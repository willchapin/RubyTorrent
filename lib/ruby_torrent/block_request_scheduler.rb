class BlockRequestScheduler

  BLOCK_SIZE = 2**14
  NUM_PENDING = 10
  
  attr_accessor :request_queue
  
  def initialize(peers, metainfo)
    @peers = peers
    @metainfo = metainfo
    @all_block_requests = Queue.new
    @request_queue = Queue.new
    store_block_requests
    init_requests
  end
  
  def store_block_requests
    store_all_but_last_piece
    store_last_piece
    store_last_block
  end
  
  def init_requests
    @peers.each do |peer|
      NUM_PENDING.times { assign_request(peer, @all_block_requests.pop) }
    end    
  end
  
  def store_all_but_last_piece
    0.upto(num_pieces - 2).each do |piece_num|
      0.upto(num_blocks_in_piece - 1).each do |block_num|
        store_request(piece_num, block_offset(block_num), BLOCK_SIZE)
      end
    end
  end

  def store_last_piece
    0.upto(num_full_blocks_in_last_piece - 1) do |block_num|
      store_request(num_pieces - 1, block_offset(block_num), BLOCK_SIZE)
    end
  end

  def store_last_block
    store_request(num_pieces - 1, last_block_offset, last_block_size)    
  end

  def store_request(index, offset, size)
    @all_block_requests.push(create_block(index, offset, size))
  end

  def assign_request(peer, block)
    peer.pending_requests << block
    @request_queue.push(assign_peer(peer, block))
  end
  
  def pipe(incoming_block)
    request = get_next_request(incoming_block)
    enqueue_request(incoming_block, request) if request
  end

  def get_next_request(block)
    if @all_block_requests.empty?
      oldest_pending_request(block)
    else
      @all_block_requests.pop
    end
  end
  
  def enqueue_request(incoming_block, request)
    incoming_block.peer.pending_requests << request
    @request_queue.push(assign_peer(incoming_block.peer, request))    
  end
  
  def oldest_pending_request(block)
    slowest_peer = @peers.sort_by{|peer| peer.pending_requests.length}.first
    slowest_peer.pending_requests.last
  end
  
  def assign_peer(peer, block)
    { connection: peer.connection,
      index:      block[:index],
      offset:     block[:offset],
      size:       block[:size] }
  end
  
  def create_block(index, offset, size)
    { index: index, offset: offset, size: size }
  end

  def num_pieces
    (@metainfo.total_size.to_f/@metainfo.piece_length).ceil
  end

  def last_block_size
    @metainfo.total_size.remainder(BLOCK_SIZE)
  end

  def num_full_blocks
    @metainfo.total_size/BLOCK_SIZE
  end

  def last_piece_size
    file_size - (@metainfo.piece_length * (@metainfo.number_of_pieces - 1))
  end

  def num_blocks_in_piece
    (@metainfo.piece_length.to_f/BLOCK_SIZE).ceil
  end

  def num_full_blocks_in_last_piece
    num_full_blocks.remainder(num_blocks_in_piece)
  end

  def total_num_blocks_in_last_piece
    num_full_blocks_in_last_piece + 1
  end

  def last_block_offset
    BLOCK_SIZE * num_full_blocks_in_last_piece
  end

  def last_block_offset
    BLOCK_SIZE * num_full_blocks_in_last_piece
  end

  def block_offset(block_num)
    BLOCK_SIZE * block_num
  end
  
end
