#
# kythera: services for TSora IRC networks
# lib/kythera.rb: configuration DSL implementation
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

# Require all of our files here and only here
require 'kythera/loggable'
require 'kythera/run'

require 'ostruct'

# Starts the parsing of the configuraiton DSL
#
# @param [Proc] block contains the actual configuration code
#
def configure(&block)
    Kythera.config = Object.new

    class << Kythera.config
        # Adds methods to the parser from an arbitrary module
        #
        # @param [Module] mod the module containing methods to add
        #
        def use(mod)
            Kythera.config.extend mod
        end
    end

    # The configuration magic begins here...
    Kythera.config.instance_eval &block

    # Make sure the configuration information is valid
    Kythera.verify_configuration

    # Configuration is solid, now let's actually start up
    Kythera.run
end

# Contains all of the application-wide stuff
module Kythera
    # For backwards-incompatible changes
    V_MAJOR = 0

    # For backwards-compatible changes
    V_MINOR = 0

    # For minor changes and bugfixes
    V_PATCH = 1

    # A String representation of the version number
    VERSION = "#{V_MAJOR}.#{V_MINOR}.#{V_PATCH}"

    # Our name for things we print out
    ME = 'kythera'

    # Application-wide configuraiton settings
    @@config = nil

    # Configuration reader
    #
    # @return [Object] the configuration settings
    #
    def self.config
        @@config
    end

    # Configuration writer
    #
    # @param [Object] config a plain Object for the configuration
    # @return [Object] the new configuration settings
    #
    def self.config=(config)
        @@config = config
    end

    # Verifies that the configuration isn't invalid or incomplete
    def self.verify_configuration
        # XXX - configuration verification
    end
end

# Contains the methods that actually implement the configuration
module Kythera::Configuration

    # Holds the settings for the daemon section
    attr_reader :me

    # Holds the settings for the uplink section
    attr_reader :uplinks

    # Holds the settings for the userserv section
    attr_reader :user_service

    # Parses the `daemon` section of the configuration
    #
    # @param [Proc] block contains the actual configuration code
    #
    def daemon(&block)
        return if @me

        @me = OpenStruct.new
        @me.extend Kythera::Configuration::Daemon
        @me.instance_eval &block
    end

    # Parses the `uplink` section of the configuration
    #
    # @param [String] name the server name
    # @param [Proc] block contains the actual configuraiton code
    #
    def uplink(name, &block)
        ul      = OpenStruct.new
        ul.name = name

        ul.extend Kythera::Configuration::Uplink
        ul.instance_eval &block

        (@uplinks ||= []) << ul
    end

    # Parses the `userserv` section of the configuration
    #
    # @param [Proc] block contains the actual configuraiton code
    #
    def userserv(&block)
        return if @user_service

        @user_service = OpenStruct.new
        @user_service.extend Kythera::Configuration::UserServ
        @user_service.instance_eval &block
    end
end

# Implements the daemon section of the configuration
#
# If you're writing an extension that needs to add settings here,
# you should provide your own via `use`:
#
# @example Extend the daemon settings
#     daemon do
#         use MyExtension::Configuration::Daemon
#
#         # ...
#     end
#
# Directly reopening this module is possible, but not advisable.
#
module Kythera::Configuration::Daemon

    # Adds methods to the parser from an arbitrary module
    #
    # @param [Module] mod the module containing methods to add
    #
    def use(mod)
        self.extend mod
    end

    private

    def name(name)
        self.name = name
    end

    def description(desc)
        self.description = desc
    end

    def admin(name, email)
        self.admin_name  = name
        self.admin_email = email
    end

    def logging(level)
        self.logging = level
    end

    def reconnect_time(time)
        self.reconnect_time = time
    end

    def verify_emails(bool)
        self.verify_emails = bool
    end

    def mailer(mailer)
        self.mailer = mailer
    end
end

# Implements the uplink section of the configuration
#
# If you're writing an extension that needs to add settings here,
# you should provide your own via `use`:
#
# @example Extend the uplink settings
#     uplink 'some.up.link' do
#         use MyExtension::Configuration::Uplink
#
#         # ...
#     end
#
# Directly reopening this module is possible, but not advisable.
# Although there can be multiple `uplink` blocks in the configuration,
# you should only need to use `use` once.
#
module Kythera::Configuration::Uplink

    # Adds methods to the parser from an arbitrary module
    #
    # @param [Module] mod the module containing methods to add
    #
    def use(mod)
        self.extend mod
    end

    private

    def priority(pri)
        self.priority = pri.to_i
    end

    def bind(host, port = nil)
        self.bind_host = host
        self.bind_port = port
    end

    def send_password(password)
        self.send_password = password
    end

    def receive_password(password)
        self.receive_password = password
    end

    def network(name)
        self.network = name
    end

    def casemapping(mapping)
        self.casemapping = mapping
    end
end

# Implements the userserv section of the configuration
#
# If you're writing an extension that needs to add settings here,
# you should provide your own via `use`:
#
# @example Extend the userserv settings
#     userserv do
#         use MyExtension::Configuration::UserServ
#
#         # ...
#     end
#
# Directly reopening this module is possible, but not advisable.
#
module Kythera::Configuration::UserServ

    # Adds methods to the parser from an arbitrary module
    #
    # @param [Module] mod the module containing methods to add
    #
    def use(mod)
        self.extend mod
    end

    private

    def nickname(nick)
        self.nickname = nick
    end

    def username(user)
        self.username = user
    end

    def hostname(host)
        self.hostname = host
    end

    def realname(gecos)
        self.realname = gecos
    end

    def max(maxu)
        self.max = maxu
    end
end
