#
# kythera: services for IRC networks
# lib/kythera/protocol/unreal/receive.rb: implements UnrealIRCd's protocol
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Copyright (c) 2011 Andrew Herbig <goforit7arh@gmail.com>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# Implements Unreal protocol-specific methods
module Protocol::Unreal
    private

    # Handles an incoming PASS
    #
    # parv[0] -> password
    def irc_pass(origin, parv)
        if parv[0] != @config.receive_password.to_s
            log.error "incorrect password received from `#{@config.name}`"
            self.dead = true
        end
    end

    # Handles an incoming SERVER (server introduction)
    #
    # without origin
    #   parv[0] -> server name
    #   parv[1] -> hops
    #   parv[2] -> server description
    # with origin
    #   parv[0] -> server name
    #   parv[1] -> hops
    #   parv[2] -> description
    def irc_server(origin, parv)
        # No origin means that we're handshaking, so this must be our uplink.
        unless origin
            server = Server.new(parv[0], @logger)

            # Make sure their name matches what we expect
            unless parv[0] == @config.name
                log.error "name mismatch from uplink"
                log.error "#{parv[0]} != #{@config.name}"

                self.dead = true

                return
            end

            server.description = parv[2]

            log.debug "new server: #{parv[0]}"

            $eventq.post(:server_added, server)
        else
            server             = Server.new(parv[0], @logger)
            server.description = parv[2]
        end
    end

    # Handles an incoming PING
    #
    # parv[0] -> source server
    # parv[1] -> optional destination server (which is us)
    def irc_ping(origin, parv)
        send_pong(parv[0])
    end

    # Handles an incoming NICK
    #
    # if we have an origin, a nick is being changed:
    #   parv[0] -> new nick
    #   parv[1] -> timestamp
    # if we don't have an origin, then a new user is being introduced.
    #   parv[0] -> nick
    #   parv[1] -> hops
    #   parv[2] -> timestamp
    #   parv[3] -> username
    #   parv[4] -> hostname
    #   parv[5] -> server
    #   parv[6] -> servicestamp
    #   parv[7] -> realname
    def irc_nick(origin, parv)
        if origin
            unless user = User.users[origin]
                log.error "got nick change for non-existant nick: #{origin}"
                return
            end

            log.debug "nick change: #{user.nickname} -> #{parv[0]}"

            user.nickname = parv[0]
        else
            p = parv

            unless s = Server.servers[p[5]]
                log.error "received NICK from unknown server: #{parv[5]}"
                return
            end

            u = User.new(s, p[0], p[3], p[4], p[7], p[2], @logger)

            s.add_user(u)
        end
    end

    # Handles an incoming QUIT
    #
    # parv[0] -> quit message
    #
    def irc_quit(origin, parv)
        unless user = User.users.delete(origin)
            log.error "received QUIT for unknown nick: #{origin}"
            return
        end

        user.server.delete_user(user)

        log.debug "user quit: #{user.nickname}"
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
    # parv[-1] -> :members &ban "exempt 'invex
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

            channel.parse_modes(modes, params) unless modes == nil
        end

        # Parse the members list
        members = parv[-1].split(' ')

        # This particular process was benchmarked, and this is the fastest
        # See benchmark/theory/multiprefix_parsing.rb
        #
        members.each do |nick|
            if nick[0].chr == '&'
                next
            end

            if nick[0].chr == '"'
                next
            end

            if nick[0].chr == "'"
                next
            end

            owner = admin = op = halfop = voice = false

            if nick[0].chr == '*'
                owner = true
                nick  = nick[REMOVE_FIRST]
            end

            if nick[0].chr == '~'
                admin = true
                nick  = nick[REMOVE_FIRST]
            end

            if nick[0].chr == '@'
                op   = true
                nick = nick[REMOVE_FIRST]
            end

            if nick[0].chr == '%'
                halfop = true
                nick   = nick[REMOVE_FIRST]
            end

            if nick[0].chr == '+'
                voice = true
                nick  = nick[REMOVE_FIRST]
            end

            unless user = User.users[nick]
                log.error "got non-existant nick in SJOIN: #{nick}"
                next
            end

            channel.add_user(user)

            if their_ts <= channel.timestamp
                if owner
                    user.add_status_mode(channel, :owner)

                    $eventq.post(:mode_added_on_channel, :owner, user, channel)
                end

                if admin
                    user.add_status_mode(channel, :admin)

                    $eventq.post(:mode_added_on_channel, :admin, user, channel)
                end

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
    # parv[0] -> channel name
    #
    def irc_join(origin, parv)
        user, channel = find_user_and_channel(origin, parv[0], :JOIN)
        return unless user and channel

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
    # parv[1] -> nick of kicked user
    # parv[2] -> kick reason
    #
    def irc_kick(origin, parv)
        user, channel = find_user_and_channel(parv[1], parv[0], :KICK)

        return unless user and channel

        channel.delete_user(user)
    end

    # Handles an incoming MODE
    #
    # parv[0]  -> target
    # parv[1]  -> mode change
    # parv...  -> mode params
    # parv[-1] -> timestamp if origin is a server
    #
    def irc_mode(origin, parv)
        user, channel = find_user_and_channel(origin, parv[0], :MODE)
        unless user and channel
            channel = Channel.channels[parv[0]]
            return unless channel
        end

        params = parv[GET_MODES_PARAMS]
        modes  = params.delete_at(0)

        channel.parse_modes(modes, params)
    end

    # Handles an incoming UMODE2
    #
    # parv[0] -> mode change
    #
    def irc_umode2(origin, parv)
        user = User.users[origin]

        user.change_modes(parv[0])
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
            s.user.nickname == parv[0] if s.respond_to?(:user)
        end

        # Send it to the service (if we found one)
        srv.send(:irc_privmsg, user, parv[1].split(' ')) if srv
    end

    # Handles an incoming SETHOST
    #
    # parv[0] -> new vhost
    #
    def irc_sethost(origin, parv)
        user = User.users[origin]

        user.set_host(parv[0])
    end

    # Handles an incoming CHGHOST
    #
    # parv[0] -> target
    # parv[1] -> new vhost
    #
    def irc_chghost(origin, parv)
        user = User.users[parv[0]]

        user.set_host(parv[1])
    end

    # Handles an incoming EOS (end of synch)
    #
    # no params
    #
    def irc_eos(origin, parv)
        delta = 0 # XXX - Time.now - $state[:bursting]
        $state[:bursting] = false

        $eventq.post(:end_of_burst, delta)
    end
end
