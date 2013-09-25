class Client
  
  attr_accessor :torrent, :meta_info, :tracker, :bitfield, :handshake, :peers

  def initialize(path_to_file)
    @torrent = File.open(path_to_file)
    set_meta_info
    set_tracker
    set_bitfield
    set_handshake
    make_tracker_request
    set_peers
    # run
  end
  
  def set_meta_info
    @meta_info ||= BEncode::Parser.new(@torrent).parse!
  end
  
  def set_tracker
    @tracker ||= Tracker.new(@meta_info["announce"])
  end
  
  def set_bitfield
    @bitfield = "0" * (@meta_info["info"]["pieces"].length/20)
  end
  
  def set_handshake
    @handshake = "\x13BitTorrent protocol\x00\x00\x00\x00\x00\x00\x00\x00#{get_info_hash}#{get_id}"
  end
  
  def make_tracker_request
    @tracker.make_request(get_tracker_request_params)
  end
  
  def get_tracker_request_params
    params = {
      info_hash:    get_info_hash,          
      peer_id:      rand_id,
      port:         '6881',
      uploaded:     '0',
      downloaded:   '0',
      left:         '10000',
      compact:      '0',
      no_peer_id:   '0',
      event:        'started' }
  end
  
  def set_peers
    @peers ||= []
    peers = @tracker.response["peers"].scan(/.{6}/)
    
    peers.map! do |peer|
      peer.unpack('a4n')
    end
    
    peers.each do |ip_string, port| 
      begin
        Timeout::timeout(2) do 
          @peers << Peer.new(ip_string, port, @handshake)
        end
      rescue => exception
       # puts exception.backtrace
        puts exception
      end
    end
  end
  
  def get_id
    @id ||= rand_id
  end

  def rand_id
    result = []
    20.times { result << rand(9) }
    result = result.join("")
    result
  end
  
  def get_info_hash
    @info_hash ||= Digest::SHA1.new.digest(@meta_info['info'].bencode)
  end
  
  def run
    peer = peers.last
    Message.send_interested(peer)
    id = Message.parse_response(peer)  
  end
  
  def request_unchoke(peer)
    
  end
   
end