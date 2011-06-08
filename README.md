    kythera: services for TSora IRC networks

    Copyright (c) 2011 Eric Will <rakaur@malkier.net>
    Rights to this code are documented in LICENSE

kythera -- services for TSora IRC networks
==========================================

This application is free but copyrighted software; see LICENSE.

To start the program, edit the configuration options in `bin/kythera` to
your satisfaction and run `./bin/kythera` at your terminal. Good luck!

For best results, run this application using [Rubinius][]. The initial footprint
is higher, but Rubinius shines with long-running processes. The longer it runs,
the faster and better it gets. Although the application should run swimmingly
using Ruby MRI 1.8.7 or Ruby MRI 1.9.2, give Rubinius a shot.

More information and code repositories can be found on [Github][].

[rubinius]: http://rubini.us/
[github]: http://github.com/rakaur/kythera/

--------------------------------------------------------------------------------

Kythera is a set of services for TSora-based IRC networks. Kythera is
extremely extensible and is not limited to providing a specific set of
services such as `NickServ`, `ChanServ` vs. Undernet-style `X`, etc. You can
configure the service to offer pretty much anything you want. If it's not there,
you can easily add support for it if you know Ruby.

Ruby also brings us to my next point. Many people have told me that IRC services
must be implemented in C in order to have any hope of keeping up with medium-
to large-sized networks. I disagree. I actually spend a good amount of time
benchmarking various Ruby implementations to make sure this wasn't a silly
project. Having [previously implemented][shrike] services in C myself, I think
I'm quite qualified to judge the situation. In most cases, Ruby was reasonably
competitive with, and sometimes faster than traditional services written in C.

Most people running ircd are sysadmins that may know some dynamic languages
like Python and Ruby, but probably not static languages like C. It's my hope
that Kythera can compete on performance, and obliterate the competition on
ease-of-use and ease-of-hacking.

[shrike]: http://github.com/rakaur/shrike/

## Runtime requirements ##

This application has the following requirements:

  * ruby -- mri ~> 1.8; mri ~> 1.9; rbx ~> 1.2
  * sqlite ~> 3.0

This application requires the following RubyGems:

  * rake ~> 0.8
  * sequel ~> 3.23
  * sqlite3 ~> 1.3

Rake is required for testing and other automated tasks. Sequel and sqlite3 are
required for database management. These gems are widely available and should
not be a problem.

If you want to run the unit tests you'll also need `riot ~> 0.12` and run
`rake test` from your terminal.

## Credits ##

This application is completely original. I'm sure to receive patches from other
contributors from time to time, and this will be indicated in SCM commits.
Presently, all major development is done by me:

  * rakaur, Eric Will <rakaur@malkier.net>

Thanks to testers, contributors, etc:

  * sycobuny, Stephen Belcher <sycobuny@malkier.net>
  * rintaun, Matt Lanigan <rintaun@projectxero.net>
  * xiphias, Michael Rodriguez <xiphias@khaydarin.net>

## Contact and Support ##

I'm not promising and fast and hard support, but I'll try to do my best. This
is a hobby and I've enjoyed it, but I have a real life with a real job and
a real family. I cannot devote major quantities of time to this.

With that said, my email addresses is all over the place. If you prefer
real-time you can try to catch me on IRC at `irc.malkier.net` in `#malkier`.
I'm also available on XMPP at `rakaur@malkier.net`.

If you have a bug feel free to drop by IRC or what have you, but I'm probably
just going to ask you to file an [issue][] on [Github][]. Please provide any
output you have, such as a backtrace. Please provide the steps anyone can take
to reproduce this problem. Feature requests are welcome and can be filed in
the same manner.

If you've read this far, congratulations. You are among the few elite people
that actually read documentation. Thank you.

[issue]: https://github.com/rakaur/kythera/issues
