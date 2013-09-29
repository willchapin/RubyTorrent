class Client
  
  attr_accessor :torrent, :meta_info, :tracker, :bitfield, :handshake, :peers, :test_block

  def initialize(path_to_file)
    @torrent = File.open(path_to_file)
    set_meta_info
    set_tracker
    set_bitfield
    set_handshake
    send_tracker_request
    set_peers
    #start_peers
    #join_threads
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
  
  def send_tracker_request
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
  
  def start_peers
    # give each peer a thread later
    run(@peers.last)
  end
  
  def run(peer)
    # three threads per peer, too many?
    Thread.new { Message.parse_stream(peer) }
    #send interested message, fix later--------
    length = "\0\0\0\1"
    id = "\2"
    peer.connection.write(length + id) 
    ###------------------------------   
    Thread.new { process_queue(peer) }
    Thread.new { request_blocks(peer) }
    
  end
  
  def request_blocks(peer)
    
    offset = 0
    data = ""

    while offset <  @meta_info["info"]["piece length"] && true
      msg_length = "\0\0\0\x0d"
      id = "\6"
      piece_index = "\0\0\0\0"
      byte_offset = [offset].pack("N")
      request_length = "\0\0\x40\0"
      request = msg_length + id + piece_index + byte_offset + request_length
      peer.connection.write(request)
      puts offset
      puts block_offset
      offset += p_length
    end
  end
  
  def process_queue(peer)
    until download_complete?
      message = peer.queue.pop
      process_message(message, peer) if message
    end
  end
  
  def process_message(message, peer)
    case message.id
    when "-1"
      # TODO: keep-alive
    when "0"
      peer.state[:is_choking] = true
    when "1"
      peer.state[:is_choking] = false
    when "2"
      peer.state[:is_interested] = false
    when "3"
      peer.state[:is_interested] = true
    when "4"
      # TODO: have message
    when "5"
      # bitfield - currently handled in peer initialization
    when "6"
      # TODO: request
    when "7"
      process_piece(message.payload)
    when "8"
      # TODO - Cancel - cancels block requests. Used if the same 
      # block is being downloaded from multiple peers, after block
      # is successfully downloaded, cancel transfers from other peers
    when "9"
      # Port - enable for DTH tracker
    end
  end
  
  def process_piece(payload)
    piece_index, byte_offset, block_data = split_piece_payload(payload)
  end
  
  def split_piece_payload(payload)
    piece_index = payload.slice!(0..3).unpack("N")
    byte_offset = payload.slice!(0..3).unpack("N")
    block_data = payload
    [piece_index, byte_offset, block_data]
    @test_block << block_data
  end
  
  def download_complete?
    !@bitfield.include?("0")
  end
  
  def join_threads
    Thread.list.each { |thread| thread.join unless current_thread?(thread) }
  end
  
  def current_thread?(thread)
    thread == Thread.current
  end
end
