#
# kythera: services for TSora IRC networks
# rakefile: automated task runner
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in LICENSE
#

require 'rake'
require 'rake/testtask'
require 'yard'

$LOAD_PATH.unshift File.expand_path('lib', File.dirname(__FILE__))
require 'kythera'

task :default => :test

task :clean => ['clean:rbc', 'clean:doc']

YARD::Rake::YardocTask.new do |t|
    t.files   = ['lib/**/*.rb', '-', 'doc/*']
    t.options = ['-oyardoc']
end

namespace :clean do
    desc 'Remove all rbc files'
    task :rbc do
        files = Dir['*.rbc'] + Dir['**/*.rbc']
        rm_f files, :verbose => true unless files.empty?
    end

    desc 'Remove YARD files'
    task :doc do
        rm_rf %w(yardoc .yardoc), :verbose => true
    end
end

Rake::TestTask.new :test do |test|
    # XXX - no tests yet!
    test.pattern = 'test/**/*_test.rb'
end
