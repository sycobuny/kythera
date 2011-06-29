#
# kythera: services for IRC networks
# lib/kythera/protocol/unreal/user.rb: UnrealIRCd-specific User class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Copyright (c) 2011 Andrew Herbig <goforit7arh@gmail.com>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# This reopens the base User class in `kythera/user.rb`
class User
    # The user's timestamp
    attr_reader :timestamp

    # The user's modes
    attr_accessor :modes

    # Unreal's user modes
    @@user_modes = { 'A' => :server_admin,
                     'a' => :services_admin,
                     'B' => :bot,
                     'C' => :co_admin,
                     'd' => :deaf,
                     'G' => :censored,
                     'g' => :oper_talk,
                     'H' => :hide_ircop,
                     'h' => :helper,
                     'i' => :invisible,
                     'N' => :netadmin,
                     'O' => :local_oper,
                     'o' => :global_oper,
                     'p' => :hide_whois_channels,
                     'q' => :unkickable,
                     'R' => :registered_privmsg,
                     'r' => :registered,
                     'S' => :service,
                     's' => :receives_snotices,
                     'T' => :no_ctcp,
                     't' => :vhost,
                     'V' => :webtv,
                     'v' => :dcc_infection_notices,
                     'W' => :see_whois,
                     'w' => :wallop,
                     'x' => :hidden_host,
                     'z' => :ssl }

    # Creates a new user and adds it to the list keyed by nick
    def initialize(server, nick, user, host, real, ts, logger)
        @server    = server
        @nickname  = nick
        @username  = user
        @hostname  = host
        @realname  = real
        @timestamp = ts
        @modes     = []
        @logger    = nil

        @status_modes = {}
        self.logger   = logger

        log.error "new user replacing user with same nick!" if @@users[nick]

        @@users[nick] = self

        log.debug "new user: #{nick}!#{user}@#{host} (#{real})"

        $eventq.post(:user_added, self)
    end

    # Is this user an IRC operator?
    #
    # @return [Boolean] true or false
    #
    def operator?
        @modes.include?(:global_oper)
    end

    def hostname=(host)
        log.debug "changing #{@nickname}'s host from #{@hostname} to #{host}"
        @hostname = host
    end
end
