#
# kythera: services for IRC networks
# rakefile: automated task runner
#
# Copyright (c) 2011 Eric Will <rakaur@malkier.net>
# Rights to this code are documented in doc/license.txt
#

require 'rake'
require 'rake/testtask'

begin
    require 'yard'
rescue LoadError
    $yard = false
else
    $yard = true
end

$LOAD_PATH.unshift File.expand_path('.', File.dirname(__FILE__))
$LOAD_PATH.unshift File.expand_path('lib', File.dirname(__FILE__))

require 'kythera'

task :default => [:setup, :test]
task :setup   => 'migrate:auto'

task :clean => ['clean:rbc', 'clean:doc']

if $yard
    YARD::Rake::YardocTask.new do |t|
        t.files   = ['lib/**/*.rb', '-', 'doc/*']
        t.options = ['-oyardoc']
    end
end

namespace :clean do
    desc 'Remove all rbc files'
    task :rbc do
        files = Dir['*.rbc'] + Dir['**/*.rbc']
        rm_f files, :verbose => true unless files.empty?
        puts '<= clean:rbc executed'
    end

    desc 'Remove YARD files'
    task :doc do
        rm_rf %w(yardoc .yardoc), :verbose => true
        puts '<= clean:doc executed'
    end
end

# Testing
Rake::TestTask.new :test do |test|
    # XXX - no tests yet!
    test.pattern = 'test/**/*_test.rb'
end

# Database migrations
namespace :migrate do
    desc 'Perform automigration (reset your db data)'
    task :auto do
        Sequel.extension :migration
        Sequel::Migrator.run Sequel::Model.db, 'db/migrations', :target => 0
        Sequel::Migrator.run Sequel::Model.db, 'db/migrations'
        puts '<= migrate:auto executed'
    end

    desc 'Perform migration up/down to VERSION'
    task :to, [:version] do |t, args|
        version = (args[:version] || ENV['VERSION']).to_s.strip
        Sequel.extension :migration
        raise 'No VERSION was provided' if version.empty?
        Sequel::Migrator.apply(Sequel::Model.db, 'db/migrations', version.to_i)
        puts "<= migrate:to[#{version}] executed"
    end

    desc 'Perform migration up to latest migration available'
    task :up do
        Sequel.extension :migration
        Sequel::Migrator.run Sequel::Model.db, 'db/migrations'
        puts '<= migrate:up executed'
    end

    desc 'Perform migration down (erase all data)'
    task :down do
        Sequel.extension :migration
        Sequel::Migrator.run Sequel::Model.db, 'db/migrations', :target => 0
        puts '<= migrate:down executed'
    end
end
