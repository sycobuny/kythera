    kythera: services for IRC networks

    Copyright (c) 2011 Eric Will <rakaur@malkier.net>
    Rights to this code are documented in doc/license.txt

Extensions Interface
====================

All files matching `extensions/**/extension.rb` are autoloaded.
A good structure would be:

  * `extensions/my_extension/`
    * `extensions/my_extension/extension.rb`
    * `extensions/my_extension/my_extension.rb`
    * `extensions/my_extension/other_files.rb`

You must provide some information to Kythera that defines your extension in
terms of what version of the software it was designed to work with and which,
if any, external dependencies your extension requires. This is done by
subclassing the `Extension` class:

    require 'kythera'

    class MyExtension < Extension
        NAME = :my_extension        # The human-readable name for your extension
        
        KYTHERA_VERSION = '~> 1.0'  # The RubyGems-style dependency string
        
        DEPENDENCIES = { 'some_gem'    => '>= 3.13',  # A Hash describing your
                         'another_gem' => '~> 3.37' } # dependencies, gem-style
                         
        # If Kythera determines from the above information that your extension
        # will load and run, this method is called. It is up to you to require
        # the rest of your files and actually make your code do things. Kythera
        # is hands-off from here on out.
        #
        def self.initialize
            require 'extensions/my_extension/my_extension.rb'
        end
    end
    
That's pretty much it. When your real code is loaded by the `self.initialize`
method, it can set timers, set events, define a Service class, or do pretty
much a anything it wants to do.

Configuration
-------------

Kythera uses a configuration DSL (domain-specific language) that actually
consists of real Ruby code and is executed by Ruby. The gist of it is like this:
you provide a module that has some methods that handle configuration directives,
you create an `OpenStruct` and call `extend` on it providing your module as an
argument. Then you execute the config DSL code in the context of that object.

While that might sound scary, Kythera actually does most of that for you. All
*you* need to do is provide the module with the methods. You put the module
under the class that subclasses `Extension`, and name it `Configuration`.
If a configuration block exists in the configuration, it will be parsed and the
resulting `OpenStruct` will be passed to your initialize method.

So, picking up from the code provided above:

    class MyExtension < Extension
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
        extension :my_extension do # Same as MyExtension::NAME
            some_setting :some_value
        end
    end

When `MyExtension.initialize` is called, it will be passed the `OpenStruct`:

    class MyExtension < Extension
        def self.initialize(config)
            @config = config
            require 'extensions/my_extension/my_extension.rb'
        end
    end

You could then access the value of `some_setting` like: `@config.some_setting`.

Neat, huh?

For more detailed configurations, check out `extensions/example/extension.rb`,
and maybe `lib/kythera/service/shrike/configuration.rb'.`

A Few Notes
-----------

You should keep in mind that the `$eventq` is cleared every time we get
disconnected from the uplink, and all `Service` subclasses are killed and
instantiated again upon reconnection. All `Timer`s are also stopped and deleted,
unless the timer has a `persistent` attribute. You can set timers that don't
get cleared by using `Timer.persistent_every` and `Timer.persistent_after`.

If you need help writing a configuration portion, for now take a look at
`lib/kythera/service/shrike/configuration.rb`. I'll try to write it up later on.

Since this isn't anywhere near a finished product yet, this is likely to
massively change. I really will do my best to keep this updated.

Have fun.
