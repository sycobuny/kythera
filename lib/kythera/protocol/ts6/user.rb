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
    # The user's IP address
    attr_reader :ip

    # The user's timestamp
    attr_reader :timestamp

    # The user's UID
    attr_reader :uid

    # Creates a new user and adds it to the list keyed by UID
    def initialize(server, nick, user, host, ip, real, umodes, uid, ts, logger)
        @server    = server
        @nickname  = nick
        @username  = user
        @hostname  = host
        @ip        = ip
        @realname  = real
        @modes     = umodes
        @uid       = uid
        @timestamp = ts
        @logger    = nil

        @status_modes = {}
        self.logger   = logger

        log.error "new user replacing user with same UID!" if @@users[uid]

        @@users[uid] = self

        log.debug "new user: #{nick}!#{user}@#{host} (#{real}) [#{uid}]"

        $eventq.post(:user_added, self)
    end
end
