class BlockRequestScheduler

  BLOCK_SIZE = 2**14
  NUM_PENDING = 10
  
  attr_accessor :request_queue
  
  def initialize(peers, metainfo)
    @peers = peers
    @metainfo = metainfo
    @all_block_requests = create_blocks
    @request_queue = Queue.new
    create_blocks
    init_requests
  end
  
  def create_blocks
    requests = []
    0.upto(num_pieces - 2).each do |piece_num|
      0.upto(num_blocks_in_piece - 1).each do |block_num|
        requests.push(create_block(piece_num,
                                   BLOCK_SIZE * block_num,
                                   BLOCK_SIZE))
      end
    end

    # last piece
    0.upto(num_full_blocks_in_last_piece - 1) do |block_num|
      requests.push(create_block(num_pieces - 1,
                                 BLOCK_SIZE * block_num,
                                 BLOCK_SIZE))
    end

    # last block
    requests.push(create_block(num_pieces - 1,
                               last_block_offset,
                               last_block_size))
    
    push_request(num_pieces(metainfo) - 1,
                 last_block_offset(metainfo),
                 last_block_size(metainfo))
       
    # last block
  end

  def push_request(index, offset, size)
    @all_block_requests.push(create_block(index, offset, size))
  end

  def push_request(index, offset, size)
    requests.push(create_block(index, offset, size))
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

  def last_block_offset(metainfo)
    BLOCK_SIZE * num_full_blocks_in_last_piece(metainfo)
  end
end
