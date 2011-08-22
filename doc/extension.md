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

    class MyExtension > Extension
        NAME = 'my_extension'       # The human-readable name for your extension
        
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
