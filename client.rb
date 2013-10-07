class Client
    
  def initialize(path_to_file)
    @torrent = File.open(path_to_file)
    set_instance_variables
    send_tracker_request
    set_peers
    run
    join_threads
  end
  
  def set_instance_variables
    @message_queue = Queue.new
    @block_request_queue = Queue.new
    @incoming_block_queue = Queue.new
    @meta_info = BEncode::Parser.new(@torrent).parse!
    puts @meta_info["info"]
    @info_hash = Digest::SHA1.new.digest(@meta_info['info'].bencode)
    @id = rand_id # make better later
    @tracker = Tracker.new(@meta_info["announce"])
    @handshake = "\x13BitTorrent protocol\x00\x00\x00\x00\x00\x00\x00\x00#{@info_hash}#{@id}"
  end
  
  def send_tracker_request
    @tracker.make_request(get_tracker_request_params)
  end
  
  def get_tracker_request_params
    { info_hash:    @info_hash,          
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

  def rand_id
    result = ''
    20.times { result << rand(9).to_s }
    result
  end

  def run
    peer = @peers.last
    Thread::abort_on_exception = true # remove later?
    Thread.new { DownloadController.new(@meta_info, @block_request_queue, @incoming_block_queue, @peers).run! } 
    Thread.new { Message.parse_stream(peer, @message_queue) }
    Thread.new { IncomingMessageProcess.new(@message_queue, @incoming_block_queue).run! } 
    Thread.new { BlockRequestProcess.new(@block_request_queue).run! }
    Thread.new { keep_alive(peer) }
    Message.send_interested(peer) # change later
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
