class Piece
  
  attr_accessor :size, :index
  
  def initialize(size, index, correct_hash, typical_piece_size)
    @size = size
    @byte_array = Array.new(@size, nil)
    @index = index
    @correct_hash = correct_hash
  end
  
  def write_block(block)
    begin_index = block.offset_in_piece
    end_index = begin_index + block.data.length
    @byte_array[begin_index..end_index] = block.data.split("")
    binding.pry if @byte_array.count(nil) == 16384
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