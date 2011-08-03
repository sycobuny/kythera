#
# kythera: services for IRC networks
# lib/kythera/database/user.rb: registered users
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

module Database
    class Channel < Sequel::Model
    end

    class ChannelUserFlag < Sequel::Model
        many_to_one :user
        many_to_one :channel
        include GenericFlag
    end
end
