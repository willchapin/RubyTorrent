class Piece
  
  attr_accessor :index
  
  def initialize(size, index, correct_hash)
    @byte_array = Array.new(size, nil)
    @index = index
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
  
  def is_verified?
    Digest::SHA1.new.digest(@byte_array.join) == @correct_hash
  end
end