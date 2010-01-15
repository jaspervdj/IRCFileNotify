require "socket"
class IRCSocket < TCPSocket
  
  attr_accessor :channel, :nick, :verbose
  
  def initialize(server,port,channel,nick,verbose=false)
    super server,port
    @nick,@channel = nick,channel
    @verbose = verbose

    connect
  end
  
  # override puts and gets
  # if verbose they will print to the terminal
  def gets
    result = super
    $stdout.puts result if verbose
    result
  end
  
  def puts(*args)
    # if args is nil, were not supposed to crash
    # we make sure we don't print when it is
    # and let super take care of the error
    $stdout.puts args.first if verbose && ! args.first.nil?
    super
  end
  
  def connect
    self.puts "NICK #{nick}"
    self.puts "USER #{nick.downcase} ignored ignored :#{nick}"
    
    setup_reply_ping_thread
  end
  
  def say(text)
    self.puts "PRIVMSG #{channel} :#{text}"
  end
  
  def join
    self.puts "JOIN #{channel}"
  end
  
  def leave
    self.puts "PART #{channel}"
  end

  def close
    leave
    self.puts "QUIT"
    super
    @pingthread.join
  end

  private

  def setup_reply_ping_thread
    @pingthread = Thread.new(self) do |socket|
      until socket.eof?
        if socket.gets =~ /PING :(.*)$/
          socket.puts "PONG :#{$1}"
        end
      end
    end
  end
  
end