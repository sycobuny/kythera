#
# kythera: services for IRC networks
# lib/kythera$log.rb: a bit of tweaking for Logger
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# Application-wide logger
$log = nil

# Just a few helpers for logging with a Logger
module Log

    # This class allows us to turn off logging easily
    class NilLogger
        include Singleton

        # Just do nothing
        def method_missing(name, *args)
        end
    end

    # This class overrides the default output formatting.
    # There's no documented way to do this; I had to figure it out.
    # That means this could break, and it's not "right."
    #
    class Formatter
        # String to use for formatting
        FORMAT = "%s, [%s] %s: %s\n"

        # Regex to use for replacing some `caller` info
        PN_RE  = /\:in \`.+\'/

        public

        # Gets called by Logger to format the output
        #
        # @param [String] severity log at this level
        # @param [Time] time when the event happened
        # @param [String] progname I don't usually use this
        # @param [String] msg the actual log message
        #
        def call(severity, time, progname, msg)
            severity = severity[0].chr
            datetime = time.strftime('%m/%d %H:%M:%S')
            progname = caller[3].split('/')[-1]

            # Include filename, line number, and method name in debug
            if severity == "DEBUG"
                progname.gsub!(PN_RE,       '')
                progname.gsub!('block in ', '')

                "[%s] (%s) %s: %s\n" % [datetime, severity, progname, msg]
            else
                "[%s] (%s) %s\n" % [datetime, severity, msg]
            end
        end
    end

    # Sets the logging object to use
    #
    # @param [Logger] logger the Logger to use (duck typing works fine here)
    #
    def self.logger=(logger)
        # Set to false/nil to disable logging...
        unless logger
            $log = NilLogger.instance
            return
        end

        if $log
            logger.level     = $log.level
            logger.formatter = $log.formatter
            $log             = logger
        else
            logger.formatter = Formatter.new
            $log             = logger
        end
    end

    # Sets the level at which we actually log
    #
    # @param [Symbol] level the level to log
    #
    def self.log_level=(level)
        case level
            when :none    then $log       = nil
            when :fatal   then $log.level = Logger::FATAL
            when :error   then $log.level = Logger::ERROR
            when :warning then $log.level = Logger::WARN
            when :info    then $log.level = Logger::INFO
            when :debug   then $log.level = Logger::DEBUG
            else               $log.level = Logger::WARN
        end
    end
end
