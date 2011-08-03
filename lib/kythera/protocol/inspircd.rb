#
# kythera: services for IRC networks
# lib/kythera/protocol/inspircd.rb: implements the InspIRCd protocol
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Copyright (c) 2011 Andrew Herbig <goforit7arh@gmail.com>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

require 'kythera/protocol/inspircd/channel'
require 'kythera/protocol/inspircd/send'
require 'kythera/protocol/inspircd/server'
require 'kythera/protocol/inspircd/receive'
require 'kythera/protocol/inspircd/user'

# Implements InspIRCd protocol-specific methods
module Protocol::InspIRCd
    # Removes the first character of the string
    REMOVE_FIRST = 1 .. -1

    # Special constant for grabbing mode params
    GET_MODES_PARAMS = 2 ... -1

    # The current UID for Services
    @@current_uid = 'AAAAAA'

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
    def introduce_user(nick, user, host, real, modes)
        send_uid(nick, user, host, real, modes)
    end

    # Sends a PRIVMSG to a user
    #
    # @param [User] origin the user that's sending the message
    # @param target either a User or a Channel or a String
    # @param [String] message the message to send
    #
    def privmsg(origin, target, message)
        target = target.uid if target.kind_of?(User)
        send_privmsg(origin.uid, target, message)
    end

    # Sends a NOTICE to a user
    #
    # @param [User] origin the user that's sending the notice
    # @param [User] user the User to send the notice to
    # @param [String] message the message to send
    #
    def notice(origin, user, message)
        send_notice(origin.uid, user.uid, message)
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

        send_fjoin(channel.name, channel.timestamp, user.uid)

        channel.add_user(user)

        user.add_status_mode(channel, :operator)

        $eventq.post(:mode_added_on_channel,
                    :operator, user, channel)
    end

    # Makes one of our clients send a QUIT
    #
    # @param [User] user which client to quit
    # @param [String] reason quit reason if any
    #
    def quit(user, reason = 'signed off')
        send_quit(user.uid, reason)
    end

    private

    # Finds a User and Channel or errors
    def find_user_and_channel(uid, name, command)
        unless user = User.users[uid]
            log.error "got non-existant UID in #{command}: #{uid}"
        end

        unless channel = Channel.channels[name]
            log.error "got non-existant channel in #{command}: #{name}"
        end

        [user, channel]
    end
end
