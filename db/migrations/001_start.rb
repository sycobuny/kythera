#
# kythera: services for IRC networks
# db/migrations/001_start.rb: create the database
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

Sequel.migration do
    change do
        create_table :users do
            primary_key :id

            # Their unique id is their email address
            String :email,    :unique => true, :null => false
            String :password, :null   => false
            String :salt,     :unique => true, :null => false

            # Some time records
            DateTime :register_date, :null => false
            DateTime :login_date

            # For email address verification
            String :verification_key

            # Index the email address
            index :email
        end
    end
end
