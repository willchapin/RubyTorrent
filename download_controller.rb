class DownloadController
  
  
  def initialize(meta_info, block_request_queue, incoming_block_queue)
    @meta_info = meta_info
    @bitfield = "0" * (@meta_info["info"]["pieces"].length/20)
    @pieces = []
    @block_request_queue = block_request_queue
    @incoming_block_queue = incoming_block_queue
    @piece_to_write_queue = Queue.new
  end
  
  def run!
    # add needed block requests to the block_request_queue
    Thread.new {  }
    
    
    Thread.new do
      loop do
        block = @incoming_block_queue.pop
        process_block(block)
      end 
    end
  end
  
  def process_block(block)
    
    if new_piece?(block)
      make_new_piece(block)
    end
    
    piece = @pieces.find { |piece| piece.index == block[:piece_index] }
    piece.write_block(block)
    if piece.is_complete?
      puts piece.is_verified?
      puts piece.index
    end
 
  end
  
  def new_piece?(block)
    @pieces.none? { |piece| piece.index == block[:piece_index] }
  end 
  
  def make_new_piece(block)
    index = block[:piece_index]
    hash_begin = index * 20
    hash_end = hash_begin + 20
    @pieces << Piece.new(@meta_info["info"]["piece length"],
                         index,
                         @meta_info["info"]["pieces"][hash_begin...hash_end])
  end
end

