#
# kythera: services for TSora IRC networks
# lib/kythera/run.rb: start up operations
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'kythera'

require 'logger'
require 'optparse'

module Kythera
    # Gets the ball rolling...
    def self.run
        puts "#{ME}: version #{VERSION} [#{RUBY_PLATFORM}]"

        # Run through some startup tests
        Kythera.check_for_root
        Kythera.check_ruby_version
        Kythera.require_dependencies

        # Handle some signals
        trap(:INT)  { self.exit_app }
        trap(:TERM) { self.exit_app }

        # Some defaults for state
        logging  = true
        logger   = nil
        debug    = false
        willfork = RUBY_PLATFORM =~ /win32/i ? false : true
        wd       = Dir.getwd

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

        # Debugging stuff
        if debug
            $-w = true

            puts "#{ME}: warning: debug mode enabled"
            puts "#{ME}: warning: all activity will be logged in the clear"
        end

        # Are we already running?
        Kythera.check_running

        # Time to fork...
        if willfork
            Kythera.daemonize wd

            if logging or debug
                Dir.mkdir 'var' unless File.exists? 'var'
                logger = Logger.new('var/kythera.log', 'weekly')
            end
        else
            puts "#{ME}: pid #{Process.pid}"
            puts "#{ME}: running in foreground mode from #{wd}"

            # Foreground logging
            logger = Logger.new($stdout) if logging or debug
        end

        # Write a pid file
        Dir.mkdir 'var' unless File.exists? 'var'
        open('var/kythera.pid', 'w') { |f| f.puts Process.pid }

        # XXX - connect to uplink!

        # If we get to here we're exiting
        logger.close if logger
        self.exit_app
    end

    # Checks to see if we're running as root
    def self.check_for_root
        if Process.euid == 0
            puts "#{ME}: refuses to run as root"
            abort
        end
    end

    # Checks to see if we're running on a decent Ruby version
    def self.check_ruby_version
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

        unless defined? Rubinius
            puts "#{ME}: runs best on Rubinius (http://rubini.us/)"
        end
    end

    # Requires our dependencies
    def self.require_dependencies
        begin
            lib = nil
            %w(rubygems cool.io sequel sqlite3).each do |m|
                lib = m
                require lib
            end
        rescue LoadError
            puts "#{ME}: could not load #{lib}"
            puts "#{ME}: this library is required for operation"
            puts "#{ME}: gem install --remote #{lib}"
            abort
        end
    end

    # Checks for an existing pid file and running daemon
    def self.check_running
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
    def self.daemonize(wd)
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
        Dir.chdir wd
    end

    # Cleans up before exiting
    def self.exit_app
        File.delete 'var/kythera.pid'
        exit
    end
end
