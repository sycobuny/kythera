#
# kythera: services for TSora IRC networks
# lib/kythera/event.rb: implements the event loop
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'kythera'

# Contains information about a posted event
class Event
    # The name of the event
    attr_reader :event

    # The arguments to pass to the handler
    attr_reader :args

    # Creates a new Event
    #
    # @param [Symbol] event unique event name
    # @param args the arguments to be passed to the handler
    #
    def initialize(event, *args)
        @event = event
        @args  = args
    end
end

# A queue of events, with handlers
class EventQueue
    include Loggable

    # The list of Events
    attr_reader :queue

    # The list of code blocks
    attr_reader :handlers

    # Creates a new EventQueue
    def initialize
        @queue    = []
        @handlers = {}
    end

    public

    # Posts a new event to the queue to be handled
    #
    # @param [Symbol] event unique event name
    # @param args the arguments to be passed to the handler
    #
    def post(event, *args)
        @queue << Event.new(event, *args)
        log.debug "posted new event: #{event}"
    end

    # Registers a handler for an event
    #
    # @param [Symbol] event unique event name
    # @param [Proc] block the handling code
    #
    def handle(event, &block)
        (@handlers[event] ||= []) << block
        log.debug "registered handler for event: #{event}"
    end

    # Does the queue need emptied?
    #
    # @return [Boolean] true or false
    #
    def needs_ran?
        @queue.empty? ? false : true
    end

    # Goes through the event queue and runs the handlers
    def run
        while e = @queue.shift
            unless @handlers[e.event]
                log.debug "no handlers for event: #{e.event}"
                next
            end

            log.debug "dispatching handlers for event: #{e.event}"
            @handlers[e.event].each { |block| block.call(*e.args) }
        end
    end
end
