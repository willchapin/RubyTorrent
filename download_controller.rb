class DownloadController
  
  require 'matrix'
  include Helpers
  
  BLOCK_SIZE = 2**14
  
  def initialize(metainfo, block_request_queue, incoming_block_queue, peers)
    @metainfo = metainfo
    @block_request_queue = block_request_queue
    @incoming_block_queue = incoming_block_queue
    @peers = peers
    @byte_array = ByteArray.new(@metainfo)
    @file_handler = FileHandler.new(@metainfo, @byte_array)
    @remaining_requests = Queue.new
  end
  
  def run!
    Thread::abort_on_exception = true
    assemble_requests
    initiate_requests
    incoming_block_process
  end
  
  def assemble_requests
    0.upto(num_pieces - 2).each do |piece_num|
      0.upto(num_blocks_in_piece - 1).each do |block_num|
        @remaining_requests.push({ index: piece_num, offset: BLOCK_SIZE * block_num, size: BLOCK_SIZE })
      end
    end    

    # last piece
    0.upto(num_full_blocks_in_last_piece - 1) do |block_num|
      @remaining_requests.push({ index: num_pieces - 1, offset: BLOCK_SIZE * block_num, size: BLOCK_SIZE })
    end

    # last block
    @remaining_requests.push({ index: num_pieces - 1, offset: BLOCK_SIZE * num_full_blocks_in_last_piece, size: last_block_size })
  end

  def initiate_requests
    @peers.each { |peer| 20.times { make_request(peer) }}
  end

  def make_request(peer)
    unless @remaining_requests.empty? 
      request = @remaining_requests.shift
    else
      slowest_peer = @peers.sort_by{|peer| peer.pending_requests.length}.first
      request = slowest_peer.pending_requests.last
    end
    peer.pending_requests << request
    if request
      @block_request_queue.push({ connection: peer.connection,
                                  index: request[:index],
                                  offset: request[:offset],
                                  size: request[:size]})
    end
  end
  
  def incoming_block_process
    loop do
      block = @incoming_block_queue.pop
      next_requests(block.peer)        
      puts "block from #{block.peer}"
      puts block.peer.pending_requests.length
      remove_from_pending(block)
      @file_handler.process_block(block)
    end
  end

  def next_requests(peer)
    (20 - peer.pending_requests.length).times { make_request(peer) }
  end
 
  def remove_from_pending(block)
    peer = block.peer
    peer.pending_requests.delete_if do |request|
      if request
        request[:index] == block.piece_index and
        request[:offset] == block.offset
      end
    end
  end
end

