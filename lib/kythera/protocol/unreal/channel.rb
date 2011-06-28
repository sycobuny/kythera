#
# kythera: services for IRC networks
# lib/kythera/protocol/unreal/channel.rb: UnrealIRCd-specific Channel class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Copyright (c) 2011 Andrew Herbig <goforit7arh@gmail.com>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# This reopens the base Channel class in `kythera/channel.rb`
class Channel
    # Unreal has owner, admin, and halfop as well as operator and voice.
    @@status_modes = { 'q' => :owner,
                       'a' => :admin,
                       'o' => :operator,
                       'h' => :halfop,
                       'v' => :voice }

    # Unreal has except and invex as well as ban
    @@list_modes = { 'b' => :ban,
                     'e' => :except,
                     'I' => :invex }

    # The channel's timestamp
    attr_reader :timestamp

    # Creates a new channel and adds it to the list keyed by name
    def initialize(name, timestamp, logger)
        @name      = name
        @timestamp = timestamp.to_i
        @modes     = []
        @logger    = nil

        # Keyed by nick
        @members = {}

        self.logger = logger

        log.error "new channel #{@name} already exists!" if @@channels[name]

        @@channels[name] = self

        log.debug "new channel: #{@name} (#{timestamp})"

        $eventq.post(:channel_added, self)
    end

    public

    # Adds a User as a member
    #
    # @param [User] user the User to add
    #
    def add_user(user)
        @members[user.nickname] = user

        log.debug "user joined #{@name}: #{user.nickname}"

        $eventq.post(:user_joined_channel, user, self)
    end

    # Deletes a User as a member
    #
    # @param [User] user User object to delete
    #
    def delete_user(user)
        @members.delete user.uid

        user.status_modes.delete(self)

        log.debug "user parted #{@name}: #{user.nickname} (#{@members.length})"

        $eventq.post(:user_parted_channel, user, self)

        if @members.length == 0
            @@channels.delete @name

            log.debug "removing empty channel #{@name}"

            $eventq.post(:channel_deleted, self)
        end
    end

    # Writer for `@timestamp`
    #
    # @param timestamp new timestamp
    #
    def timestamp=(timestamp)
        if timestamp.to_i > @timestamp
            log.warn "changing timestamp to a later value?"
            log.warn "#{@name} -> #{timestamp} > #{@timestamp}"
        end

        log.debug "#{@name}: timestamp changed: #{@timestamp} -> #{timestamp}"

        @timestamp = timestamp.to_i
    end
end
