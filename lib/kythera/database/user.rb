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
        one_to_many :user_flags

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

        # Returns user flags as symbols instead of objects
        #
        # @return [Array] symbols for all flags
        #
        def flags
            @flags ||= user_flags.collect { |uf| uf.flag.to_sym }
        end

        # Adds flags to a user. NB: params do not necessarily have to be symbols
        # as the method converts them internally.
        #
        # @param [Symbol] a flag to add
        # @param [Symbol] (optional) another flag to add
        # @etc
        # @return [Array] the flags sent to the method
        #
        def add_flags(*flags_to_add)
            $db.transaction do
                flags_to_add.each do |flag|
                    next if flags.include?(flag.to_sym)

                    user_flag = UserFlag.new
                    user_flag.flag = flag.to_s

                    flags << flag.to_sym
                    add_user_flag(user_flag)
                end
            end
        end

        # Removes flags from a user. NB: params do not necessarily have to be
        # symbols as the method converts them internally.
        #
        # @param [Symbol] a flag to remove
        # @param [Symbol] (optional) another flag to remove
        # @etc
        # @return [Array] the flags sent to the method
        #
        def remove_flags(*flags_to_rem)
            uf = user_flags.to_a

            $db.transaction do
                flags_to_rem.each do |flag|
                    ftr = uf.find { |f| f.flag == flag.to_s }
                    next unless ftr

                    flags.delete_if { |f| f == flag.to_sym }
                    ftr.delete
                end
            end
        end
    end

    # A user flag indicates a user is given elevated privileges
    class UserFlag < Sequel::Model
        many_to_one :user

        # Converts to a String
        def to_s
            flag
        end

        # Converts to a Symbol
        def to_sym
            flag.to_sym
        end
    end
end
