#!/usr/bin/env rake

MAXFILES = ENV['MAXFILES'] || 65535

def as_root(*args)
  unless Process.euid == 0
    cmd = ['sudo', __FILE__, *args]
    puts cmd.join(' ')
    exec *cmd
  end
end

desc "setup limits.conf"
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
    as_root('file_max')
    open('/etc/secuirty/limits.conf', 'a') do |f|
      f.puts
      f.puts desired
    end
  else
    unless hard && hard.to_i >= MAXFILES
      puts "Please setup the following entries in #{path}:\n#{desired}"
    else
      puts "hard: #{hard}"
      puts "soft: #{soft}"
    end
  end
end

desc "setup file-max"
task :file_max do
  path = '/proc/sys/fs/file-max'
  limit = File.read(path).to_i
  unless limit >= MAXFILES
    as_root('file_max')
    open('/proc/sys/fs/file-max', 'w') { |f| f.write(MAXFILES.to_s) }
  end
end

desc "set kernel maxfiles to #{MAXFILES}"
task :sysctl do
  maxfiles     = `sysctl kern.maxfiles`[/:\s*(\d+)/, 1].to_i
  maxfilesproc = `sysctl kern.maxfilesperproc`[/:\s*(\d+)/, 1].to_i
  unless maxfiles >= MAXFILES && maxfilesproc >= MAXFILES
    as_root('file_max')
    sh "sysctl -w kern.maxfiles=#{MAXFILES}"
    sh "sysctl -w kern.maxfilesperproc=#{MAXFILES}"
  end
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
task :run do
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