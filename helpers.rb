module Helpers
  
  BLOCK_SIZE = 2**14
  
  def self.set_meta_info(meta_info)
    @meta_info = meta_info
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
  
  def total_num_blocks_in_last_piece
    num_full_blocks_in_last_piece + 1
  end
  
  def last_piece?(index)
    index == @meta_info.number_of_pieces - 1
  end
  
  def get_piece_size(piece_index)
    last_piece?(piece_index) ? last_piece_size : piece_size
  end
  
  def get_block_size(piece_index, block_index)
    last_block?(piece_index, block_index) ? last_block_size : BLOCK_SIZE
  end
  
  def last_block?(piece_index, block_index)
    total_num_blocks - 1 == block_index + (piece_index * num_blocks_in_piece) 
  end

end