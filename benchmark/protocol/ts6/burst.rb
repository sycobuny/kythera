#
# kythera: services for IRC networks
# benchmark/protocol/ts6/burst.rb: benchmark initial burst
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

$LOAD_PATH.unshift File.expand_path('../../../lib', File.dirname(__FILE__))
require 'kythera/protocol/ts6'
require 'kythera'

require 'benchmark'
require 'benchmark/ips'
require 'logger'
require 'ostruct'

$logger = Logger.new($stdout)
$logger.level = Logger::FATAL

$eventq = EventQueue.new($logger)

config = OpenStruct.new
config.protocol = :ts6

ul = Uplink.new(config, $logger)

class << ul
    attr_reader :recvq
end

# XXX - randomize these at some point, otherwise it's not a real representation
sid   = ':0XX SID droneserv.dev 2 0X3 :kythera droneserv development'
uid1  = ':0XX UID xiphias 1 1307151136 +aiow ~xiphias 64-121-34-121.c3-0.tlg-ubr1.atw-tlg.pa.cable.rcn.com 64.121.34.121 0XXAAAAAA :Michael Rodriguez'
uid2  = ':0XX UID rakaur 1 1306941621 +aiow rakaur ericw.org 204.152.222.180 0XXAAAAAB :watching the weather change'
sjoin = ':0XX SJOIN 1306941651 #kythera +tn :@0XXAAAAAA @0XXAAAAAB'

Benchmark.ips do |x|
    x.report 'bursting' do
        ul.recvq << sid
        ul.recvq << uid1
        ul.recvq << uid2
        ul.recvq << sjoin
        ul.send :parse
    end
end
