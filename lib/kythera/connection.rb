#
# kythera: services for TSora IRC networks
# lib/kythera/connection.rb: interfaces to cool.io
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'kythera'
require 'kythera/loggable'

# Provides all of our networking needs
class Connection < Cool.io::TCPSocket
    include Loggable

    # References back to our Uplink... circular, so take good care of this
    attr_accessor :uplink

    public

    def connected?
        @connected
    end

    private

    # Called when a connection is established
    def on_connect
        @connected = true

        log.info "successfully connected to #{@remote_host}:#{@remote_port}"

        @uplink.connection_established
    end

    # Called when a connection fails
    def on_connect_failed
        @connected = false
        @uplink    = nil
    end

    # Called when the connection is closed or lost
    def on_close
        @connected = false
        @uplink    = nil

        log.info "lost connection to #{@remote_host}:#{@remote_port}"
    end

    # Called when data has been read and is waiting to be parsed
    def on_read(data)
        data.scan /(.+\n?)/ do |line|
            line = line[0]

            # If the last line had no \n, add this one onto it.
            if @uplink.recvq[-1] and @uplink.recvq[-1][-1].chr != "\n"
                @uplink.recvq[-1] += line
            else
                @uplink.recvq << line
            end
        end

        @uplink.parse if @uplink.recvq[-1] and @uplink.recvq[-1][-1].chr == "\n"
    end
end
