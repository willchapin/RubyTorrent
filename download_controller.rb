class DownloadController
  
  require 'pry'
  
  BLOCK_SIZE = 2**14
  
  def initialize(meta_info, block_request_queue, incoming_block_queue, peers)
    @meta_info = meta_info
    @piece_bitfield = "0" * (@meta_info.number_of_pieces)
    puts get_total_num_blocks
    puts @block_bitfield
    @pieces = []
    @block_request_queue = block_request_queue
    @incoming_block_queue = incoming_block_queue
    @peers = peers
    @blocks_to_write = Queue.new
    @verification_table = [0] * get_num_pieces
  end
  
  def run!
    Thread.new { FileWriterProcess.new(@blocks_to_write, @meta_info).run! } 
    Thread.new { push_to_block_request_queue }
    Thread.new { loop { process_block(@incoming_block_queue.pop) } }        
  end
  
  def push_to_block_request_queue
    piece = 0
    block_count = 0
    peer = @peers.last

    0.upto(get_num_pieces - 2).each do |piece_num|
      0.upto(get_num_blocks_in_piece - 1).each do |block_num|
        @block_request_queue.push({ 
          connection: peer.connection, index: piece_num, offset: BLOCK_SIZE * block_num, size: BLOCK_SIZE })
      end
    end
    
    # last piece
    0.upto(get_num_full_blocks_in_last_piece - 2) do |block_num|
      @block_request_queue.push({
        connection: peer.connection, index: get_num_pieces - 1, offset: BLOCK_SIZE * block_num, size: BLOCK_SIZE })
    end
    
    # last block
    puts "request: " 
    puts get_num_pieces - 1
    puts BLOCK_SIZE * get_num_full_blocks_in_last_piece
    puts get_last_block_size
    
    @block_request_queue.push({
      connection: peer.connection, index: get_num_pieces - 1, offset: BLOCK_SIZE * get_num_full_blocks_in_last_piece, size: get_last_block_size  })
 
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
        @verification_table[piece.index] = 1
        puts @verification_table
      end
    end
  end

  def new_piece?(block)
    @pieces.none? { |piece| piece.index == block.piece_index }
  end 

  def make_new_piece(block)
        
    if block.piece_index == @meta_info.number_of_pieces - 1
      puts "walla"
      size = get_last_piece_size
    else
      size = @meta_info.piece_length
    end
    
    hash_begin_index = block.piece_index * 20
    hash_end_index = hash_begin_index + 20
    @pieces << Piece.new(size,
                         block.piece_index,
                         @meta_info.pieces_hash[hash_begin_index...hash_end_index],
                         @meta_info.piece_length)
  end
  
  def get_piece_size
    @meta_info.piece_length
  end
  
  def get_num_pieces
    (get_file_size.to_f/get_piece_size).ceil
  end
  
  def get_last_block_size
    get_file_size.remainder(BLOCK_SIZE)
  end
  
  def is_last_block?(total_blocks)
    total_blocks == get_num_full_blocks
  end
  
  def get_num_full_blocks
    @meta_info.total_size/BLOCK_SIZE
  end
  
  def get_total_num_blocks
    (@meta_info.total_size.to_f/BLOCK_SIZE).ceil
  end
  
  def get_file_size
    @meta_info.total_size
  end
  
  def get_last_piece_size 
    get_file_size - (get_piece_size * (@meta_info.number_of_pieces - 1))
  end
  
  def get_num_blocks_in_piece
    (get_piece_size.to_f/BLOCK_SIZE).ceil
  end
  
  def get_num_full_blocks_in_last_piece
    get_num_full_blocks.remainder(get_num_blocks_in_piece)   
  end
end

