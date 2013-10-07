class DownloadController
  
  BLOCK_SIZE = 2**14
  
  def initialize(meta_info, block_request_queue, incoming_block_queue, peers)
    @meta_info = meta_info
    @bitfield = "0" * (@meta_info.number_of_pieces)
    @pieces = []
    @block_request_queue = block_request_queue
    @incoming_block_queue = incoming_block_queue
    @peers = peers
    @pieces_to_write = Queue.new
  end
  
  def run!
    Thread.new { FileWriterProcess.new(@pieces_to_write, @meta_info.file_name ).run! } 
    Thread.new { push_to_block_request_queue }
    Thread.new { loop { process_block(@incoming_block_queue.pop) } }        
  end
  
  def push_to_block_request_queue
    piece = 0
    total_blocks = 0
    peer = @peers.last
    while piece < @meta_info.number_of_pieces
      offset = 0
      while offset < get_piece_size
        if is_last_block?(total_blocks)
          @block_request_queue.push({ connection: peer.connection, index: piece, offset: offset, size: get_last_block_size })
        else
          @block_request_queue.push({ connection: peer.connection, index: piece, offset: offset, size: BLOCK_SIZE })
        end
        total_blocks += 1
        offset += BLOCK_SIZE
      end
      piece += 1
    end
  end
  
  def process_block(block)
    
    if new_piece?(block)
      make_new_piece(block)
    end
    
    piece = @pieces.find { |piece| piece.index == block[:piece_index] }
    piece.write_block(block)
    
    if piece.is_complete?
      if piece.is_verified?
        puts "piece #{piece.index} (#{piece.size} bytes) has been downloaded and verified"
        @pieces_to_write.push(piece)
      end
    end
  end
   
  def new_piece?(block)
    @pieces.none? { |piece| piece.index == block[:piece_index] }
  end 

  def make_new_piece(block)
        
    if block[:piece_index] == @meta_info.number_of_pieces - 1
      size = get_last_piece_size
    else
      size = @meta_info.piece_length
    end
    hash_begin_index = block[:piece_index] * 20
    hash_end_index = hash_begin_index + 20
    @pieces << Piece.new(size,
                         block[:piece_index],
                         @meta_info.pieces_hash[hash_begin_index...hash_end_index],
                         @meta_info.piece_length)
  end
  
  def get_piece_size
    @meta_info.piece_length
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
    @meta_info.file_size
  end
  
  def get_last_piece_size 
    get_file_size - (get_piece_size * (@meta_info.number_of_pieces - 1))
  end
end

