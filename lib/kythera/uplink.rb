#
# kythera: services for IRC networks
# lib/kythera/uplink.rb: represents the interface to the remote IRC server
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# Represents the interface to the remote IRC server
class Uplink
    include Loggable

    # The configuration information
    attr_accessor :config

    # The TCPSocket
    attr_reader :socket

    # Creates a new Uplink and includes the protocol-specific methods
    def initialize(config, logger)
        @config    = config
        @connected = false
        @recvq     = []
        @sendq     = []
        @socket    = nil
        @logger    = nil

        self.logger = logger

        # Set up some event handlers
        $eventq.handle(:socket_readable) { read  }
        $eventq.handle(:socket_writable) { write }
        $eventq.handle(:recvq_ready)     { parse }

        $eventq.handle(:connected) { send_handshake }
        $eventq.handle(:connected) { Service.instantiate(self, @logger) }

        $eventq.handle(:end_of_burst) do |delta|
            log.info "finished synching to network in #{delta}s"
        end

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
        @connected
    end

    # Returns whether the sendq needs written
    #
    # @return [Boolean] true or false
    #
    def need_write?
        not @sendq.empty?
    end

    # Sets our state to not connected
    #
    # @param [Boolean] bool true or false
    #
    def dead=(bool)
        if bool
            log.info "lost connection to #{@config.name}:#{@config.port}"

            $eventq.post(:disconnected)

            @socket.close if @socket
            @recvq.clear

            @connected = false
            @socket    = nil
        end
    end

    # Connects to the uplink using the information in `@config`
    def connect
        log.info "connecting to #{@config.host}:#{@config.port}"

        begin
            @socket = TCPSocket.new(@config.host, @config.port,
                                    @config.bind_host, @config.bind_port)
        rescue Exception => err
            log.error "connection failed: #{err}"
            self.dead = true
            return
        else
            log.info "successfully connected to #{@config.name}:#{@config.port}"

            @connected = true

            $eventq.post(:connected)
        end
    end

    # Matches CR or LF
    CR_OR_LF = /\r|\n/

    # Reads waiting data from the socket and stores each "line" in the recvq
    def read
        begin
            data = @socket.read_nonblock(8192)
        rescue Errno::EAGAIN
            retry # XXX - maybe add this back to the readfds?
        rescue Exception => err
            data = nil # Dead
        end

        if not data or data.empty?
            log.error "read error from #{@config.name}: #{err}" if err
            self.dead = true
            return
        end

        # Passes every "line" to the block, including "\n"
        data.scan /(.+\n?)/ do |line|
            line = line[0]

            # If the last line had no \n, add this one onto it.
            if @recvq[-1] and @recvq[-1][-1].chr !~ CR_OR_LF
                @recvq[-1] += line
            else
                @recvq << line
            end
        end

        $eventq.post(:recvq_ready) if @recvq[-1] and @recvq[-1][-1].chr == "\n"
    end

    # Writes the each "line" in the sendq to the socket
    def write
        begin
            # Use shift because we need it to fall off immediately
            while line = @sendq.shift
                log.debug "<- #{line}"
                line += "\r\n"
                @socket.write_nonblock(line)
            end
        rescue Errno::EAGAIN
            retry # XXX - maybe add this back to the writefds?
        rescue Exception => err
            log.error "write error to #{@config.name}: #{err}"
            self.dead = true
            return
        end
    end

    private

    # Removes the first character from a string
    NO_COL = 1 .. -1

    # Because String#split treats ' ' as /\s/ for some reason
    RE_SPACE = / /

    # Parses incoming IRC data and sends it off to protocol-specific handlers
    def parse
        while line = @recvq.shift
            line.chomp!

            log.debug "-> #{line}"

            # don't do anything if the line is empty
            next if line.empty?

            if line[0].chr == ':'
                # Remove the origin from the line, and eat the colon
                origin, line = line.split(RE_SPACE, 2)
                origin = origin[NO_COL]
            else
                origin = nil
            end

            tokens, args = line.split(' :', 2)
            parv = tokens.split(RE_SPACE)
            cmd  = parv.delete_at(0)
            parv << args unless args.nil?

            # Some IRCds have commands like '&' that we translate for methods
            cmd = TOKENS[cmd] if defined?(TOKENS)

            # Downcase it and turn it into a Symbol
            cmd = "irc_#{cmd.downcase}".to_sym

            # Call the protocol-specific handler
            if self.respond_to?(cmd, true)
                self.send(cmd, origin, parv)
            else
                log.debug "no protocol handler for #{cmd.to_s.upcase}"
            end

            # Fire off an event for extensions, etc
            $eventq.post(cmd, origin, parv)
        end
    end
end
