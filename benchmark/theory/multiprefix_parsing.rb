#
# kythera: services for TSora IRC networks
# benchmark/theory/multiprefix_parsing.rb: different methods of parsing SJOIN
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'rubygems'
require 'benchmark'
require 'benchmark/ips'

# Parses a multiprefix user string by checking the first character
# for relevancy and then removing it.
#
def prefixes_slice(string)
    at = plus = false

    if string[0].chr == '@'
        at = true
        string = string[1..-1]
    end

    if string[0].chr == '+'
        plus = true
        string = string[1..-1]
    end

    [at, plus, string]
end

# Does the same as the above but in a slightly different manner
def prefixes_slice2(string)
    at = plus = false
    if string[0].chr == "@"
        at = true
        string.slice! 0
    end

    if string[0].chr == "+"
        plus = true
        string.slice! 0
    end

    [at, plus, string]
end

# Parses a multiprefix user string by checking the first character
# for relevancy and then subbing it away.
#
def prefixes_sub(string)
    at = plus = false

    if string[0].chr == '@'
        at = true
        string.sub!('@', '')
    end

    if string[0].chr == '+'
        plus = true
        string.sub!('+', '')
    end

    [at, plus, string]
end

# Parses a multiprefix user string with a regular expression
def prefixes_re(string)
    string.scan(/^(\@)?(\+)?([A-Z0-9]+)$/)[0]
end

Benchmark.ips do |x|
    x.report 'prefixes_slice' do
        prefixes_slice '@+0XXAAAAAB'
    end

    x.report 'prefixes_slice2' do
        prefixes_slice2 '@+0XXAAAAAB'
    end

    x.report 'prefixes_sub' do
        prefixes_sub '@+0XXAAAAAB'
    end

    x.report 'prefixes_re' do
        prefixes_re '@+0XXAAAAAB'
    end
end
