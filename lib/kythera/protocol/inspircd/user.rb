#
# kythera: services for IRC networks
# lib/kythera/protocol/inspircd/user.rb: InspIRCd-specific User class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Copyright (c) 2011 Andrew Herbig <goforit7arh@gmail.com>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# This reopens the base User class in `kythera/user.rb`
class User
    # InspIRCd usermodes
    @@user_modes = { 'i' => :invisible,
                     'o' => :operator,
                     's' => :receives_snotices,
                     'w' => :wallop,
                     'B' => :bot,
                     'c' => :common_chans,
                     'd' => :chan_deaf,
                     'g' => :callerid,
                     'G' => :censor,
                     'h' => :helpop,
                     'H' => :hideoper,
                     'I' => :hidechans,
                     'k' => :servprotect,
                     'Q' => :unethical,
                     'r' => :registered,
                     'R' => :registered_privmsg,
                     'S' => :stripcolor,
                     'W' => :show_whois,
                     'x' => :m_cloaking }

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
        @uid       = uid
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
