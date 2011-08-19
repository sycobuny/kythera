#
# kythera: services for IRC networks
# extensions/example/extension.rb: example extension
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

class ExampleExtensionHeader < Extension
    NAME = 'example'
    KYTHERA_VERSION = '~> 0.0'

    DEPENDENCIES = { 'sequel'   => '~> 3.23' }

    # This is called if your versions are right and your dependencies are met.
    # The rest is up to you.
    #
    def self.initialize
        require 'extensions/example/example'
    end
end
