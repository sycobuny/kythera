#
# kythera: services for IRC networks
# lib/kythera/extension.rb: extensions interface
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Copyright (c) 2011 Stephen Belcher <sycobuny@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'kythera'

# This is the base class for an extension. All extensions must subclass this.
# For the full documentation see `doc/extensions.md`
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
            pass = encrypt(password)

            vt = Digest::SHA2.hexdigest("--#{pass}--#{Time.now.to_s}--")

            account = Account.new

            account.login        = login
            account.salt         = salt
            account.password     = pass
            account.verification = vt
            account.registered   = now
            account.last_login   = now
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
            @authenticated
        end

        def authenticates?(password)
            password == encrypt(password)
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
                self.update(:last_login    => Time.now,
                            :failed_logins => 0)
                @logged_in = true
            else
                self.update(:failed_logins => failed_logins + 1)
                raise PasswordMismatchError
            end
        end

        def logout!
            @logged_in = false
        end

        def validated?
            validated.nil?
        end

        def validates?(validation)
            validated == self.validated
        end

        def validate(validation)
            begin
                validate!(validation)
                true
            rescue BadValidationError
                false
            end
        end

        def validate!(validation)
            if validates?(validation)
                update(:validation => nil)
            else
                raise BadValidationError
            end
        end

        def [](key)
            account_fields.find do |field|
                key.to_s == f.key
            end
        end

        def []=(key, value)
            if field = account_fields.find { |f| key.to_s == f.key }
                field.update(:value => value)
            else
                field = AccountField.new
                field.key   = key.to_s
                field.value = value

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

        def encrypt(password)
            saltbytes = salt.unpack('m')[0]
            Digest::SHA2.hexdigest(saltbytes + passwd)
        end
    end

    class AccountField < Sequel::Model
        many_to_one :account
    end
end
