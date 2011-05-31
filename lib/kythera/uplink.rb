#
# kythera: services for TSora IRC networks
# lib/kythera/uplink.rb: represents the interface to the remote IRC server
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

# Represents the interface to the remote IRC server
class Uplink
    include Loggable

    # The configuration information
    attr_accessor :config

    # The cool.io socket
    attr_accessor :connection

    # Creates a new Uplink and includes the protocol-specific methods
    def initialize(config)
        @config     = config
        @connection = nil

        # Include the methods for the protocol we're using
        require "kythera/protocol/#{@config.protocol.to_s.downcase}"
        extend Protocol.const_get(@config.protocol)
    end

    public

    # Represents the Uplink as a String
    #
    # @return [String] name:port
    #
    def to_s
        "#{@config.name}:#{@config.port}"
    end

    # Returns the Uplink name from configuration
    #
    # @return [String] Uplink's name in the configuration file
    #
    def name
        @config.name
    end

    # Returns the Uplink port from configuration
    #
    # @return [Fixnum] Uplink's port in the configuration file
    #
    def port
        @config.port
    end

    # Returns whether we're connected or not
    #
    # @return [Boolean] true or false
    #
    def connected?
        @connection ? @connection.connected? : false
    end

    # Parses incoming IRC data and sends it off to protocol-specific handlers
    #
    # @param [String] data data from the IRC server
    #
    def parse(data)
        # XXX - parse data!
    end
end
