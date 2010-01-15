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
        
        # yield with all the added files (possibly empty)
        yield diff
       
        old_files = files
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

    connect
  end
  
  def run
    @watcher.watch do |files|
      mainloop(files)
      sleep 1
    end
  end
  
  private

  def pipe(content)
    puts content
    content
  end
  
  def connect
    @socket = TCPSocket.open(@server,@port)
    @socket.puts pipe "NICK #{@bot_name}"
    @socket.puts pipe "USER #{@bot_name.downcase} ignored ignored :#{@bot_name}"

    @listenthread = Thread.new(@socket) do |socket|
      until @socket.eof?
        if pipe(@socket.gets) =~ /PING :(.*)$/
          @socket.puts pipe "PONG :#{$1}"
        end
      end
    end
  end

  def mainloop(files)
    unless files.empty?
      @socket.puts pipe "JOIN #{@channel}"
      sleep 1
      @socket.puts pipe "PRIVMSG #{@channel} :#{files.join ", "} were added"
      sleep 1
      @socket.puts pipe "PART #{@channel}"
    end
  end

  def disconnect
    @socket.puts pipe "QUIT"
    @socket.close      # Probably exception due to socket.gets while closing 
    @listenthread.join
  end
end

# Main
if __FILE__ == $0
  bot = IRCFileBot.new "wina.ugent.be", "ZeusFileBot", "#zeus", 6666, "/tmp"
  bot.run
end
