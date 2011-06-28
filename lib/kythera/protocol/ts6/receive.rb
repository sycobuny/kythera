#
# kythera: services for IRC networks
# lib/kythera/protocol/ts6/receive.rb: implements the TS6 protocol
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# Implements TS6 protocol-specific methods
module Protocol::TS6
    private

    # Handles an incoming PASS
    #
    # parv[0] -> password
    # parv[1] -> 'TS'
    # parv[2] -> ts version
    # parv[3] -> sid of remote server
    #
    def irc_pass(origin, parv)
        if parv[0] != @config.receive_password.to_s
            log.error "incorrect password received from `#{@config.name}`"
            self.dead = true
        else
            Server.new(parv[3], @logger)
        end
    end

    # Handles an incoming SERVER
    #
    # parv[0] -> server name
    # parv[1] -> hops
    # parv[2] -> server description
    #
    def irc_server(origin, parv)
        if origin
            # If we have an origin, then this is a new server introduction.
            # However this is a TS5 introduction, and we only support TS6-only
            # networks, so spit out a warning and ignore it.
            #
            log.warn 'got non-TS6 server introduction on TS6-only network:'
            log.warn "#{parv[0]} (#{parv[2]})"

            return
        end

        # No origin means we're handshaking, so this must be our uplink
        server = Server.servers.values.first

        # Make sure their name matches what we expect
        unless parv[0] == @config.name
            log.error "name mismatch from uplink"
            log.error "#{parv[0]} != #{@config.name}"

            self.dead = true

            return
        end

        server.name        = parv[0]
        server.description = parv[2]

        log.debug "new server: #{parv[0]}"

        $eventq.post(:server_added, server)
    end

    # Handles an incoming SVINFO
    #
    # parv[0] -> max ts version
    # parv[1] -> min ts version
    # parv[2] -> '0'
    # parv[3] -> current ts
    #
    def irc_svinfo(origin, parv)
        ts_delta = parv[3].to_i - Time.now.to_i

        if parv[0].to_i < 6
            log.error "#{@config.name} doesn't support TS6"
            self.dead = true
        elsif ts_delta >= 60
            log.warn "#{@config.name} has excessive TS delta"
            log.warn "#{parv[3]} - #{Time.now.to_i} = #{ts_delta}"
        elsif ts_delta >= 300
            log.error "#{@config.name} TS delta exceeds five minutes"
            log.error "#{parv[3]} - #{Time.now.to_i} = #{ts_delta}"
            self.dead = true
        end
    end

    # Handles an incoming PING
    #
    # parv[0] -> sid of remote server
    #
    def irc_ping(origin, parv)
        send_pong(parv[0])

        if $state[:bursting]
            delta = Time.now - $state[:bursting]
            $state[:bursting] = false

            $eventq.post(:end_of_burst, delta)
        end
    end

    # Handles an incoming SID (server introduction)
    #
    # parv[0] -> server name
    # parv[1] -> hops
    # parv[2] -> sid
    # parv[3] -> description
    #
    def irc_sid(origin, parv)
        server             = Server.new(parv[2], @logger)
        server.name        = parv[0]
        server.description = parv[3]

        $eventq.post(:server_added, server)
    end

    # Handles an incoming SQUIT (server disconnection)
    #
    # parv[0] -> SID leaving
    # parv[1] -> server's uplink's name
    #
    def irc_squit(origin, parv)
        unless server = Server.servers.delete(parv[0])
            log.error "received SQUIT for unknown SID: #{parv[0]}"
            return
        end

        # Remove all their users to comply with CAPAB QS
        server.users.each { |u| User.users.delete u.uid }

        log.debug "server leaving: #{parv[0]}"
    end

    # Handles an incoming UID (user introduction)
    #
    # parv[0] -> nickname
    # parv[1] -> hops
    # parv[2] -> timestamp
    # parv[3] -> '+' umodes
    # parv[4] -> username
    # parv[5] -> hostname
    # parv[6] -> ip
    # parv[7] -> uid
    # parv[8] -> realname
    #
    def irc_uid(origin, parv)
        p = parv

        unless s = Server.servers[origin]
            log.error "got UID from unknown SID: #{origin}"
            return
        end

        m = parv[3][1 .. -1]

        u = User.new(s, p[0], p[4], p[5], p[6], p[8], m, p[7], p[2], @logger)

        s.add_user(u)
    end

    # Handles an incoming NICK
    #
    # parv[0] -> new nickname
    # parv[1] -> ts
    #
    def irc_nick(origin, parv)
        return unless parv.length == 2 # We don't want TS5 introductions

        unless user = User.users[origin]
            log.error "got nick change for non-existant UID: #{origin}"
            return
        end

        log.debug "nick change: #{user.nickname} -> #{parv[0]} [#{origin}]"

        user.nickname = parv[0]
    end

    # Handles an incoming QUIT
    #
    # parv[0] -> quit message
    #
    def irc_quit(origin, parv)
        unless user = User.users.delete(origin)
            log.error "received QUIT for unknown UID: #{origin}"
            return
        end

        user.server.delete_user(user)

        log.debug "user quit: #{user.nickname} [#{user.uid}]"
    end

    # Removes the first character of the string
    REMOVE_FIRST = 1 .. -1

    # Special constant for grabbing mode params
    GET_MODES_PARAMS = 2 ... -1

    # Handles an incoming SJOIN (channel burst)
    #
    # parv[0] -> timestamp
    # parv[1] -> channel name
    # parv[2] -> '+' cmodes
    # parv... -> cmode params (if any)
    # parv[-1] -> members as UIDs
    #
    def irc_sjoin(origin, parv)
        their_ts = parv[0].to_i

        # Do we already have this channel?
        if channel = Channel.channels[parv[1]]
            if their_ts < channel.timestamp
                # Remove our status modes, channel modes, and bans
                channel.members.each { |u| u.clear_status_modes(channel) }
                channel.clear_modes
                channel.timestamp = their_ts
            end
        else
            channel = Channel.new(parv[1], parv[0], @logger)
        end

        # Parse channel modes
        if their_ts <= channel.timestamp
            modes_and_params = parv[GET_MODES_PARAMS]
            modes  = modes_and_params[0]
            params = modes_and_params[REMOVE_FIRST]

            channel.parse_modes(modes, params) unless modes == '0'
        end

        # Parse the members list
        members = parv[-1].split(' ')

        # This particular process was benchmarked, and this is the fastest
        # See benchmark/theory/multiprefix_parsing.rb
        #
        members.each do |uid|
            op = voice = false

            if uid[0].chr == '@'
                op  = true
                uid = uid[REMOVE_FIRST]
            end

            if uid[0].chr == '+'
                voice = true
                uid   = uid[REMOVE_FIRST]
            end

            unless user = User.users[uid]
                # Maybe it's a nickname?
                user = User.users.values.find { |u| u.nickname == uid }
                unless user
                    log.error "got non-existant UID in SJOIN: #{uid}"
                    next
                end
            end

            channel.add_user(user)

            if their_ts <= channel.timestamp
                if op
                    user.add_status_mode(channel, :operator)

                    $eventq.post(:mode_added_on_channel,
                                :operator, user, channel)
                end

                if voice
                    user.add_status_mode(channel, :voice)

                    $eventq.post(:mode_added_on_channel, :voice, user, channel)
                end
            end
        end
    end

    # Handles an incoming JOIN (non-burst channel join)
    #
    # parv[0] -> timestamp
    # parv[1] -> channel name
    # parv[2] -> '+'
    #
    def irc_join(origin, parv)
        user, channel = find_user_and_channel(origin, parv[1], :JOIN)
        return unless user and channel

       if parv[0].to_i < channel.timestamp
           # Remove our status modes, channel modes, and bans
           channel.members.each { |u| u.clear_status_modes(channel) }
           channel.clear_modes
           channel.timestamp = parv[0].to_i
       end

       # Add them to the channel
       channel.add_user(user)
    end

    # Handles an incoming PART
    #
    # parv[0] -> channel name
    #
    def irc_part(origin, parv)
        user, channel = find_user_and_channel(origin, parv[0], :PART)

        return unless user and channel

        channel.delete_user(user)
    end

    # Handles an incoming KICK
    #
    # parv[0] -> channel name
    # parv[1] -> UID of kicked user
    # parv[2] -> kick reason
    #
    def irc_kick(origin, parv)
        user, channel = find_user_and_channel(parv[1], parv[0], :KICK)

        return unless user and channel

        channel.delete_user(user)
    end

    # Handles an incoming TMODE
    #
    # parv[0] -> timestamp
    # parv[1] -> channel name
    # parv[2] -> mode string
    #
    def irc_tmode(origin, parv)
        if origin.length == 3
            user, channel = find_user_and_channel(origin, parv[1], :TMODE)
            return unless user and channel
        else
            channel = Channel.channels[parv[1]]
            return unless channel
        end

        params = parv[GET_MODES_PARAMS]
        modes  = params.delete_at(0)

        channel.parse_modes(modes, params)
    end

    # Handles an incoming PRIVMSG
    #
    # parv[0] -> target
    # parv[1] -> message
    #
    def irc_privmsg(origin, parv)
        return if parv[0][0].chr == '#'

        # Look up the sending user
        user = User.users[origin]

        # Which one of our clients was it sent to?
        srv = Service.services.find do |s|
            s.user.uid == parv[0] if s.respond_to?(:user)
        end

        # Send it to the service (if we found one)
        srv.send(:irc_privmsg, user, parv[1].split(' ')) if srv
    end
end
