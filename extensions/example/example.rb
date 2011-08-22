#
# kythera: services for IRC networks
# extensions/example/example.rb: example extension
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

class ExampleExtension
    # If you get here, you're loaded and ready to go

    def initialize(config)
        @config = config
        #puts "ExampleExtension has been initialized!"
    end
end
