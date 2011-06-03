#
# kythera: services for TSora IRC networks
# lib/kythera/server.rb: Server class
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'kythera'

# This is just a base class. All protocol module should monkeypatch this.
class Server
    include Loggable

    # A list of all servers. The protocol module should decide what the key is.
    @@servers = {}

    # Attribute reader for `@@servers`
    #
    # @return [Hash] a list of all Servers
    #
    def self.servers
        @@servers
    end

    # The server's name
    attr_accessor :name

    # The server's description
    attr_accessor :description

    # Creates a new server. Should be patched by the protocol module.
    def initialize(logger)
        @logger = logger
    end
end
