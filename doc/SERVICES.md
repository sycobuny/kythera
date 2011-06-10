    kythera: services for TSora IRC networks

    Copyright (c) 2011 Eric Will <rakaur@malkier.net>
    Rights to this code are documented in LICENSE

Services Interface
==================

All files matching `lib/kythera/service/*.rb` are loaded. The a good structure
would be:

  * `lib/kythera/service/chanserv.rb`
    * `lib/kythera/service/chanserv/file1.rb`
    * `lib/kythera/service/chanserv/file2.rb`

Since your code is executed upon load, most things are taken care of
automatically. So long as your service subclasses `Service`, your class will
be registered and automatically instantiated at the proper time:

    class ChanServ < Service
        # ...
    end

Just by doing this your class is registered and will be instantiated. It is
your responsibility to provide certain methods in your class that the
application will utilize to introduce your clients and to send events your way:

    class ChanServ < Service
        # Your service is always initialized with a logger
        def initialize(logger)
            # Calling `super` sets up the logger, and you don't have to
            # do anything else with it. The logger works as:
            #   log.info 'hello...'
            #   log.debug 'hello...'
            # etc.
            #
            super

            # You're free to register any events you'd like to handle, however
            # your class will have an interface for receiving PRIVMSG sent to it
            # so that you don't have to parse _all_ PRIVMSGs.
            $eventq.handle(:some_event) { my_handler }
        end

        # You must provide a method that returns your service's nickname
        attr_reader :nickname

        # You must provide a method that handles PRIVMSG sent your nickname
        def irc_privmsg(user, params)
            # `user`   is the User object that sent the message
            # `params` is an array containing the message sent to your client
            #          that has been tokenized by space

            user   = User
            params = ['REGISTER', '#channel', 'etc']
        end
    end

So there's your service. That's all you have to do to get started, everything
else (handling the PRIVMSG) is up to you.

Since this isn't anywhere near a finished product yet, this is likely to
massively change. At the very least I plan to add methods similar to the
`irc_privmsg` shown above (such as `irc_notice`).

Have fun.
