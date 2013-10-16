class IncomingBlockProcess

  BLOCK_SIZE = 2**14
  
  attr_accessor :piece_verification_table

  def initialize(incoming_block_queue, blocks_to_write, meta_info, piece_verification_table, pending_requests)
    @incoming_block_queue = incoming_block_queue
    @blocks_to_write = blocks_to_write
    @meta_info = meta_info
    @piece_verification_table = piece_verification_table
    @pending_requests = pending_requests
    @pieces = []
  end
  
  def run!
    loop do
      process_block(@incoming_block_queue.pop)
      @pending_requests -= 1
      puts @pending_requests
    end
  end
  
   def process_block(block)
        
    if new_piece?(block)
      make_new_piece(block)
    end
    
    piece = @pieces.find { |piece| piece.index == block.piece_index }
    piece.write_block(block)
    
    @blocks_to_write.push(block)
    
    if piece.is_complete?
      puts "piece #{piece.index} (#{piece.size} bytes) has been downloaded"
      if piece.is_verified?
        puts "piece #{piece.index} (#{piece.size} bytes) has been verified"
        @piece_verification_table[piece.index] = 1
      end
    end
  end
  
  def new_piece?(block)
    @pieces.none? { |piece| piece.index == block.piece_index }
  end 

  def make_new_piece(block)
        
    if last_piece?(block.piece_index)
      size = last_piece_size
    else
      size = @meta_info.piece_length
    end
    
    hash_begin_index = block.piece_index * 20
    hash_end_index = hash_begin_index + 20
    @pieces << Piece.new(size,
                         block.piece_index,
                         @meta_info.pieces_hash[hash_begin_index...hash_end_index])
  end
  
  def piece_size
    @meta_info.piece_length
  end
  
  def num_pieces
    (file_size.to_f/piece_size).ceil
  end
  
  def last_block_size
    file_size.remainder(BLOCK_SIZE)
  end
  
  def is_last_block?(total_blocks)
    total_blocks == num_full_blocks
  end
  
  def num_full_blocks
    @meta_info.total_size/BLOCK_SIZE
  end
  
  def total_num_blocks
    (@meta_info.total_size.to_f/BLOCK_SIZE).ceil
  end
  
  def file_size
    @meta_info.total_size
  end
  
  def last_piece_size 
    file_size - (piece_size * (@meta_info.number_of_pieces - 1))
  end
  
  def num_blocks_in_piece
    (piece_size.to_f/BLOCK_SIZE).ceil
  end
  
  def num_full_blocks_in_last_piece
    num_full_blocks.remainder(num_blocks_in_piece)   
  end
  
  def last_piece?(index)
    index == @meta_info.number_of_pieces - 1
  end
end