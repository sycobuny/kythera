#
# kythera: services for TSora IRC networks
# lib/kythera/server.rb: defines the Server object
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

class Server
    include Loggable

    @@servers = {}

    def self.servers
        @@servers
    end

    attr_reader :sid, :users
    attr_accessor :description, :name

    def initialize(sid, name, logger)
        @sid   = sid
        @name  = name
        @users = {}

        self.logger = logger

        @@servers[sid] = self

        log.debug "Server#new: #{@name} (#{@sid})"
    end

    public

    def to_s
        "#{@name} (#{@sid})"
    end
end
