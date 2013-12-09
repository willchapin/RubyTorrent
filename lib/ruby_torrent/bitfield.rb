class Bitfield
  
  attr_accessor :bits
  
  def initialize(*bit_array)
    @bits = bit_array.join.split('').map! { |char| char.to_i }
    p @bits
  end
  
  def have_piece(index)
    @bits[index] = 1
  end
  
end