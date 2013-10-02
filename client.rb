class Client
  
  BLOCK_SIZE = 2**14

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
      compact:      '1',
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
    result.join("")
  end
  
  def get_info_hash
    @info_hash ||= Digest::SHA1.new.digest(@meta_info['info'].bencode)
  end
  
  def start_peers
    # run each peer later
    run(@peers.last)
  end
  
  def run(peer)
    Thread::abort_on_exception = true # remove later?
    Thread.new { DownloadController.new(@meta_info, @request_queue, @incoming_block_queue).run! } 
    Thread.new { BlockRequestProcess.new(@request_queue).run! }
    Thread.new { Message.parse_stream(peer) }
    Thread.new { process_queue(peer) }
    Thread.new { keep_alive(peer) }
    send_interested(peer) # change later

    push_to_request_queue(peer)
  end
  
  
  ## refactor this!!!
  def push_to_request_queue(peer)
            
    piece = 0
    total_blocks = 0
    
    while piece < get_num_pieces
      offset = 0
      while offset < get_piece_size
        if is_last_block?(total_blocks)
          @request_queue.push({ connection: peer.connection, index: piece, offset: offset, size: get_last_block_size })
        else
          @request_queue.push({ connection: peer.connection, index: piece, offset: offset, size: BLOCK_SIZE })
        end
        total_blocks += 1
        offset += 2**14
      end
      piece += 1
    end
  end
  
  def get_piece_size
    @meta_info["info"]["piece length"]
  end
  
  def get_num_pieces
    @meta_info["info"]["pieces"].length/20
  end
  
  def get_last_block_size
    get_file_size.remainder(BLOCK_SIZE)
  end
  def is_last_block?(total_blocks)
    total_blocks == get_num_full_blocks
  end
  
  def get_num_full_blocks
    get_file_size/BLOCK_SIZE
  end
  
  def get_file_size
    @meta_info["info"]["length"]
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
      puts "keep alive!"
    when "0"
      peer.state[:is_choking] = true
      puts "is chokeing"
    when "1"
      peer.state[:is_choking] = false
      puts "not choking"
    when "2"
      peer.state[:is_interested] = false
      puts "is not interested"
    when "3"
      peer.state[:is_interested] = true
      puts "is interested"
    when "4"
      # TODO: have message
      puts "have"
    when "5"
      # bitfield - currently handled in peer initialization
      puts "bitfield"
    when "6"
      # TODO: request
      puts "request"
    when "7"
      puts "block: " + message.print
      push_to_block_queue(message.payload)
    when "8"
      puts "cancel"
      # TODO - Cancel - cancels block requests. Used if the same 
      # block is being downloaded from multiple peers, after block
      # is successfully downloaded, cancel transfers from other peers
    when "9"
      puts "port"
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
  
  def keep_alive(peer)
    loop do
      peer.connection.write("\0\0\0\0")
      sleep(60)
    end
  end
  
  def current_thread?(thread)
    thread == Thread.current
  end
end
