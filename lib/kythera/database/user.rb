#
# kythera: services for IRC networks
# lib/kythera/database/user.rb: registered users
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

module Database

    # A registered user has these attributes:
    #
    # email
    # password
    # register_date
    # login_date
    # verification_key
    #
    class User < Sequel::Model
        plugin :validation_helpers

        # Registers a new user
        #
        # @param [String] email the user's email address
        # @param [String] password the user's plain text password
        # @return [Database::User] user object
        #
        def self.register(email, password)
            user               = User.new
            user.email         = email
            user.register_date = Time.now

            user.store_password(password)
            user.save

            user
        end

        # Validations
        def validate
            super

            validates_type String, [:email, :password, :salt, :verification_key]
            validates_type Time, [:register_date, :login_date]

            validates_not_string [:register_date, :login_date]

            validates_presence [:email, :password, :register_date]

            validates_unique :email, :salt
        end

        # Stores a password hash and the salt used with it
        #
        # @param [String] password the password to hash
        #
        def store_password(passwd)
            self.salt     = SecureRandom.base64(256)
            saltbytes     = salt.unpack('m')[0]
            self.password = Digest::SHA2.hexdigest(saltbytes + passwd)
        end

        # Compares passwords
        #
        # @param [String] passwd the password to check for validity
        # @return [Boolean] true or false
        #
        def authenticate(passwd)
            Digest::SHA2.hexdigest(salt.unpack('m')[0] + passwd) == password
        end
    end
end
