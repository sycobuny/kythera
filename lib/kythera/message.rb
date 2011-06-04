#
# kythera: services for TSora IRC networks
# lib/kythera/message.rb: Message class implementation
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'kythera'

# Represents the old `(char *origin, int parc, char *parv[])`
class Message
    # A Regex to break up the origin
    ORIGIN_RE = /^(.+)\!(.+)\@(.+)$/

    attr_reader :origin, :origin_nick, :origin_user, :origin_host
    attr_reader :parv, :raw

    # Creates a new Message
    def initialize(origin, parv, raw)
        @origin, @parv, @raw = origin, parv, raw

        # Is the origin a user? Let's make this a little more simple...
        if m = ORIGIN_RE.match(@origin)
            @origin_nick, @origin_user, @origin_host = m[1..3]
        end
    end

    public

    # Was the message sent to a channel?
    #
    # @return [Boolean] true or false
    #
    def to_channel?
        %w(# & !).include?(@parv[0])
    end
end
