#
# kythera: services for TSora IRC networks
# lib/kythera/channel.rb: Channel class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# This is just a base class. All protocol module should monkeypatch this.
class Channel
    include Loggable

    # Standard IRC status cmodes
    STATUS_MODES = { 'o' => :operator,
                     'v' => :voice }

    # Standard IRC list cmodes
    LIST_MODES   = { 'b' => :ban }

    # Standard IRC cmodes requiring a param
    PARAM_MODES  = { 'l' => :limited,
                     'k' => :keyed }

    # Standard boolean IRC cmodes
    BOOL_MODES   = { 'i' => :invite_only,
                     'm' => :moderated,
                     'n' => :no_external,
                     'p' => :private,
                     's' => :secret,
                     't' => :topic_lock }

    # A list of all channels. The key is the channel name by default
    @@channels = {}

    # Attribute reader for `@@channels`
    #
    # @return [Hash] a list of all Channels
    #
    def self.channels
        @@channels
    end

    # The channel name, including prefix
    attr_reader :name

    # If the channel is +k, this is the key
    attr_reader :key

    # If the channel is +l, this is the limit
    attr_reader :limit

    # A Hash of members keyed by nickname
    attr_reader :members

    # An Array of mode Symbols
    attr_reader :modes

    # Creates a new channel. Should be patched by the protocol module.
    def initialize(name, logger)
        @name   = name
        @modes  = []
        @logger = nil

        self.logger = logger

        # Keyed by nickname by default
        @members = {}

        @@channels[name] = self

        log.debug "new channel: #{@name}"

        $eventq.post(:channel_added, self)
    end

    public

    # String representation is just `@name`
    def to_s
        "#{@name}"
    end

    # Parses a mode string and updates channel state
    #
    # @param [String] modes the mode string
    # @param [Array] params params to the mode string, tokenized by space
    #
    def parse_modes(modes, params)
        action = nil # :add or :delete

        modes.each_char do |c|
            mode, param = nil

            if c == '+'
                action = :add
                next
            elsif c == '-'
                action = :delete
                next
            end

            # Status modes
            if STATUS_MODES.include? c
                mode  = STATUS_MODES[c]
                param = params.shift

            elsif LIST_MODES.include? c
                mode  = LIST_MODES[c]
                param = params.shift

            # Always has a param (some send the key, some send '*')
            elsif c == 'k'
                mode  = :keyed
                param = params.shift
                @key  = action == :add ? param : nil

            # Has a param when +, doesn't when -
            elsif c == 'l'
                mode   = :limited
                param  = params.shift
                @limit = action == :add ? param : 0

            # The rest, no param
            elsif BOOL_MODES.include? c
                mode = BOOL_MODES[c]
            end

            # Add boolean modes to the channel's modes
            unless STATUS_MODES.include? c or LIST_MODES.include? c
                if action == :add
                    @modes << mode
                else
                    @modes.delete(mode)
                end
            end

            unless STATUS_MODES.include? c
                log.debug "mode #{action}ed: #{self} -> #{mode} #{param}"
            end

            # XXX - list modes

            # Status modes for users get tossed to another method so that
            # how they work can be monkeypatched by protocol modules
            #
            parse_status_mode(action, mode, param) if STATUS_MODES.include? c

            # Post an event for it
            if action == :add
                $eventq.post(:mode_added_on_channel, mode, param, self)
            elsif action == :delete
                $eventq.post(:mode_deleted_on_channel, mode, param, self)
            end
        end
    end

    # Adds a User as a member
    #
    # @param [User] user the User to add
    #
    def add_user(user)
        @members[user.nickname] = user

        log.debug "user joined #{self}: #{user.nickname}"

        $eventq.post(:user_joined_channel, user, self)
    end

    # Deletes a User as a member
    #
    # @param [User] user User object to delete
    #
    def delete_user(user)
        @members.delete user.nickname

        user.status_modes.delete(self)

        log.debug "user parted #{self}: #{user.nickname} (#{@members.length})"

        $eventq.post(:user_parted_channel, user, self)

        if @members.length == 0
            @@channels.delete @name

            log.debug "removing empty channel #{self}"

            $eventq.post(:channel_deleted, self)
        end
    end

    # Deletes all modes
    def clear_modes
        @modes = []
    end

    private

    # Deals with status modes
    #
    # @param [Symbol] mode Symbol representing a mode flag
    # @param [String] target the user this mode applies to
    #
    def parse_status_mode(action, mode, target)
        unless user = User.users[target]
            log.warn "cannot parse a status mode for an unknown user"
            log.warn "#{target} -> #{mode} (#{self})"

            return
        end

        if action == :add
            user.add_status_mode(self, mode)
        elsif action == :delete
            user.delete_status_mode(self, mode)
        end
    end
end
