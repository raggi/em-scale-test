#!/usr/bin/env rake
MAXFILES = 100000

desc "set kernel maxfiles to #{MAXFILES}"
task :sysctl do
  sh "sudo sysctl -w kern.maxfiles=#{MAXFILES}"
  sh "sudo sysctl -w kern.maxfilesperproc=#{MAXFILES}"
end

desc "set ulimit to #{MAXFILES}"
task :ulimit do
  sh "ulimit -n #{MAXFILES}"
  sh "ulimit -n"
end

desc "start test"
task :run => %w(sysctl ulimit) do
  ruby '-rubygems', 'conns.rb', MAXFILES.to_s
end

desc "show time waits"
task :time_waits do
  grep = if RUBY_PLATFORM =~ /mswin|mingw/
    'find "TIME_WAIT"'
  else
    'grep TIME_WAIT'
  end
  system "netstat -an | #{grep}"
end

task :default => :run