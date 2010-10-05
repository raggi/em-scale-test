require 'eventmachine'

class Counter < EM::Connection
  def initialize
    super
    $inits += 1
  end

  def post_init
    @connected = true
  end

  def connection_completed
    $conns += 1
    @connected = true # we connected
  end

  def unbind
    $discs += 1
    raise EventMachine::ConnectionError, "failed to connect" unless @connected
  end
end

$inits, $conns, $discs = 0, 0, 0

localhost, port = '127.0.0.1', 9000+rand(256)

EM.kqueue
EM.epoll

EM.set_descriptor_table_size((ARGV.first || 1_000_000).to_i)

puts "PID: #{$$}"

class Spinner
  DEFAULT = %w(- \\ | /)
  def initialize(rot_arr = DEFAULT)
    @rot_arr = rot_arr
    @pos = -1
  end
  def next
    @rot_arr[@pos = (@pos + 1) % @rot_arr.size]
  end
end

begin
  EM.run do
    args = [localhost, port, Counter]
    EM.start_server(*args)
    conns = []
    
    spinner = Spinner.new

    EM.add_periodic_timer(0.1) do
      print "\r #{spinner.next} Inits: #{$inits}\tConns: #{$conns}\tDiscs: #{$discs}"
      $stdout.flush
    end
    
    # EM.add_periodic_timer(0.1) do # kqueue bug?
    EM.tick_loop do
      begin
        if $discs == 0
          conns << EM.connect(*args)
        else
          conns.shift.close_connection rescue EM.next_tick { EM.stop }
        end
      rescue EventMachine::ConnectionError
        puts
        puts "Error connecting: #{$!.message}"
        print "Num open files: "
        system "lsof -p #{$$} | wc -l"
        EM.next_tick { EM.stop }
        :stop
      end
    end
  end
ensure
  puts
  puts "Finishing: Inits: #{$inits}\tConns: #{$conns}\tDiscs: #{$discs}"
end