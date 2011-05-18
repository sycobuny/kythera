#
# kythera: services for TSora IRC networks
# lib/kythera/run.rb: start up operations
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'optparse'

require 'kythera'

module Kythera
    # Gets the ball rolling...
    def self.run
        puts "#{ME}: version #{VERSION} [#{RUBY_PLATFORM}]"

        # Run through some startup tests
        Kythera.check_for_root
        Kythera.check_ruby_version
        Kythera.require_dependencies

        # Some defaults for state
        logging  = true
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
        rescue OptionParser::ParseError => e
            puts e, opts
            abort
        end

        # Interpreter warnings
        $-w = true if debug

        puts "#{ME}: i don't do anything else yet, but bravo, brave one."
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
        rescue LoadError => e
            puts "#{ME}: could not load #{lib}"
            puts "#{ME}: this library is required for operation"
            puts "#{ME}: gem install --remote #{lib}"
            abort
        end
    end
end
