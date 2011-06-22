#
# kythera: services for IRC networks
# lib/kythera/service/shrike.rb: implements shrike's X
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

class Shrike < Service
    private

    # This is dangerous, and is only here for my testing purposes - XXX
    def do_raw(user, params)
        return unless user.operator?

        @uplink.raw(params.join(' '))
    end

    # Extremely dangerous, this is here only for my testing purposes! - XXX
    def do_eval(user, params)
        return unless user.operator?

        code = params.join(' ')

        result = eval(code)

        @uplink.privmsg(@user, @config.channel, "#{result.inspect}")
    end
end
