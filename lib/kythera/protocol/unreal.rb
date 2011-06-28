#
# kythera: services for IRC networks
# lib/kythera/protocol/unreal.rb: implements UnrealIRCd's protocol
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Copyright (c) 2011 Andrew Herbig <goforit7arh@gmail.com>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

require 'kythera/protocol/unreal/channel'
require 'kythera/protocol/unreal/send'
require 'kythera/protocol/unreal/server'
require 'kythera/protocol/unreal/receive'
require 'kythera/protocol/unreal/user'

module Protocol::Unreal
    public

    # Sends a string straight to the uplink
    #
    # @param [String] string message to send
    #
    def raw(string)
        @sendq << string
    end

    # Introduces a pseudo-client to the network
    #
    # @param [String] nick user's nickname
    # @param [String] user user's username
    # @param [String] host user's hostname
    # @param [String] real user's realname / gecos
    #
    def introduce_user(nick, user, host, real)
        send_nick(nick, user, host, real)
    end

    # Sends a PRIVMSG to a user
    #
    # @param [User] origin the user that's sending the message
    # @param target either a User or a Channel or a String
    # @param [String] message the message to send
    #
    def privmsg(origin, target, message)
        target = target.nickname if target.kind_of?(User)
        send_privmsg(origin.nickname, target, message)
    end

    # Sends a NOTICE to a user
    #
    # @param [User] origin the user that's sending the notice
    # @param [User] user the User to send the notice to
    # @param [String] message the message to send
    #
    def notice(origin, user, message)
        send_notice(origin.nickname, user.nickname, message)
    end

    # Makes one of our clients join a channel
    #
    # @param [User] user the User we want to join
    # @param channel can be a Channel or a string
    #
    def join(user, channel)
        if channel.kind_of?(String)
            if chanobj = Channel.channels[channel]
                channel = chanobj
            else
                # This is a nonexistant channel
                channel = Channel.new(channel, Time.now.to_i, @logger)
            end
        end

        send_sjoin(channel.name, channel.timestamp, user.nickname)

        channel.add_user(user)
    end

    # Makes one of our clients send a QUIT
    #
    # @param [User] user which client to quit
    # @param [String] reason quit reason if any
    #
    def quit(user, reason = 'signed off')
        send_quit(user.nick, reason)
    end

    private

    # Finds a User and Channel or errors
    def find_user_and_channel(nick, name, command)
        unless user = User.users[nick]
            log.error "got non-existant nick in #{command}: #{nick}"
        end

        unless channel = Channel.channels[name]
            log.error "got non-existant channel in #{command}: #{name}"
        end

        [user, channel]
    end
end
