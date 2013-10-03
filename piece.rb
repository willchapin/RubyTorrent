class Piece
  
  attr_accessor :size, :index, :byte_offset_in_file
  
  def initialize(size, index, correct_hash, typical_piece_size)
    @size = size
    @byte_array = Array.new(size, nil)
    @index = index
    @byte_offset_in_file = @index * typical_piece_size
    @correct_hash = correct_hash
  end
  
  def write_block(block)
    begin_index = block[:byte_offset]
    end_index = begin_index + block[:block_data].length
    @byte_array[begin_index...end_index] = block[:block_data].split("")
  end
  
  def is_complete?
    !@byte_array.include?(nil)
  end
  
  def a_to_s
    @byte_array.join("")
  end
  
  def is_verified?
    Digest::SHA1.new.digest(@byte_array.join) == @correct_hash
  end
end