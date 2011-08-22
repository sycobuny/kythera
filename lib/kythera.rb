#
# kythera: services for IRC networks
# lib/kythera.rb: configuration DSL implementation
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

# Check for our dependencies before doing _anything_ else
DEPENDENCIES = { 'sequel'   => '~> 3.23',
                 'sqlite3'  => '~> 1.3' }

DEPENDENCIES.each do |name, reqs|

    spec = Gem::Specification.find_all_by_name(name, reqs)

    if spec.empty?
        puts "kythera: depends on #{name} #{reqs}"
        puts "kythera: this library is required for operation"
        puts "kythera: gem install --remote #{name}"
        abort
    else
        require name
    end
end

# Require all the Ruby stdlib stuff we need
require 'logger'
require 'optparse'
require 'ostruct'
require 'singleton'
require 'socket'

require 'digest/sha2'

# Require all of our files here and only here
require 'kythera/log'
require 'kythera/channel'
require 'kythera/database'
require 'kythera/event'
require 'kythera/extension'
require 'kythera/protocol'
require 'kythera/run'
require 'kythera/securerandom'
require 'kythera/server'
require 'kythera/service'
require 'kythera/timer'
require 'kythera/uplink'
require 'kythera/user'

# Require all of our extensions
Dir.glob(['extensions/**/extension.rb']) { |filepath| require filepath }

# Starts the parsing of the configuraiton DSL
#
# @param [Proc] block contains the actual configuration code
#
def configure(&block)
    # This is for storing random application states
    $state = {}

    $config = Object.new

    class << $config
        # Adds methods to the parser from an arbitrary module
        #
        # @param [Module] mod the module containing methods to add
        #
        def use(mod)
            $config.extend(mod)
        end
    end

    # The configuration magic begins here...
    $config.instance_eval(&block)

    # Make sure the configuration information is valid
    Kythera.verify_configuration

    # Verify extension compatibility
    Extension.verify_and_load

    # Configuration is solid, now let's actually start up
    Kythera.new
end

# Contains all of the application-wide stuff
class Kythera
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

    # Verifies that the configuration isn't invalid or incomplete
    def self.verify_configuration
        # XXX - configuration verification
        $config.uplinks.sort! { |a, b| a.priority <=> b.priority }
    end
end

# Contains the methods that actually implement the configuration
module Kythera::Configuration
    # Holds the settings for the daemon section
    attr_reader :me

    # Holds the settings for the uplink section
    attr_reader :uplinks

    # Holds the settings for services
    attr_reader :services

    # Reports an error about an unknown directive
    def method_missing(meth, *args, &block)
       puts "kythera: unknown configuration directive '#{meth}' (ignored)"
    end

    # Load a service and parse its configuration
    #
    # The configuration will be placed at $config.name_of_service
    #
    # @param [Symbol] name name of the service
    #
    def service(name, &block)
        # Start by loading the service
        begin
            require "kythera/service/#{name}"
        rescue LoadError
            puts "kythera: couldn't load service: #{name} (ignored)"
            return
        end

        # Find the Service's class
        srv = Service.services_classes.find { |s| s::NAME == name }

        begin
            # Find the Service's configuration methods
            srv_config_parser = srv::Configuration
        rescue NameError
            puts "kythera: service has no configuration handlers: #{name}"
        else
            # Parse the configuration block
            srv_config = OpenStruct.new
            srv_config.extend(srv_config_parser)
            srv_config.instance_eval(&block)

            # Store it in $config
            instance_variable_set("@#{srv::NAME}", srv_config)

            # Make it readable
            Kythera::Configuration.class_exec do
                attr_reader srv::NAME
            end
        end
    end

    # Load an extension's configuration
    #
    # If an extension provides configuration methods, this method parses the
    # configuration into an OpenStruct like the rest of the configuration and
    # stores it in `$state`. When the extension is verified & loaded, the
    # OpenStruct will be passed to its initialize method. If it fails
    # verification it will be erased.
    #
    # @param [Symbol] name the name of the extension
    #
    def extension(name, &block)
        $state[:ext_cfg] ||= {}

        # Find the Extension's class
        ext = Extension.extensions.find { |e| e::NAME == name }

        unless ext
            puts "kythera: unknown extension configuration: #{name} (ignored)"
        else
            begin
                # Find the Extension's configuration methods
                ext_config_parser = ext::Configuration
            rescue NameError
                puts "kythera: extension has no configuration handlers: #{name}"
            else
                # Parse the configuration block
                ext_config = OpenStruct.new
                ext_config.extend(ext_config_parser)
                ext_config.instance_eval(&block)

                # Store it in $state[:ext_cfg]
                $state[:ext_cfg][ext::NAME] = ext_config
            end
        end
    end

    # Parses the `daemon` section of the configuration
    #
    # @param [Proc] block contains the actual configuration code
    #
    def daemon(&block)
        return if @me

        @me = OpenStruct.new
        @me.extend(Kythera::Configuration::Daemon)
        @me.instance_eval(&block)
    end

    # Parses the `uplink` section of the configuration
    #
    # @param [String] name the server name
    # @param [Proc] block contains the actual configuraiton code
    #
    def uplink(host, port = 6667, &block)
        ul      = OpenStruct.new
        ul.host = host.to_s
        ul.port = port.to_i

        ul.extend(Kythera::Configuration::Uplink)
        ul.instance_eval(&block)

        (@uplinks ||= []) << ul
    end
end

# Implements the daemon section of the configuration
#
# If you're writing an extension that needs to add settings here,
# you should provide your own via `use`.
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
        self.extend(mod)
    end

    private

    def name(name)
        self.name = name.to_s
    end

    def description(desc)
        self.description = desc.to_s
    end

    def admin(name, email)
        self.admin_name  = name.to_s
        self.admin_email = email.to_s
    end

    def logging(level)
        self.logging = level
    end

    def unsafe_extensions(action)
        self.unsafe_extensions = action
    end

    def reconnect_time(time)
        self.reconnect_time = time.to_i
    end

    def verify_emails(bool)
        self.verify_emails = bool
    end

    def mailer(mailer)
        self.mailer = mailer.to_s
    end
end

# Implements the uplink section of the configuration
#
# If you're writing an extension that needs to add settings here,
# you should provide your own via `use`.
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
        self.extend(mod)
    end

    private

    def priority(pri)
        self.priority = pri.to_i
    end

    def name(name)
        self.name = name.to_s
    end

    def bind(host, port = nil)
        self.bind_host = host.to_s
        self.bind_port = port.to_i
    end

    def send_password(password)
        self.send_password = password.to_s
    end

    def receive_password(password)
        self.receive_password = password.to_s
    end

    def network(name)
        self.network = name
    end

    def protocol(protocol)
        self.protocol = protocol

        # Check to see if they specified a valid protocol
        begin
            require "kythera/protocol/#{protocol.to_s.downcase}"
        rescue LoadError
            raise "invalid protocol `#{protocol}` for uplink `#{name}`"
        end

        proto = Protocol.find(protocol)

        raise "invalid protocol `#{protocol}` for uplink `#{name}`" unless proto
    end

    def sid(sid)
        self.sid = sid.to_s
    end

    def casemapping(mapping)
        self.casemapping = mapping
    end
end
