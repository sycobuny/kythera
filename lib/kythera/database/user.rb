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
        one_to_many :channel_user_flags

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

        # Returns user flags as Symbols instead of objects
        #
        # @return [Array] symbols for all flags
        #
        def flags
            # iterate each UserFlag object and just cache the "flag" member as a
            # Symbol, cause that's what we'll need most frequently
            @flags ||= user_flags.collect { |uf| uf.flag.to_sym }
        end

        # Adds flags to a User
        #
        # @param [Symbol,String] a flag or flags to add
        #
        def add_flags(*flags_to_add)
            # backup our cache because we're going to be editing it directly,
            # and we want to ensure we can rollback if problems arise
            uf = flags.dup

            begin
                # transaction safety!
                $db.transaction do
                    flags_to_add.each do |flag|
                        # don't bother adding a flag we've already got
                        next if flags.include?(flag.to_sym)

                        # otherwise, make a new ChannelFlag object and set it up
                        user_flag = UserFlag.new
                        user_flag.flag = flag.to_s

                        # add the flags to our cache and the DB
                        flags << flag.to_sym
                        add_user_flag(user_flag)
                    end
                end
            rescue Exception => e
                # rollback changes to our cache if we couldn't save, and then
                # reraise cause we don't know for sure how to proceed from here
                @flags = uf
                raise e
            end
        end

        # Removes flags from a User
        #
        # @param [Symbol,String] a flag or flags to remove
        #
        def remove_flags(*flags_to_rem)
            # backup our cache because we're going to be editing it directly,
            # and we want to ensure we can rollback if problems arise
            uf = flags.dup

            begin
                # transaction safety!
                $db.transaction do
                    flags_to_rem.each do |flag|
                        # find the flag in the user_flags so we can get the
                        # UserFlag object proper, not just a Symbol
                        ftr = user_flags.find { |f| f.flag == flag.to_s }
                        next unless ftr

                        # delete the element in our cached array as well as in
                        # the database
                        flags.delete_if { |f| f == flag.to_sym }
                        ftr.delete
                    end
                end
            rescue Exception => e
                # rollback changes to our cache if we couldn't save, and then
                # reraise cause we don't know for sure how to proceed from here
                @flags = uf
                raise e
            end
        end

        # Converts object to its database ID
        #
        # @return [Integer] database ID
        #
        def to_i
            id
        end
    end

    # A user flag indicates a user is given elevated privileges
    class UserFlag < Sequel::Model
        many_to_one :user
        include GenericFlag
    end
end
