#
# kythera: services for IRC networks
# lib/kythera/database.rb: database routines
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

$db = Sequel.sqlite('db/kythera.db')

require 'kythera/database/user'

# Namespace to bind objects to the database
module Database
end
