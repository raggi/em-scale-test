#!/usr/bin/env rake
MAXFILES = 65535

desc "setup limits.conf (requires sudo)"
task :limits do
  desired =  <<-PLAIN
  *       soft    nofile  1024
  *       hard    nofile  65535
  PLAIN
  path = '/etc/security/limits.conf'
  limits = File.read(path)
  soft = limits[/soft\s+nofile\s+(\d+)/m, 1]
  hard = limits[/hard\s+nofile\s+(\d+)/m, 1]
  unless soft || hard
    unless Process.euid == 0
      cmd = ['sudo', __FILE__, 'limits']
      puts cmd.join(' ')
      exec *cmd
    end

    open('/etc/secuirty/limits.conf', 'a') do |f|
      f.puts
      f.puts desired
    end
  else
    unless hard && hard.to_i >= MAXFILES
      puts "Please setup the following entries in #{path}:\n#{desired}"
    end
  end
end

desc "set kernel maxfiles to #{MAXFILES}"
task :sysctl do
  sh "sudo sysctl -w kern.maxfiles=#{MAXFILES}"
  sh "sudo sysctl -w kern.maxfilesperproc=#{MAXFILES}"
end

desc "set ulimit to #{MAXFILES}"
task :ulimit do
  case RUBY_PLATFORM
  when /linux/
    sh "ulimit -n unlimited"
  else
    # Assume broken ulimit implementation.
    sh "ulimit -n #{MAXFILES}"
  end
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