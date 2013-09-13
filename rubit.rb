require 'net/http'
require_relative 'ruby-bencode/lib/bencode.rb'
require 'digest/sha1'
require 'ipaddr'
require 'socket'
require 'timeout'

def rand_id
  result = []
  20.times { result << rand(9) }
  result = result.join("")
  result
end

def announce_list?(metainfo)
  metainfo.include?("announce-list")
end

def get_info_hash(metainfo)
  Digest::SHA1.new.digest(metainfo['info'].bencode)
end

def set_params(info_hash)
  params = {}
  params[:info_hash] = info_hash
  params[:peer_id] = rand_id
  params[:port] = '6881'
  params[:uploaded] = '0'
  params[:downloaded] = '0'
  params[:left] = '10000'
  params[:compact] = '0'
  params[:no_peer_id] = '0'
  params[:event] = 'started'
  params
end


torrent = File.open(ARGV.first)
metainfo = BEncode::Parser.new(torrent).parse!
puts metainfo["info"]["piece length"]
puts metainfo["info"]["pieces"].bytes.length

info_hash = get_info_hash(metainfo)
params = set_params(info_hash)


#if announce_list?(metainfo)
if false
  puts "list"
  metainfo["announce-list"].flatten!
  puts metainfo["announce-list"].inspect
  metainfo["announce-list"].each do |uri|
    
    begin
      puts uri.inspect
      next if uri =~ /^udp/
      request = URI(uri)
      request.query = URI.encode_www_form(params)
      puts request
      res = Net::HTTP.get_response(request)
      puts res
    rescue => error
      puts error
    end
  end
else
  request = URI(metainfo['announce'])
  request.query = URI.encode_www_form(params)
  res = Net::HTTP.get_response(request)
end

puts res
response_body = BEncode.load(res.body)
puts response_body

handshake = "\x13BitTorrent protocol\x00\x00\x00\x00\x00\x00\x00\x00#{info_hash}#{rand_id}"

peers = response_body["peers"].scan(/.{6}/)
puts peers.inspect

peers.map! do |peer|
  peer.unpack('a4n')
end

peers.each do |ip_string, port| 
  puts "ip_string: " + ip_string.to_s
  puts "port: " + port.to_s
  puts  IPAddr.new_ntoh(ip_string)
  begin
    Timeout::timeout(2) do 
      sock = TCPSocket.new(IPAddr.new_ntoh(ip_string).to_s, port)
      puts "ok"
      sock.write(handshake)
      response = {}
      puts "hello?"
      response["pstrlen"] = sock.getbyte
      response["pstr"] = sock.read(response["pstrlen"])
      response["reserved"] = sock.read(8)
      response["info_hash"] = sock.read(20)
      response["peer_id"] = sock.read(20)
      puts response.inspect
      bitfield_length = sock.read(4).unpack("N")[0]
      puts bitfield_length
      msg_id = sock.read(1)
      puts msg_id.bytes
      bitfield = sock.read(bitfield_length - 1).unpack("B8" * (bitfield_length - 1))
      puts bitfield
    end
  rescue => error
    puts error
  end
end