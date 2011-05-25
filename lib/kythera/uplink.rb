#
# kythera: services for TSora IRC networks
# lib/kythera/uplink.rb: represents the interface to the remote IRC server
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

# Represents the interface to the remote IRC server
# XXX - ircd protocol shit goes here...
class Uplink
    include Loggable

    # The configuration information
    attr_accessor :config

    # The cool.io socket
    attr_accessor :connection

    def initialize(config)
        @config     = config
        @connection = nil
    end

    public

    def to_s
        "#{@config.name}:#{@config.port}"
    end

    def name
        @config.name
    end

    def port
        @config.port
    end

    def connected?
        @connection ? @connection.connected? : false
    end

    def parse(data)
        # XXX - parse data!
    end
end
