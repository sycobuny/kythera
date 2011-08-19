#
# kythera: services for IRC networks
# lib/kythera/run.rb: start up operations
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

class Kythera
    # Gets the ball rolling...
    def initialize
        puts "#{ME}: version #{VERSION} [#{RUBY_PLATFORM}]"

        # Run through some startup tests
        check_for_root
        check_ruby_version

        # Handle some signals
        trap(:INT)  { exit_app }
        trap(:TERM) { exit_app }

        # Some defaults for state
        logging  = true
        debug    = false
        willfork = RUBY_PLATFORM =~ /win32/i ? false : true
        wd       = Dir.getwd
        @uplink  = nil

        # Do command-line options
        opts = OptionParser.new

        d_desc = 'Enable debug logging'
        h_desc = 'Display usage information'
        n_desc = 'Do not fork into the background'
        q_desc = 'Disable regular logging'
        v_desc = 'Display version information'

        opts.on('-d', '--debug',   d_desc) { debug    = true  }
        opts.on('-h', '--help',    h_desc) { puts opts; abort }
        opts.on('-n', '--no-fork', n_desc) { willfork = false }
        opts.on('-q', '--quiet',   q_desc) { logging  = false }
        opts.on('-v', '--version', v_desc) { abort            }

        begin
            opts.parse(*ARGV)
        rescue OptionParser::ParseError => err
            puts err, opts
            abort
        end

        # Logging stuff
        if debug
            $-w = true
            logging = true
            $config.me.logging = :debug

            puts "#{ME}: warning: debug mode enabled"
            puts "#{ME}: warning: all activity will be logged in the clear"
        end

        Log.logger = nil unless logging

        # Are we already running?
        check_running

        # Time to fork...
        if willfork
            daemonize(wd)
            Log.logger = Logger.new('var/kythera.log', 'weekly') if logging
        else
            puts "#{ME}: pid #{Process.pid}"
            puts "#{ME}: running in foreground mode from #{wd}"

            # Foreground logging
            Log.logger = Logger.new($stdout) if logging
        end

        Log.log_level = $config.me.logging if logging
        $db.loggers << $log if debug

        # Write a pid file
        open('var/kythera.pid', 'w') { |f| f.puts Process.pid }

        # Enter the main event loop
        begin
            main_loop
        rescue Exception => err
            $log.fatal("exception in main_loop: #{err}")
            $log.fatal("backtrace: #{err.backtrace}")
            exit_app
        end

        # If we get to here we're exiting (this is a normal termination)
        exit_app
    end

    private

    # Runs the entire event-based app
    #
    # Once we enter this loop we only leave it to exit the app.
    # This makes sure we're connected and handles events, timers, and I/O
    #
    def main_loop
        loop do
            # If it's true we're connectED, if it's nil we're connectING
            connect until @uplink and @uplink.connected?

            # Only check for writable if we have data waiting to be written
            writefd = [@uplink.socket] if @uplink.need_write?

            # Ruby's threads suck. In theory, the timers should
            # manage themselves in separate threads. Unfortunately,
            # Ruby has a global lock and the scheduler isn't great, so
            # this tells select() to timeout when the next timer needs to run.
            #
            timeout = (Timer.next_time - Time.now.to_f).round
            timeout = 1 if timeout == 0 # Don't want 0, that's forever
            timeout = 60 if timeout < 0 # Less than zero means no timers

            # Wait up to 60 seconds for our socket to become readable/writable
            ret = IO.select([@uplink.socket], writefd, [], timeout)

            # This means select timed out and there's no activity on the socket
            next unless ret

            $eventq.post :socket_readable unless ret[0].empty?
            $eventq.post :socket_writable unless ret[1].empty?

            # Run the event loop until it's empty
            $eventq.run while $eventq.needs_run?
        end
    end

    # Connects to the uplink
    def connect
        # Clear all non-persistent Timers
        Timer.stop

        # Reset Services, as they're instantiated upon connection
        Service.services.clear

        if @uplink
           $log.debug "current uplink failed, trying next"

            curruli  = $config.uplinks.find_index(@uplink.config)
            curruli += 1
            curruli  = 0 if curruli > ($config.uplinks.length - 1)

            $eventq = EventQueue
            @uplink = Uplink.new($config.uplinks[curruli])

            sleep $config.me.reconnect_time
        else
            $eventq = EventQueue.new
            @uplink = Uplink.new($config.uplinks[0])
        end

        @uplink.connect
    end

    # Checks to see if we're running as root
    def check_for_root
        if Process.euid == 0
            puts "#{ME}: refuses to run as root"
            abort
        end
    end

    # Checks to see if we're running on a decent Ruby version
    def check_ruby_version
        if RUBY_VERSION < '1.9' and RUBY_VERSION < '1.8.7'
            puts "#{ME}: requires at least Ruby version 1.8.7"
            puts "#{ME}: you have #{RUBY_VERSION}"
            abort
        elsif RUBY_VERSION > '1.9' and RUBY_VERSION < '1.9.2'
            puts "#{ME}: requires at least Ruby version 1.9.2"
            puts "#{ME}: you have #{RUBY_VERSION}"
            abort
        elsif RUBY_VERSION >= '1.9.2'
            Encoding.default_internal = 'UTF-8'
            Encoding.default_external = 'UTF-8'
        end
    end

    # Checks for an existing pid file and running daemon
    def check_running
        return unless File.exists? 'var/kythera.pid'

        currpid = File.read('var/kythera.pid').chomp.to_i rescue nil
        running = Process.kill(0, currpid) rescue nil

        if not running or currpid == 0
            File.delete 'var/kythera.pid'
        else
            puts "#{ME}: daemon is already running"
            abort
        end
    end

    # Forks into the background and exits the parent
    #
    # @param [String] wd the directory to move into once forked
    #
    def daemonize(wd)
        begin
            pid = fork
        rescue Exception => err
            puts "#{ME}: unable to daemonize: #{err}"
            abort
        end

        # This is the parent process
        if pid
            puts "#{ME}: pid #{pid}"
            puts "#{ME}: running in background mode from #{Dir.getwd}"
            exit
        end

        # This is the child process
        Dir.chdir(wd)
    end

    # Cleans up before exiting
    def exit_app
        $log.close if $log
        File.delete 'var/kythera.pid'
        exit
    end
end
