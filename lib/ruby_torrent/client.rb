class Client

  # set queues and set processes in different methods
  
  def initialize(path_to_file, download_folder)
    @metainfo = parse_metainfo(File.open(path_to_file), download_folder)
    @tracker = Tracker.new(@metainfo.announce)
    @id = rand_id # TODO: assign meaningful id
    @peers = []
    set_peers
    @scheduler = BlockRequestScheduler.new(@peers, @metainfo)
    @message_queue = Queue.new
    @incoming_block_queue = Queue.new    
  end

  def parse_metainfo(torrent_file, download_folder)
    metainfo = BEncode::Parser.new(torrent_file).parse!
    MetaInfo.new(metainfo, download_folder)
  end
  
  def rand_id
    20.times.reduce("") { |a, _| a + rand(9).to_s }
  end

  def set_peers
    peers = @tracker.make_request(tracker_request_params)["peers"].scan(/.{6}/)
    get_unpacked_peers(peers).each do |ip_string, port|
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

  def get_unpacked_peers(peers)
    peers.map {|p| p.unpack('a4n') }
  end

  def run!
    Thread::abort_on_exception = true
    @peers.each { |peer| peer.start!(@message_queue) }    
    make_threads([scheduler, incoming_message, file_handler])
  end
  
  def scheduler
    lambda { pipe(@scheduler.request_queue, BlockRequestProcess.new) }
  end

  def incoming_message
    lambda do
      pipe(@message_queue,
           IncomingMessageProcess.new(@metainfo.piece_length),
           @incoming_block_queue)
    end
  end

  def file_handler
    lambda do
      multi_pipe(@incoming_block_queue,
                 FileHandler.new(@metainfo),
                 @scheduler)
    end
  end
  
  def make_threads(processes)
    processes.each do |process|
      Thread.new { process.call }
    end
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
