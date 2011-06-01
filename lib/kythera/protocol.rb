#
# kythera: services for TSora IRC networks
# lib/kythera/protocol.rb: implements protocol basics
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

module Protocol
    # Allows protocol module names to be case-insensitive
    def self.find(mod)
        Protocol.const_get Protocol.constants.find { |c| c =~ /^#{mod}$/i }
    end
end
