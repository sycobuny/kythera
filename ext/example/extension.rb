#
# kythera: services for IRC networks
# ext/example/extension.rb: example extension
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

class ExampleExtensionHeader < Extension
    NAME = 'example'
    KYTHERA_VERSION = '~> 0.0'
end
