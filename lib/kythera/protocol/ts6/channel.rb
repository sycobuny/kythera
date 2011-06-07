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
        @logger    = logger
        @modes     = []

        # Keyed by UID
        @members = {}

        @@channels[name] = self

        log.debug "new channel: #{name} (#{timestamp})"
    end

    public

    # Adds a User as a member
    #
    # @param [User] user the User to add
    #
    def add_user(user)
        @members[user.uid] = user

        log.debug "new user in #{@name}: #{user.nickname} [#{user.uid}]"
    end

    # Deletes a User as a member
    #
    # @param user can be string (UID) or User object
    #
    def delete_user(user)
        if user.kind_of? User then user = user.uid end
        @members.delete user

        log.debug "user left #{@name}: #{user} (#{@members.length})"
    end

    # Writer for `@timestamp`
    #
    # @param timestamp new timestamp
    #
    def timestamp=(timestamp)
        if timestamp.to_i > @timestamp
            log.warning "changing timestamp to a later value?"
            log.warning "#{@name} -> #{timestamp} > #{@timestamp}"
        end

        log.debug "#{@name}: timestamp changed: #{@timestamp} -> #{timestamp}"

        @timestamp = timestamp.to_i
    end
end
