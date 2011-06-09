#
# kythera: services for TSora IRC networks
# lib/kythera/protocol/ts6.rb: implements the TS6 protocol
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'kythera'

require 'kythera/protocol/ts6/channel'
require 'kythera/protocol/ts6/server'
require 'kythera/protocol/ts6/user'

# Implements TS6 protocol-specific methods
module Protocol::TS6
    private

    ###########
    # M I S C #
    ###########

    # Finds a User and Channel or errors
    def find_uid_and_channel(uid, name, command)
        unless user = User.users[uid]
            log.error "got non-existant UID in #{command}: #{uid}"
        end

        unless channel = Channel.channels[name]
            log.error "got non-existant channel in #{command}: #{name}"
        end

        [user, channel]
    end

    #################
    # S E N D E R S #
    #################

    # Sends the initial data to the server
    def send_handshake
        send_pass
        send_capab
        send_server
        send_svinfo
    end

    # PASS <PASSWORD> TS <TS_CURRENT> :<SID>
    def send_pass
        @sendq << "PASS #{@config.send_password} TS 6 :#{@config.sid}"
    end

    # CAPAB :<CAPABS>
    def send_capab
        @sendq << 'CAPAB :QS EX IE KLN UNKLN ENCAP'
    end

    # SERVER <NAME> <HOPS> :<DESC>
    def send_server
        @sendq << "SERVER #{$config.me.name} 1 :#{$config.me.description}"
    end

    # SVINFO <MAX_TS_VERSION> <MIN_TS_VERSION> 0 :<TS>
    def send_svinfo
        @sendq << "SVINFO 6 6 0 :#{Time.now.to_i}"
    end

    # :<SID> PONG <NAME> :<PARAM>
    def send_pong(param)
        @sendq << ":#{@config.sid} PONG #{$config.me.name} :#{param}"
    end

    #####################
    # R E C E I V E R S #
    #####################

    # Handles an incoming PASS
    #
    # parv[0] -> password
    # parv[1] -> 'TS'
    # parv[2] -> ts version
    # parv[3] -> sid of remote server
    #
    def irc_pass(m)
        if m.parv[0] != @config.receive_password.to_s
            log.error "incorrect password received from `#{@config.name}`"
            self.dead = true
        else
            Server.new(m.parv[3], @logger)
        end
    end

    # Handles an incoming SERVER
    #
    # parv[0] -> server name
    # parv[1] -> hops
    # parv[2] -> server description
    #
    def irc_server(m)
        if m.origin
            # If we have an origin, then this is a new server introduction.
            # This sucks, because this is not a TS6 server introduction, and
            # we specifically state we only speak TS6, but it doesn't seem like
            # they care, so now we have to deal with this anyway.
            #
            server = Server.new('ts5_' + rand(99999).to_s, @logger)
        else
            # No origin means we're handshaking, so this must be our uplink
            not_used, server = Server.servers.first

            unless m.parv[0] == @config.name
                log.error "name mismatch from uplink"
                log.error "#{m.parv[0]} != #{@config.name}"

                self.dead = true

                return
            end
        end

        server.name        = m.parv[0]
        server.description = m.parv[2]

        log.debug "new server: #{m.parv[0]}"

        $eventq.post(:server_added, server)
    end

    # Handles an incoming SVINFO
    #
    # parv[0] -> max ts version
    # parv[1] -> min ts version
    # parv[2] -> '0'
    # parv[3] -> current ts
    #
    def irc_svinfo(m)
        if m.parv[0].to_i < 6
            log.error "`#{@config.name}` doesn't support TS6"
            @recvq.clear
            @connection.close
        elsif (m.parv[3].to_i - Time.now.to_i) >= 60
            log.warning "`#{@config.name}` has excessive TS delta"
        end
    end

    # Handles an incoming PING
    #
    # parv[0] -> sid of remote server
    #
    def irc_ping(m)
        send_pong(m.parv[0])
    end

    # Handles an incoming SID (server introduction)
    #
    # parv[0] -> server name
    # parv[1] -> hops
    # parv[2] -> sid
    # parv[3] -> description
    #
    def irc_sid(m)
        server             = Server.new(m.parv[2], @logger)
        server.name        = m.parv[0]
        server.description = m.parv[3]

        $eventq.post(:server_added, server)
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
    def irc_uid(m)
        p = m.parv
        User.new(p[0], p[4], p[5], p[6], p[8], p[7], p[2], @logger)
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
    def irc_sjoin(m)
        their_ts = m.parv[0].to_i

        # Do we already have this channel?
        if channel = Channel.channels[m.parv[1]]
            if their_ts < c.timestamp
                # Remove our status modes, channel modes, and bans
                channel.members.each { |u| u.clear_status_modes(channel) }
                channel.clear_modes
                channel.timestamp = their_ts
            end
        else
            channel = Channel.new(m.parv[1], m.parv[0], @logger)
        end

        # Parse channel modes
        if their_ts <= channel.timestamp
            modes_and_params = m.parv[GET_MODES_PARAMS]
            modes  = modes_and_params[0]
            params = modes_and_params[REMOVE_FIRST]

            channel.parse_modes(modes, params)
        end

        # Parse the members list
        members = m.parv[-1].split(' ')

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
                log.error "got non-existant UID in SJOIN: #{uid}"
                next
            end

            channel.add_user user

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
    def irc_join(m)
        user, channel = find_uid_and_channel(m.origin, m.parv[1], 'JOIN')
        return unless user and channel

       if m.parv[0].to_i < channel.timestamp
           # Remove our status modes, channel modes, and bans
           channel.members.each { |u| u.clear_status_modes(channel) }
           channel.clear_modes
           channel.timestamp = m.parv[0].to_i
       end

       # Add them to the channel
       channel.add_user user
    end

    # Handles an incoming PART
    #
    # parv[0] -> channel name
    #
    def irc_part(m)
        user, channel = find_uid_and_channel(m.origin, m.parv[0], 'PART')
        p m.parv

        return unless user and channel

        channel.delete_user user
    end

    # Handles an incoming TMODE
    #
    # parv[0] -> timestamp
    # parv[1] -> channel name
    # parv[2] -> mode string
    #
    def irc_tmode(m)
        if m.origin.length == 3
            user, channel   = find_uid_and_channel(m.origin, m.parv[1], 'TMODE')
            return unless user and channel
        else
            channel = Channel.channels[m.parv[1]]
            return unless channel
        end

        params = m.parv[GET_MODES_PARAMS]
        modes  = params.delete_at(0)

        channel.parse_modes(modes, params)
    end
end
