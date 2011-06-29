#
# kythera: services for IRC networks
# lib/kythera/protocol/unreal/server.rb: UnrealIRCd-specific Server class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Copyright (c) 2011 Andrew Herbig <goforit7arh@gmail.com>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# This reopens the base Server class in `kythera/server.rb`
class Server
    # Creates a new Server and adds it to the list keyed by numeric
    def initialize(name, logger)
        @name   = name
        @users  = []
        @logger = nil

        self.logger = logger

        if @@servers[name]
            log.error "new server replacing server with same name!"
        end

        @@servers[name] = self

        log.debug "new server initialized: #{@name}"
    end
end
