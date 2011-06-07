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
        @sendq << 'CAPAB :QS KLN UNKLN ENCAP'
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
            @recvq.clear
            @connection.close
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
        not_used, s   = Server.servers.first # There should only be one
        s.name        = m.parv[0]
        s.description = m.parv[2]
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

    # Handles an incoming UID
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

    # Handles an incoming
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
        if c = Channel.channels[m.parv[1]]
            if their_ts < c.timestamp
                # Remove our status modes, channel modes, and bans
                c.members.each { |u| u.clear_status_modes(c) }
                c.clear_modes
                c.timestamp = their_ts
            end
        else
            c = Channel.new(m.parv[1], m.parv[0], @logger)
        end

        # Parse channel modes
        if their_ts <= c.timestamp
            modes_and_params = m.parv[GET_MODES_PARAMS]
            modes  = modes_and_params[0]
            params = modes_and_params[REMOVE_FIRST]

            c.parse_modes(modes, params)
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

            unless u = User.users[uid]
                log.error "Got non-existant UID #{uid} in SJOIN to #{c.name}"
                next
            end

            c.add_user u

            if their_ts <= c.timestamp
                u.add_status_mode(c, :operator) if op
                u.add_status_mode(c, :voice)    if voice
            end
        end
    end
end
