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
        # do not yield if nothing is added
        yield diff if diff.size > 0
       
        old_files = files
      end
      
    end
  end
  
  private
  
  def get_files
    Dir.entries(directory)
  end
  
end

class IRCSocket < TCPSocket
  
  attr_accessor :channel, :nick, :verbose
  
  def initialize(server,port,channel,nick,verbose=false)
    super server,port
    @nick,@channel = nick,channel
    @verbose = verbose
  end
  
  # override puts and gets
  # if verbose they will print to the terminal
  def gets
    result = super
    puts result if verbose
    result
  end
  
  def puts(*args)
    # if args is nil, were not supposed to crash
    # we make sure we don't print when it is
    # and let super take care of the error
    puts args.first if verbose && ! args.first.nil?
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

class IRCFileBot
  
  def initialize(server,bot_name,channel,port,directory)
    @server,@bot_name,@channel,@port = server,bot_name,channel,port
    @watcher = Watcher.new(directory)
    @ircsocket = IRCSocket.new server,port,channel,bot_name
  end
  
  def run
    @watcher.watch do |files|
      files_added(files)
      sleep 1
    end
  end
  
  private
  
  def files_added(files)
    @ircsocket.join
    sleep 1
    @ircsocket.say "#{files.join ", "} were added"
    sleep 2
    @ircsocket.leave
  end

end

# Main
if __FILE__ == $0
  bot = IRCFileBot.new "wina.ugent.be", "ZeusFileBot", "#zeus", 6666, "/tmp"
  bot.run
end
