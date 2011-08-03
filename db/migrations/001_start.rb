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

        create_table :channels do
            primary_key :id

            # Name, which naturally must be unique
            String :name, :unique => :true, :null => false

            # When was the channel registered?
            DateTime :register_date, :null => false
        end

        create_table :user_flags do
            primary_key :id

            # The only columns are user_id and flag, both required
            Integer :user_id, :null => false
            String  :flag,    :null => false

            # The user_id column is associated with the users table
            foreign_key [:user_id], :users

            # Add a unique constraint on the two columns
            unique [:user_id, :flag]
        end

        create_table :channel_flags do
            primary_key :id

            # The only columns are channel_id and flag, both required
            Integer :channel_id, :null => false
            String  :flag,       :null => false

            # The channel_id column is associated with the channels table
            foreign_key [:channel_id], :channels

            # Add a unique constraint on the two columns
            unique [:channel_id, :flag]
        end

        create_table :channel_user_flags do
            primary_key :id

            # The only columns are channel_id, user_id and flag, all required
            Integer :channel_id, :null => false
            Integer :user_id,    :null => false
            String  :flag,       :null => false

            # The channel_id column is associated with the channels table
            # The user_id column is associated with the users table
            foreign_key [:channel_id], :channels
            foreign_key [:user_id],    :users

            # Add a unique constraint on the three columns
            unique [:channel_id, :user_id, :flag]
        end
    end
end
