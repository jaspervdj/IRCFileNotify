require "socket"

class Watcher
  
  attr_accessor :directory
  
  def initialize(directory=Dir.pwd)
    @directory = directory
  end
  
  def watch
    if ! block_given?
      raise
    else
      old_files = get_files
      loop do
        files = get_files
        diff = files - old_files
        
        # yield with all the added files
        yield diff
       
        old_files = files
        sleep 1
      end
      
    end
  end
  
  private
  
  def get_files
    Dir.entries(directory)
  end
  
end

class IRCFileBot
  
  def initialize(server,bot_name,channel,port,directory)
    @server,@bot_name,@channel,@port = server,bot_name,channel,port
    @watcher = Watcher.new(directory)
  end
  
  def run
    @watcher.watch do |files|
      connection do |conn|
        conn.puts "PRIVMSG #{@channel} :#{files.join ", "} were added"
      end
    end
  end
  
  private
  
  def connection
    socket = TCPSocket.open(@server,@port)
    socket.puts "NICK #{@bot_name}"
    socket.puts "USER #{@nick.down_case} ignored ignored :#{@bot_name}"
    
    # apparently we need to respond to a PING
    until socket.eof?
      if socket.gets =~ /PING :(.*)$/
        socket.puts "PONG :#{$1}"
      end
    end
    
    socket.puts "JOIN #{@channel}"
    
    sleep 5
    yield socket
    
    socket.puts "PART #{@channel} :that's all folks"
    socket.puts "QUIT"
    
  end
  
  
end


