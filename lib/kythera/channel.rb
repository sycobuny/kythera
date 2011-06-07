#
# kythera: services for TSora IRC networks
# lib/kythera/channel.rb: Channel class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
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

    # Instance attributes
    attr_reader :name, :key, :limit, :members, :modes

    # Creates a new channel. Should be patched by the protocol module.
    def initialize(name, logger)
        @name   = name
        @logger = logger
        @modes  = []

        # Keyed by nickname by default
        @members = {}

        @@channels[name] = self

        log.debug "new channel: #{name}"
    end

    public

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

            log.debug "#{@name} #{action == :add ? '+' : '-'}#{mode} #{param}"

            # Add boolean modes to the channel's modes
            unless STATUS_MODES.include? c or LIST_MODES.include? c
                if action == :add
                    @modes << mode
                else
                    @modes.delete mode
                end
            end

            # XXX - list modes

            # Status modes for users get tossed to another method so that
            # how they work can be monkeypatched by protocol modules
            #
            parse_status_mode(mode, param) if STATUS_MODES.include? c
        end
    end

    # Adds a User as a member
    #
    # @param [User] user the User to add
    #
    def add_user(user)
        @members[user.nickname] = user

        log.debug "new user in #{@name}: #{user.nickname}"
    end

    # Deletes a User as a member
    #
    # @param user can be string (key) or User (value)
    #
    def delete_user(user)
        if user.kind_of? User then user = user.nickname end
        @members.delete user

        log.debug "user left #{@name}: #{user} (#{@members.length})"
    end

    # Deletes all modes
    def clear_modes
        @modes = []
    end

    private

    # Deals with status modes
    #
    # @param [Symbol] mode Symbol representing a mode flag
    # @param [String] user the user this mode applies to
    #
    def parse_status_mode(mode, user)
        unless u = User.users[user]
            log.warning "cannot parse a status mode for an unknown user"
            log.warning "#{user} -> #{mode} (#{@name})"

            return
        end

        u.add_status_mode(self, mode)
    end
end
