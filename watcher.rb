require 'find'
require 'socket'

# Get a list of files for a directory
class Watcher
    def initialize directory, server, port, nick, channel
        @directory = directory
        @server = server
        @port = port
        @nick = nick
        @channel = channel
    end

    def getAllFiles directory
        list = Find.find(directory).to_a
        list.find_all{|f| File.file? f}
        list.map{|f| File.basename f}
    end

    # Send a message over IRC.
    def sendMessages messages
        @socket = TCPSocket.open @server, @port
        toSocket "NICK #{@nick}"
        toSocket "USER #{@nick.downcase} ignored ignored :#{@nick}"
        replyPong
        toSocket "JOIN #{@channel}"
        sleep 5
        messages.each do |message|
            toSocket "PRIVMSG #{@channel} :#{message}"
            sleep 5
        end
        toSocket "PART #{@channel} :kthxbye"
        toSocket "QUIT"
        @socket.close
    end

    # Reply to the pong message
    def replyPong
        until @socket.eof? do
            reply = @socket.gets
            puts reply

            if reply.match(/^PING :(.*)$/)
                toSocket "PONG :#{$~[1]}"
                return
            end
        end
    end

    # Write something to the socket.
    def toSocket message
        puts message
        @socket.puts message
    end

    # Main function. Blocks forever.
    def run
        oldFiles = getAllFiles @directory
        loop do
            files = getAllFiles @directory
            newFiles = files - oldFiles
            unless newFiles.empty?
                sendMessages(newFiles.map{|f| "File added: #{f}"})
            end
            oldFiles = files
            sleep 2
        end
    end
end

# Arguments:
# - directory to watch
# - IRC server hostname
# - IRC server port
# - Name for the bot
# - Channel to join
watcher = Watcher.new "/srv/ftp", "wina.ugent.be", 6666, "ZeusFileBot", "#zeus"
watcher.run
