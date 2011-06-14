#
# kythera: services for TSora IRC networks
# benchmark/socket/read.rb: benchmarks the socket read method
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'rubygems'
require 'benchmark'
require 'benchmark/ips'

CR_OR_LF = /\r|\n/

$recvq = []

def read(data)
    #data.scan /([^\r\n]+)(\r\n|\r|\n)?/ do |line, endl|
    #    line += endl || ''

    data.scan /(.+\n?)/ do |line|
        line = line[0]

        if $recvq[-1] and $recvq[-1][-1] !~ CR_OR_LF
            $recvq[-1] += line
        else
            $recvq << line
        end
    end
end

data0 = ["PASS receive_linkage TS 6 :0XX\r\n",
        "CAPAB :QS EX CHW IE KLN GLN ",
        "KNOCK UNKLN CLUSTER ENCAP SAV",
        "E SAVETS_100\r\n",
        "SERVER test.malkier.net 1 :malkier irc\r",
        "SVINFO 6 3 0 :532523535\r\n",
        "THIS one has slash are\rTHIS one is after it\r\n"].join('')

data1 = "NOTICE AUTH :*** Processing connection to test.malkier.net\r\nNOTICE AUTH :*** Looking up your hostname...\r\nNOTICE AUTH :*** Checking Ident\r\nNOTICE AUTH :*** Found your hostname\r\nNOTICE AUTH :*** Che"

data2 = "cking blah blah\r\nNOTICE AUTH :*** Checking your mom\r\n"

data3 = "NOTICE AUTH :*** This one ends in slash are only\rNOTICE AUTH :*** omg\r\n"

data4 = "NOTICE AUTH :*** This one comes after slash are\r\n"

Benchmark.ips do |x|
    x.report 'read single line' do
        $recvq.clear
        read(data0)
    end

    x.report 'read multiple lines' do
        $recvq.clear
        read(data0)
        read(data1)
        read(data2)
        read(data3)
        read(data4)
    end
end
