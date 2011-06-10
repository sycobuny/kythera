#
# kythera: services for TSora IRC networks
# lib/kythera/protocol/ts6/channel.rb: TS6-specific Channel class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'kythera'

# This reopens the base Channel class in `kythera/channel.rb`
class Channel
    # TS6 has except and invex as well as ban
    LIST_MODES   = { 'b' => :ban,
                     'e' => :except,
                     'I' => :invex }

    # Instance attributes
    attr_reader :timestamp

    # Creates a new channel and adds it to the list keyed by name
    def initialize(name, timestamp, logger)
        @name      = name
        @timestamp = timestamp.to_i
        @modes     = []
        @logger    = nil

        # Keyed by UID
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
        @members[user.uid] = user

        log.debug "user joined #{@name}: #{user.nickname}"

        $eventq.post(:user_joined_channel, user, self)
    end

    # Deletes a User as a member
    #
    # @param [User] user User object to delete
    #
    def delete_user(user)
        @members.delete user.uid

        user.cmodes.delete(self)

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
