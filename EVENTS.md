    kythera: services for TSora IRC networks

    Copyright (c) 2011 Eric Will <rakaur@malkier.net>
    Rights to this code are documented in LICENSE

List of Events
==============

  * socket_readable -- there is data on the socket ready to be read
  * socket_writable -- the socket is ready to be written to
  * connected -- we are connected to the uplink
  * disconnected -- we have been disconnected from the uplink
  * recvq_ready -- the recvq has data ready to be parsed
  
  * irc_* -- any command received by the uplink is posted as irc_<command>
      * e.g.: PRIVMSG = irc_privmsg
      * e.g.: PING = irc_ping
