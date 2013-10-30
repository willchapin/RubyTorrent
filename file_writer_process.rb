class FileWriterProcess

  BLOCK_SIZE = 2**14

  def initialize(blocks_to_write_queue, byte_array, meta_info)
    @byte_array = byte_array
    @queue = blocks_to_write_queue
    @meta_info = meta_info
    @disk = Disk.new(meta_info) 
  end
    
  def run!
    loop do
      block = @queue.pop
      @disk.write(block)
      record(block)
      verify(block.piece_index)
    end
  end
  
  def record(block)
    start_byte, end_byte = get_range(block)
    @byte_array.has_all(start_byte, end_byte)
  end
  
  def verify(piece_index)
    current_piece_size = current_piece_size(piece_index)
    piece_start_byte = piece_index * piece_size
    piece_end_byte = piece_start_byte + current_piece_size - 1
    
    puts "do we have the piece numbered #{piece_index}? #{@byte_array.has_all?(piece_start_byte, piece_end_byte)}"
        
    if @byte_array.has_all?(piece_start_byte, piece_end_byte)
      puts "whoop"
      puts correct_hash(piece_index)
      puts Digest::SHA1.new.digest(@disk.read(piece_start_byte, piece_end_byte))
      puts "doop"
      if correct_hash(piece_index) == Digest::SHA1.new.digest(
                                        @disk.read(piece_start_byte, piece_end_byte))
        puts "yeah yeah yeah!"
      elsif
        puts "nah nah nah!"
      end
    end
  end
  
  def get_range(block)
    size = last_block?(block) ? last_block_size : BLOCK_SIZE  
    start_byte = block.piece_index * piece_size + block.offset_in_piece
    end_byte = start_byte + size - 1
    [start_byte, end_byte] 
  end

  def done?
    @piece_verification_table.count(0).zero?
  end
  
  def current_piece_size(piece_index)
    last_piece?(piece_index) ? last_piece_size : piece_size
  end

  def byte_range(piece_index, block_index)
    start = (piece_index * piece_size) + (block_index * BLOCK_SIZE)
    fin = start + BLOCK_SIZE - 1
    [start, fin]
  end
  
  def last_block?(block)
    block.piece_index * num_blocks_in_piece + (block.offset_in_piece/BLOCK_SIZE) == total_num_blocks - 1
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
  
  def correct_hash(piece_index)
    start_byte = piece_index * 20
    end_byte = start_byte + 19
    @meta_info.pieces_hash[start_byte..end_byte]
  end
end

