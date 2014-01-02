# This program passive detects dropbox clients.
require 'socket'
require 'colorize'
require 'optparse'
require 'ostruct'

DROPBOX_PORT = 17500
DEBUG = true
socket = UDPSocket.new 


options = OpenStruct.new
options.list_interfaces = false
options.using_interface = nil

OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"
  
  opts.on("-i [interface]",Integer,"Sepcify an interface") do |i|
    options.using_interface = i
  end
  
  opts.on("-I","List all interfaces") do |l|
    options.list_interfaces = l
  end
end.parse! ARGV

if options.list_interfaces
  puts "List of interfaces:"
  puts "-------------------"
  Socket.ip_address_list.each_with_index{|addr,i|
     puts "- [#{i.to_s}] : #{addr.ip_address} "
   }
  puts "-------------------"
  exit
end


require 'set'
dropbox_clients = Set.new

def get_boardcast(ip)
   (ip.split '.').take(3).push('255').join('.')
end

#TODO use SO_REUSEADDR
#socket.setsockopt(Socket::SO_REUSEADDR)
socket.bind get_boardcast(Socket.ip_address_list[options.using_interface].ip_address),DROPBOX_PORT

loop do
	msg,info = socket.recvfrom(1024)
  puts info.inspect
  void, port, host, host2 = info
  
  if dropbox_clients.add? host
    puts "discoveried a dropbox host #{host}".green
  end
  
  if DEBUG
    puts "MSG: #{msg} from #{info[2]} (#{info[3]})/#{info[1]}\
     len #{msg.size}"
  end
end

#TODO make it works with C-C?
at_exit {
  require 'yaml'
  (File.open 'dropbox_hosts.yml','w').write dropbox_clients.to_yaml
}
