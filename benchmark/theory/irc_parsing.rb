#
# kythera: services for TSora IRC networks
# benchmark/theory/irc_parsing.rb: different methods of parsing IRC
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'rubygems'
require 'benchmark'
require 'benchmark/ips'

IRC_RE = /^(?:\:(\S+)\s)?(\S+)\s(?:([^:]+)\s)?(?:\:(.+))?$/
NO_COL = 1 .. -1

def parse_re(recvq)
    while line = recvq.shift
        line.chomp!

        next unless m = IRC_RE.match(line)

        origin = m[1]
        cmd    = m[2]

        if m[3]
            parv = m[3].split
        else
            parv = []
        end

        parv << m[4]
    end
end

def parse_line(recvq)
    while line = recvq.shift
        line.chomp!

        if line[0].chr == ':'
            # Remove the origin from the line, and eat the colon
            origin, line = line.split(' ', 2)
            origin = origin[NO_COL]
        else
            origin = nil
        end

        tokens, args = line.split(' :')
        parv = tokens.split(' ')
        cmd  = parv.delete_at(0)
        parv << args
    end
end

Benchmark.ips do |x|
    x.report 'regular expression' do
        parse_re [':rakaur!rakaur@malkier.net PRIVMSG #rintaun :omg hai']
    end

    x.report 'line parser' do
        parse_line [':rakaur!rakaur@malkier.net PRIVMSG #rintaun :omg hai']
    end
end
