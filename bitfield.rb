class Bitfield
  
  attr_accessor :bits
  
  def initialize(*bit_array)
    @bits = bit_array.join
    puts @bits
  end
  
end