class Client

  def initialize(path_to_file, download_folder)
    @peers = []
    torrent = File.open(path_to_file)
    @metainfo = MetaInfo.new(BEncode::Parser.new(torrent).parse!, download_folder)
    @id = rand_id # TODO: assign meaningful id
    @tracker = Tracker.new(@metainfo.announce)
    set_peers
  end

  def rand_id
    20.times.reduce("") { |a, _| a + rand(9).to_s }
  end

  def send_tracker_request
    @tracker.make_request(get_tracker_request_params)
  end

  def tracker_request_params
    { info_hash:    @metainfo.info_hash,
      peer_id:      @id,
      port:         '6881',
      uploaded:     '0',
      downloaded:   '0',
      left:         '10000',
      compact:      '1',
      no_peer_id:   '0',
      event:        'started' }
  end

  def set_peers
    peers = @tracker.make_request(tracker_request_params)["peers"].scan(/.{6}/)
    unpacked_peers = peers.map {|p| p.unpack('a4n') }
    unpacked_peers.each do |ip_string, port|
      set_peer(ip_string, port)
    end
  end

  def set_peer(ip_string, port)
    begin
      handshake = "\x13BitTorrent protocol\x00\x00\x00\x00\x00\x00\x00\x00#{@metainfo.info_hash}#{@id}"
      Timeout::timeout(1) { @peers << Peer.new(ip_string, port, handshake, @metainfo.info_hash) }
    rescue => exception
      puts exception
    end
  end

  def run!
    message_queue = Queue.new
    incoming_block_queue = Queue.new
    block_request_scheduler = BlockRequestScheduler.new(@peers, @metainfo)
    
    Thread::abort_on_exception = true

    @peers.each do |peer|
      Thread.new { Message.parse_stream(peer, message_queue) }
      Thread.new { keep_alive(peer) }
      Message.send_interested(peer)
    end

    Thread.new {
      pipe(block_request_scheduler.request_queue,
           BlockRequestProcess.new)
    }

    Thread.new {
      pipe(message_queue,
           IncomingMessageProcess.new(@metainfo.piece_length),
           incoming_block_queue)
    }

    Thread.new {
      multi_pipe(incoming_block_queue,
                 FileHandler.new(@metainfo),
                 block_request_scheduler)
    }
    
  end

  def join_threads
    Thread.list.each { |thread| thread.join unless current_thread?(thread) }
  end

  def keep_alive(peer)
    loop do
      begin
        peer.connection.write("\0\0\0\0")
      rescue
        puts "keep alive broken"
      end
      sleep(60)
    end
  end

  def current_thread?(thread)
    thread == Thread.current
  end

  def multi_pipe(input, *processors)
    while m = input.pop
      processors.each { |p| p.pipe(m) }
    end
  end

  def pipe(input, processor, output=nil)
    while m = input.pop
      if output
         processor.pipe(m, output)
      else
        processor.pipe(m)
      end
    end
  end
end