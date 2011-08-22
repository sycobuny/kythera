#
# kythera: services for IRC networks
# lib/kythera/database/user.rb: registered users
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Copyright (c) 2011 Stephen Belcher <sycobuny@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

module Database
    class Channel < Sequel::Model
    end

    # Just a join table
    class ChannelUserFlag < Sequel::Model
        many_to_one :user
        many_to_one :channel
        include GenericFlag
    end
end
