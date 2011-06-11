#
# kythera: services for TSora IRC networks
# lib/kythera/service/shrike.rb: implements shrike's X
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'kythera'

# This service is designed to implement the functionality of Shrike IRC Services
class Shrike < Service

    V_MAJOR = 0
    V_MINOR = 0
    V_PATCH = 1

    VERSION = "#{V_MAJOR}.#{V_MINOR}.#{V_PATCH}"

    # This is all we do for now :)
    #
    # @param [Uplink] uplink the interface to the IRC server
    # @param [Logger] logger our logger object
    #
    def initialize(uplink, logger)
        # Prepare the logger and uplink
        super

        log.info "shrike module loaded (version #{VERSION})"
    end
end
