#
# kythera: services for IRC networks
# lib/kythera/database/account.rb: core account and accountfield models
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Copyright (c) 2011 Stephen Belcher <sycobuny@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# This is the core Account model which all services and extensions should use
# for user management. While you can push directly into the database using
# built-in Sequel ORM magic, it's advised you treat the class as read-only
# except for the API specified here.
#

module Database
    class Account < Sequel::Model
        one_to_many :account_fields

        def self.register(login, password, verification)
            begin
                register!(login, password, verification)
            rescue LoginExistsError, PasswordMismatchError
                nil
            end
        end

        def self.register!(login, password, verification)
            raise LoginExistsError unless self.where(:login => login).empty?
            raise PasswordMismatchError unless password == verification

            now  = Time.now
            salt = SecureRandom.base64(256)
            pass = encrypt(salt, password)
            vt   = Digest::SHA2.hexdigest("--#{pass}--#{now.to_s}--")

            account = new
            account.login        = login
            account.salt         = salt
            account.password     = pass
            account.verification = vt
            account.registered   = now
            account.last_login   = now

            account.save
            account
        end

        def self.identify(login, password)
            begin
                identify!(login, password)
            rescue NoSuchLoginError, PasswordMismatchError
                nil
            end
        end

        def self.identify!(login, password)
            account = self.where(:login => login).first
            raise NoSuchLoginError unless account

            account.authenticate!(password)
        end

        def authenticated?()
            @authenticated ||= false
        end

        def authenticates?(password)
            self.password == encrypt(password)
        end

        def authenticate(password)
            begin
                authenticate!(password)
                true
            rescue PasswordMismatchError
                false
            end
        end

        def authenticate!(password)
            pass = encrypt(password)

            if authenticates?(password)
                self.update(:last_login => Time.now, :failed_logins => 0)
                @authenticated = true
            else
                self.update(:failed_logins => self.failed_logins + 1)
                raise PasswordMismatchError
            end

            self
        end

        def logout!
            @authenticated = false
        end

        def verified?
            self.verification.nil?
        end

        def verifies?(verification)
            verification == self.verification
        end

        def verify(verification)
            begin
                verify!(verification)
                true
            rescue BadVerificationError
                false
            end
        end

        def verify!(verification)
            if verifies?(verification)
                self.update(:verification => nil)
            else
                raise BadVerificationError
            end
        end

        def [](key)
            field = account_fields.find { |f| key.to_s == f.key }
            field ? field.value : nil
        end

        def []=(key, value)
            if field = account_fields.find { |f| key.to_s == f.key }
                field.update(:value => value.to_s)
            else
                field = AccountField.new
                field.key   = key.to_s
                field.value = value.to_s

                account_fields << field
            end
        end

        def keys
            account_fields.collect { |field| field.key }
        end

        def delete_field(key)
            returns unless field = account_fields.find { |f| key.to_s = f.key }
            field.delete
        end

        class LoginExistsError      < Exception; end
        class PasswordMismatchError < Exception; end
        class BadValidationError    < Exception; end
        class NoSuchLoginError      < Exception; end

        #######
        private
        #######

        def self.encrypt(salt, password)
            saltbytes = salt.unpack('m')[0]
            Digest::SHA2.hexdigest(saltbytes + password)
        end

        def encrypt(password)
            self.class.encrypt(self.salt, password)
        end
    end

    class AccountField < Sequel::Model
        many_to_one :account
    end
end
