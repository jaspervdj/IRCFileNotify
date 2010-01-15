require "ircsocket"

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
    @ircsocket = IRCSocket.new server,port,channel,bot_name,true
  end
  
  def run
    @watcher.watch do |files|
      files_added(files)
      sleep 1
    end
  end
  
  def interrupt
    @ircsocket.close
  end
  
  private
  
  def files_added(files)
    @ircsocket.join
    sleep 1
    @ircsocket.say "#{files.join ", "} #{files.size == 1 ? "was" : "were"} added"
    sleep 1
    @ircsocket.leave
  end

end

# Main
if __FILE__ == $0
  bot = IRCFileBot.new "wina.ugent.be", "NuddedTestBot", "#zeus", 6666, Dir.pwd
  trap("INT") {bot.interrupt}
  bot.run
end
