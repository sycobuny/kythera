#
# kythera: services for IRC networks
# ext/example/example.rb: example extension
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

class ExampleExtension
    # If you get here, you're loaded and ready to go

    def initialize
        puts "ExampleExtension has been initialized!"
    end
end

my_ext = ExampleExtension.new
