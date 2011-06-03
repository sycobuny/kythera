#
# kythera: services for TSora IRC networks
# lib/kythera/protocol/ts6/server.rb: TS6-specific Server class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'kythera'

# This reopens the base Server class in `kythera/server.rb`
class Server
    # The server's SID
    attr_reader :sid

    # Creates a new Server and adds it to the list keyed by SID
    def initialize(sid, logger)
        @sid    = sid
        @logger = logger

        @@servers[sid] = self

        log.debug "new server: #{@sid}"
    end
end
