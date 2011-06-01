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

    # The receive-queue, which holds lines waiting to be parsed
    attr_accessor :recvq

    # Creates a new Uplink and includes the protocol-specific methods
    def initialize(config)
        @config = config
        @recvq  = []

        # Include the methods for the protocol we're using
        extend Protocol
        extend Protocol.find(@config.protocol)
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

    # Called by Connection when we're connected
    def connection_established
        send_pass
        send_capab
        send_server
        send_svinfo
    end

    def write(data)
        log.debug "<- #{data}"
        data += "\r\n"
        @connection.write data
    end

    NO_COL = 1 .. -1

    # Parses incoming IRC data and sends it off to protocol-specific handlers
    def parse
        while line = recvq.shift
            line.chomp!

            log.debug "-> #{line}"

            if line[0].chr == ':'
                # Remove the origin from the line, and eat the colon
                origin, line = line.split(' ', 2)
                origin = origin[NO_COL]
            else
                origin = nil
            end

            tokens, args = line.split(' :')
            parv = tokens.split(' ')
            cmd  = parv.delete_at(0)
            parv << args

            cmd = "receive_#{cmd.downcase}".to_sym

            self.send(cmd, origin, parv) if self.respond_to?(cmd, true)
        end
    end
end
