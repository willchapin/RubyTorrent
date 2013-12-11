class BlockRequestScheduler

  BLOCK_SIZE = 2**14
  NUM_PENDING = 10
  
  attr_accessor :request_queue
  
  def initialize(peers, metainfo)
    @peers = peers
    @all_block_requests = Queue.new
    @request_queue = Queue.new
    init_requests
  end
  
  def create_blocks(metainfo)

    # all but last piece
    0.upto(num_pieces(metainfo) - 2).each do |piece_num|
      0.upto(num_blocks_in_piece(metainfo) - 1).each do |block_num|
        @all_block_requests.push(create_block(piece_num,
                                   BLOCK_SIZE * block_num,
                                   BLOCK_SIZE))
      end
    end

    # last piece

    0.upto(num_full_blocks_in_last_piece(metainfo) - 1) do |block_num|
      @all_block_requests.push(create_block(num_pieces(metainfo) - 1,
                                 BLOCK_SIZE * block_num,
                                 BLOCK_SIZE))
    end

    
    push_request(num_pieces(metainfo) - 1,
                 last_block_offset(metainfo),
                 last_block_size(metainfo))
       
    # last block
  end

  def push_request(index, offset, size)
    @all_block_requests.push(create_block(index, offset, size))
  end

  
  def get_all_but_last_piece(metainfo)
    0.upto(num_pieces(metainfo) - 2).each do |piece_num|
      0.upto(num_blocks_in_piece(metainfo) - 1).each do |block_num|
        @all_block_requests.push(create_block(piece_num,
                                   BLOCK_SIZE * block_num,
                                   BLOCK_SIZE))
      end
    end
  end
  
  def pipe(incoming_block)
    
    if @all_block_requests.empty?
      slowest_peer = @peers.sort_by{|peer| peer.pending_requests.length}.first
      block = slowest_peer.pending_requests.last
    else
      block = @all_block_requests.pop
    end

    if block
      incoming_block.peer.pending_requests << block
      @request_queue.push(make_request(incoming_block.peer, block))    
    end
  end

  def make_request(peer, block)
    { connection: peer.connection,
      index:      block[:index],
      offset:     block[:offset],
      size:       block[:size] }
  end

  def init_requests
    @peers.each do |peer|
      NUM_PENDING.times do
        block = @all_block_requests.pop
        peer.pending_requests << block
        @request_queue.push(make_request(peer, block))
      end
    end    
  end
  
  def create_block(index, offset, size)
    { index: index, offset: offset, size: size }
  end

  def num_pieces(metainfo)
    (metainfo.total_size.to_f/metainfo.piece_length).ceil
  end

  def last_block_size(metainfo)
    metainfo.total_size.remainder(BLOCK_SIZE)
  end

  def num_full_blocks(metainfo)
    metainfo.total_size/BLOCK_SIZE
  end

  def last_piece_size
    file_size - (metainfo.piece_length * (metainfo.number_of_pieces - 1))
  end

  def num_blocks_in_piece(metainfo)
    (metainfo.piece_length.to_f/BLOCK_SIZE).ceil
  end

  def num_full_blocks_in_last_piece(metainfo)
    num_full_blocks(metainfo).remainder(num_blocks_in_piece(metainfo))
  end

  def total_num_blocks_in_last_piece(metainfo)
    num_full_blocks_in_last_piece(metainfo) + 1
  end

  def last_block_offset(metainfo)
    BLOCK_SIZE * num_full_blocks_in_last_piece(metainfo)
  end
end
