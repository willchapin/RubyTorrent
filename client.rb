class Client
  
  attr_accessor :torrent, :meta_info, :tracker, :handshake, :peers

  def initialize(path_to_file)
    @torrent = File.open(path_to_file)
    @request_queue = Queue.new
    @incoming_block_queue = Queue.new
    set_meta_info
    set_tracker
    set_handshake
    send_tracker_request
    set_peers
    start_peers
    join_threads
  end
  
  def set_meta_info
    @meta_info ||= BEncode::Parser.new(@torrent).parse!
  end
  
  def set_tracker
    @tracker ||= Tracker.new(@meta_info["announce"])
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
        Timeout::timeout(1) do 
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
    run(@peers.first)
  end
  
  def run(peer)
    Thread::abort_on_exception = true # remove later?
    
    Thread.new { Message.parse_stream(peer) }
    Thread.new { DownloadController.new(@meta_info, @request_queue, @incoming_block_queue).run! } 
    send_interested(peer) # change later
    Thread.new { process_queue(peer) }
    Thread.new { BlockRequestProcess.new(@request_queue).run! }
    push_to_request_queue(peer)
  end

  def push_to_request_queue(peer)
    piece = 0
    while piece < @meta_info["info"]["pieces"].length/20 
      offset = 0
      while offset <  @meta_info["info"]["piece length"]
        @request_queue.push({ connection: peer.connection, index: piece, offset: offset })
        offset += 2**14
      end
      piece += 1
    end
  end
  
  def send_interested(peer)
    length = "\0\0\0\1"
    id = "\2"
    peer.connection.write(length + id) 
  end
  
  def process_queue(peer)
    loop do
      message = peer.queue.pop
      process_message(message, peer)
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
      push_to_block_queue(message.payload)
    when "8"
      # TODO - Cancel - cancels block requests. Used if the same 
      # block is being downloaded from multiple peers, after block
      # is successfully downloaded, cancel transfers from other peers
    when "9"
      # Port - enable for DTH tracker
    end
  end
  
  def push_to_block_queue(payload)
    piece_index, byte_offset, block_data = split_piece_payload(payload)
    @incoming_block_queue.push({ piece_index: piece_index,
                                 byte_offset: byte_offset,
                                 block_data: block_data
                                 })
  end
  
  def split_piece_payload(payload)
    piece_index = payload.slice!(0..3).unpack("N")[0]
    byte_offset = payload.slice!(0..3).unpack("N")[0]
    block_data = payload
    [piece_index, byte_offset, block_data]
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
