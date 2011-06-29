#
# kythera: services for IRC networks
# lib/kythera/protocol/unreal/send.rb: implements UnrealIRCd's protocol
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Copyright (c) 2011 Andrew Herbig <goforit7arh@gmail.com>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# Implements Unreal protocol-specific methods
module Protocol::Unreal
    private

    # Sends the initial data to the server
    def send_handshake
        send_pass
        send_protoctl
        send_server
        send_netinfo
        send_eos
    end

    # PASS :link password
    def send_pass
        @sendq << "PASS :#{@config.send_password}"
    end

    # PROTOCTL protocol options
    def send_protoctl
        @sendq << "PROTOCTL NOQUIT VHP SJOIN SJOIN2 SJ3"
    end

    # SERVER server.name 1 :server description
    def send_server
        @sendq << "SERVER #{$config.me.name} 1 :#{$config.me.description}"
    end

    # EOS
    def send_eos
        @sendq << "EOS"
    end

    # NETINFO maxglobal currenttime protocolversion cloakhash 0 0 0 :networkname
    def send_netinfo
        @sendq << "NETINFO 0 #{Time.now.to_i} * 0 0 0 :#{@config.network}"
    end

    # PONG source :destination
    def send_pong(param)
        @sendq << "PONG #{$config.me.name} :#{param}"
    end

    # NICK nick hopcount timestamp username
    #      hostname server servicestamp :realname
    def send_nick(nick, user, host, real)
        ts = Time.now.to_i

        str  = "NICK #{nick} 1 #{ts} #{user} #{host} #{$config.me.name} 0 :"
        str += real

        @sendq << str

        User.new(nil, nick, user, host, real, ts, @logger)
    end

    # :source PRIVMSG target :message
    def send_privmsg(source, target, message)
        @sendq << ":#{source} PRIVMSG #{target} :#{message}"
    end

    # :source NOTICE target :message
    def send_notice(source, target, message)
        @sendq << ":#{source} NOTICE #{target} :#{message}"
    end

    # :server.name SJOIN timestamp channel +modes[ modeparams] :memberlist
    def send_sjoin(channel, timestamp, nick)
        @sendq << "SJOIN #{timestamp} #{channel} + :@#{nick}"
    end

    # :user QUIT :reason
    def send_quit(nick, reason)
        @sendq << ":#{nick} QUIT :#{reason}"
    end

    # :user MODE target modechange
    def send_mode(nick, target, change)
        @sendq << ":#{nick} MODE #{target} #{change}"
    end
end
