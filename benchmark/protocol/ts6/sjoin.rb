#
# kythera: services for IRC networks
# benchmark/protocol/ts6/sjoin.rb: benchmark channel introductions
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

str = ':0XX SJOIN 1306941651 #kythera +tn :@0XXAAAAAM @0XXAAAAAG @0XXAAAAAF @0XXAAAAAD @0XXAAAAAB'

Benchmark.ips do |x|
    x.report 'introducing channels' do
        ul.recvq << str
        ul.send :parse
    end
end
