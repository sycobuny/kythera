#
# kythera: services for IRC networks
# lib/kythera/protocol/ts6/user.rb: TS6-specific User class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# This reopens the base User class in `kythera/user.rb`
class User
    # Ratbox user modes
    @@user_modes = { 'a' => :administrator,
                     'i' => :invisible,
                     'o' => :operator,
                     'w' => :wallop,
                     'D' => :deaf }

    # The user's IP address
    attr_reader :ip

    # The user's timestamp
    attr_reader :timestamp

    # The user's UID
    attr_reader :uid

    # Creates a new user and adds it to the list keyed by UID
    def initialize(server, nick, user, host, ip, real, umodes, uid, ts, logger)
        @server    = server.to_s
        @nickname  = nick.to_s
        @username  = user.to_s
        @hostname  = host.to_s
        @ip        = ip.to_s
        @realname  = real.to_s
        @uid       = uid.to_s
        @timestamp = ts
        @modes     = []
        @logger    = nil

        @status_modes = {}
        self.logger   = logger

        log.error "new user replacing user with same UID!" if @@users[uid]

        # Do our user modes
        parse_modes(umodes)

        @@users[uid] = self

        log.debug "new user: #{nick}!#{user}@#{host} (#{real}) [#{uid}]"

        $eventq.post(:user_added, self)
    end
end
