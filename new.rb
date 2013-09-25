require 'net/http'
require 'digest/sha1'
require 'ipaddr'
require 'socket'
require 'timeout'
require_relative 'ruby-bencode/lib/bencode.rb'
require_relative 'client'
require_relative 'tracker'
require_relative 'peer'
require_relative 'bitfield'
require_relative 'message'


my_cli = Client.new(ARGV.first)
peer = my_cli.peers.last
puts peer
puts my_cli.meta_info["info"]

# the following is a simple download of one piece

interested = "\0\0\0\1\2"
length = "\0\0\0\1"
id = "\2"
peer.connection.write(length + id)

puts "unchoke"
len = peer.connection.read(4).unpack("N")
id = peer.connection.read(1).bytes
puts len 
puts id


offset = 0
data = ""
puts 'piece length'
puts my_cli.meta_info["info"]["piece length"]

while offset <=  my_cli.meta_info["info"]["piece length"] - 2**14 && true
  
  #puts data.bytes.length
  msg_length = "\0\0\0\x0d"
  id = "\6"
  piece_index = "\0\0\0\0"
  byte_offset = [offset].pack("N")
  request_length = "\0\0\x40\0"
  
  #puts byte_offset.inspect
  
  #byte_offset.force_encoding("utf-8")
  
  #puts piece_index.encoding
  #puts byte_offset.encoding
  #puts request_length.encoding
  
  request = msg_length + id + piece_index + byte_offset + request_length
  
  puts request.inspect
  puts offset/(2**14)  

  peer.connection.write(request)
  length = peer.connection.read(4)
  temp = length.unpack("N")[0]
  #break if length == nil || temp == 0
  #puts temp
  #puts 'p_length'
  puts "temp: " + temp.to_s
  p_length = temp - 9
  #puts p_length
  #puts 'id'
  id = peer.connection.read(1).bytes
  #puts 'index'
  p_index = peer.connection.read(4).unpack("N")
  #puts 'begin'
  block_offset = peer.connection.read(4).unpack("N")
  #puts 'block'
  data << peer.connection.read(p_length)
  #puts 'stop'
  puts offset
  puts block_offset
  offset += p_length
end


puts data.length
puts Digest::SHA1.new.digest(data).bytes
puts '-----------------------'
puts my_cli.meta_info["info"]["pieces"].bytes[0...20]
puts Digest::SHA1.new.digest(data) == my_cli.meta_info["info"]["pieces"][0...20]
