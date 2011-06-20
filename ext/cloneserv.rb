#
# kythera: services for IRC networks
# ext/cloneserv.rb: introduces tons of clones for testing
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

require 'securerandom'

# This service just connects a bunch of clones to the network for testing
class CloneServ < Service
    attr_reader :user

    # Disabled by default
    def self.enabled?
        false
    end

    def self.verify_configuration
        true
    end

    def initialize(uplink, logger)
        # Prepare the logger and uplink
        super

        log.info "CloneServ module loaded"

        nicks, chans = [], []

        alpha = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz'

        25_000.times do |i|
            nicks[i] = SecureRandom.hex(8)
            nicks[i][0] = alpha[SecureRandom.random_number(alpha.length)].chr
        end

        nicks.uniq!

        7_500.times do |i|
            chans[i] = SecureRandom.hex(10)
            chans[i][0] = '#'
        end

        chans.uniq!

        users = []

        25_000.times do |i|
            users[i] = @uplink.introduce_user(nicks[i], SecureRandom.hex(4),
                                         'cloneserv.dev', SecureRandom.hex)
        end

        # Join our configuration channel
        $eventq.handle(:end_of_burst) do
            users.each do |u|
                @uplink.join(u, chans[SecureRandom.random_number(7_500)])
            end
        end
    end
end
