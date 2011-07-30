#
# kythera: services for IRC networks
# lib/kythera/protocol/inspircd/send.rb: implements the InspIRCd protocol
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Copyright (c) 2011 Andrew Herbig <goforit7arh@gmail.com>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# Implements InspIRCd protocol-specific methods
module Protocol::InspIRCd
    private

    # Sends the initial data to the server
    def send_handshake
        $state[:bursting] = Time.now

        send_capab
        send_server
    end

    # CAPAB START
    # CAPAB CAPABILITIES :VAR=VALUE {[VAR=VALUE]}
    # CAPAB MODULES <module list>
    # CAPAB END
    def send_capab
        @sendq << 'CAPAB START'
        # PROTOCOL is the only mandatory argument
        @sendq << 'CAPAB CAPABILITIES :PROTOCOL=1201'
        # we're not a real server so we don't have any modules loaded
        @sendq << 'CAPAB END'
    end

    # SERVER <servername> <password> <hopcount> <id> :<description>
    def send_server
        str  = "SERVER #{$config.me.name} #{@config.send_password} 0 "
        str += "#{@config.sid} :#{$config.me.description}"

        @sendq << str
    end

    def send_burst
        @sendq << ":#{@config.sid} BURST #{Time.now.to_i}"
        # we don't have anything to burst, so don't send anything
        @sendq << ":#{@config.sid} ENDBURST"
    end

    # :<sid> UID <uid> <timestamp> <nick> <hostname> <displayed-hostname> <ident> <ip> <signon time> +<modes {mode params}> :<gecos>
    def send_uid(nick, user, host, real, modes = '')
        ts    = Time.now.to_i
        ip    = @config.bind_host || '255.255.255.255'
        id    = @@current_uid
        uid   = "#{@config.sid}#{id}"
        modes = "+#{modes}"

        @@current_uid.next!

        str  = ":#{@config.sid} UID #{uid} #{ts} #{nick} #{host} #{host} "
        str += "#{user} #{ip} #{ts} #{modes} :#{real}"

        @sendq << str

        User.new(nil, nick, user, host, ip, real, modes, uid, ts, @logger)
    end

    # :<sid> FJOIN <channel> <timestamp> +<modes> <params> :<statusmodes,uuid>
    def send_fjoin(channel, timestamp, uid)
        @sendq << ":#{@config.sid} FJOIN #{channel} #{timestamp} + ,#{uid}"
    end

    # :<source> PONG <source> :<destination>
    def send_pong(dest)
        @sendq << ":#{@config.sid} PONG #{@config.sid} :#{dest}"
    end

    # :source PRIVMSG target :message
    def send_privmsg(source, target, message)
        @sendq << ":#{source} PRIVMSG #{target} :#{message}"
    end

    # :source NOTICE target :message
    def send_notice(source, target, message)
        @sendq << ":#{source} NOTICE #{target} :#{message}"
    end
end
