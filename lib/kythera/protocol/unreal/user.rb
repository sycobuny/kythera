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

    # Creates a new user and adds it to the list keyed by nick
    def initialize(server, nick, user, host, real, ts, logger)
        @server    = server.to_s
        @nickname  = nick.to_s
        @username  = user.to_s
        @hostname  = host.to_s
        @realname  = real.to_s
        @modes     = nil
        @timestamp = ts.to_i
        @logger    = nil

        @status_modes = {}
        self.logger   = logger

        log.error "new user replacing user with same nick!" if @@users[nick]

        @@users[nick] = self

        log.debug "new user: #{nick}!#{user}@#{host} (#{real})"

        $eventq.post(:user_added, self)
    end

    def hostname=(host)
        log.debug "changing #{@nickname}'s host from #{@hostname} to #{host}"
        @hostname = host
    end
end
