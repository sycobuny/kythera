#
# kythera: services for TSora IRC networks
# benchmark/protocol/ts6/burst.rb: benchmark initial burst
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

$LOAD_PATH.unshift File.expand_path('../../../lib', File.dirname(__FILE__))
require 'kythera/protocol/ts6'
require 'kythera'

require 'benchmark'
require 'benchmark/ips'
require 'logger'
require 'ostruct'

$eventq = EventQueue.new
$eventq.logger = Logger.new($stdout)
$eventq.log_level = :fatal

config = OpenStruct.new
config.protocol = :ts6

ul = Uplink.new(config)
ul.logger = Logger.new($stdout)
ul.log_level = :fatal

class << ul
    attr_reader :recvq
end

# XXX - randomize these at some point, otherwise it's not a real representation
sjoin = ':0XX SJOIN 1306941651 #kythera +tn :@0XXAAAAAM @0XXAAAAAG @0XXAAAAAF @0XXAAAAAD @0XXAAAAAB'
uid   = ':0XX UID xiphias 1 1307151136 +aiow ~xiphias 64-121-34-121.c3-0.tlg-ubr1.atw-tlg.pa.cable.rcn.com 64.121.34.121 0XXAAAAAE :Michael Rodriguez'

Benchmark.ips do |x|
    x.report 'bursting' do
        ul.recvq << uid
        ul.recvq << sjoin
        ul.send :parse
    end
end
