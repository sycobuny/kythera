#
# kythera: services for IRC networks
# lib/kythera/protocol/inspircd/server.rb: InspIRCd-specific Server class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Copyright (c) 2011 Andrew Herbig <goforit7arh@gmail.com>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# This reopens the base Server class in `kythera/server.rb`
class Server
    # The server's SID
    attr_reader :sid

    # Creates a new Server and adds it to the list keyed by SID
    def initialize(sid, logger)
        @sid    = sid
        @users  = []
        @logger = nil

        self.logger = logger

        log.error "new server replacing server with same SID!" if @@servers[sid]

        @@servers[sid] = self

        log.debug "new server initialized: #{@sid}"
    end
end
