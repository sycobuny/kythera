    kythera: services for TSora IRC networks

    Copyright (c) 2011 Eric Will <rakaur@malkier.net>
    Rights to this code are documented in doc/license.txt

Extensions Interface
====================

All files matching `lib/kythera/service/*.rb` and `ext/*.rb` are autoloaded.
A good structure would be:

  * `lib/kythera/service/chanserv.rb`
    * `lib/kythera/service/chanserv/file1.rb`
    * `lib/kythera/service/chanserv/file2.rb`
  * `ext/my_extension.rb`
    * `ext/my_extension/file1.rb`
    * `ext/my_extension/file2.rb`

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
        # You must provide this method. Typically you determine whether your
        # service is enabled or not by checking to see if your configuration
        # settings exist. If not, they were commented out or unloaded.
        #
        def self.enabled?
            if $config.respond_to?(:chanserv) and $config.chanserv
                true
            else
                false
            end
        end

        # Your service is always initialized with the uplink and a logger
        def initialize(uplink, logger)
            # Calling `super` sets up the logger, and you don't have to
            # do anything else with it. The logger works as:
            #   log.info 'hello...'
            #   log.debug 'hello...'
            #
            # Calling this also sets `@uplink` to the argument provided.
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
            @user = @uplink.introduce_user(nick, username, hostname, realname)
        end

        public

        # You must provide a few methods so that Kythera can get at some of
        # your service's information. We need access to your User and your
        # configuration object.
        #
        attr_reader :config, :user

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

If you need help writing a configuration portion, for now take a look at
`lib/kythera/service/shrike/configuration.rb`. I'll try to write it up later on.

Since this isn't anywhere near a finished product yet, this is likely to
massively change. At the very least I plan to add methods similar to the
`irc_privmsg` shown above (such as `irc_notice`).

Have fun.
