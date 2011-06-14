#
# kythera: services for TSora IRC networks
# benchmark/protocol/ts6/uid.rb: benchmark user introductions
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

str = ':0XX UID xiphias 1 1307151136 +aiow ~xiphias 64-121-34-121.c3-0.tlg-ubr1.atw-tlg.pa.cable.rcn.com 64.121.34.121 0XXAAAAAE :Michael Rodriguez'

Benchmark.ips do |x|
    x.report 'introducing users' do
        ul.recvq << str
        ul.send :parse
    end
end
