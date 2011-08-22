    kythera: services for IRC networks

    Copyright (c) 2011 Eric Will <rakaur@malkier.net>
    Rights to this code are documented in doc/license.txt

Service Interface
=================

Since your code is executed upon load, most things are taken care of
automatically. So long as your service subclasses `Service`, your class will
be registered and automatically instantiated at the proper time:

    require 'kythera'

    class ChanServ < Service
        # ...
    end

Just by doing this your class is registered and will be instantiated. It is
your responsibility to provide certain methods in your class that the
application will utilize to introduce your clients and to send events your way:

    require 'kythera'

    class ChanServ < Service
        # You must provide a name. This is used for variable names and such.
        NAME = :chanserv

        # You must provide this method. Check whether your config section
        # exists at all, whether required settings are defined or are invalid,
        # etc. Return a boolean value.
        #
        def self.verify_configuration
            if $config.respond_to?(:chanserv) and $config.chanserv
                true
            else
                false
            end
        end

        # Your service is always initialized with the uplink
        def initialize(uplink)
            # Calling super sets `@uplink` to the argument provided.
            # The uplink contains the methods you'll use to communicate
            # with the IRC server.
            #
            super

            # You're free to register any events you'd like to handle, however
            # your class will have an interface for receiving PRIVMSG sent to it
            # so that you don't have to parse _all_ PRIVMSGs.
            #
            $eventq.handle(:some_event) { my_handler }

            # You should also introduce your clients to the uplink here. This
            # method returns your User object.
            #
            @user = @uplink.introduce_user(nick, user, host, real, modes)
        end

        public

        # If you want your @user to receive PRIVMSGs, you must provide access
        # to it with a reader.
        #
        attr_reader :user

        # You must provide a method that handles PRIVMSG sent your nickname
        def irc_privmsg(user, params)
            # `user`   is the User object that sent the message
            # `params` is an array containing the message sent to your client
            #          that has been tokenized by space
            #
            user   = User
            params = ['REGISTER', '#channel', 'etc']
        end
    end

So there's your service. That's all you have to do to get started, everything
else (handling the PRIVMSG) is up to you.

Configuration
-------------

Kythera uses a configuration DSL (domain-specific language) that actually
consists of real Ruby code and is executed by Ruby. The gist of it is like this:
you provide a module that has some methods that handle configuration directives,
you create an `OpenStruct` and call `extend` on it providing your module as an
argument. Then you execute the config DSL code in the context of that object.

While that might sound scary, Kythera actually does most of that for you. All
*you* need to do is provide the module with the methods. You put the module
under the class that subclasses `Service`, and name it `Configuration`.
If a configuration block exists in the configuration, it will be parsed and the
resulting `OpenStruct` will be passed to your initialize method.

So, picking up from the code provided above:

    class ChanServ < Service
        module Configuration
            # You must always have private so that the method names do not
            # interfere with your accessors. This is a side-effect of OpenStruct
            #
            private

            def some_setting(some_value)
                self.some_setting = some_value
            end
        end
    end

Then, in `bin/kythera` (the configuration)

    configure do
        service :chanserv do # Same as ChanServ::NAME
            some_setting :some_value
        end
    end

The resulting `OpenStruct` is placed in `$config.NAME`, in this case as
`$config.chanserv`.

Neat, huh?

For more detailed configurations, check out `extensions/example/extension.rb`,
and maybe `lib/kythera/service/shrike/configuration.rb'.`

* * *

Since this isn't anywhere near a finished product yet, this is likely to
massively change. At the very least I plan to add methods similar to the
`irc_privmsg` shown above (such as `irc_notice`).

Have fun.
