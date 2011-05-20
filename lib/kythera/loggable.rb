#
# kythera: services for TSora IRC networks
# lib/kythera/loggable.rb: instant logging, just include Loggable
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

# A mixin to add easy logging to your class
# Just `include Loggable` and call `self.logger=`
#
module Loggable

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
            datetime = time.strftime('%m/%d %H:%M:%S')
            progname = caller[3].split('/')[-1]

            # Include filename, line number, and method name in debug
            if severity == "DEBUG"
                progname.gsub!(PN_RE,       '')
                progname.gsub!('block in ', '')

                "[%s] %s: %s\n" % [datetime, progname, msg]
            else
                "[%s] %s\n" % [datetime, msg]
            end
        end
    end

    # Returns our proxy logger so we can do `log.info` instead of `@logger.info`
    def log
        @logger
    end

    # Sets the logging object to use
    #
    # @param [Logger] logger the Logger to use (duck typing works fine here)
    #
    def logger=(logger)

        # Set to false/nil to disable logging...
        unless logger
            @logger = nil
            return
        end

        if @logger
            logger.level     = @logger.level
            logger.formatter = @logger.formatter
            @logger          = logger
        else
            logger.formatter = Formatter.new
            @logger          = logger
        end
    end

    # Sets the level at which we actually log
    #
    # @param [Symbol] level the level to log
    #
    def log_level=(level)
        case level
            when :none    then @logger       = nil
            when :fatal   then @logger.level = Logger::FATAL
            when :error   then @logger.level = Logger::ERROR
            when :warning then @logger.level = Logger::WARN
            when :info    then @logger.level = Logger::INFO
            when :debug   then @logger.level = Logger::DEBUG
            else               @logger.level = Logger::WARN
        end
    end
end
