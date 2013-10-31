class Piece
  
  attr_accessor :index, :start_byte, :end_byte
  
  def initialize(index, start_byte, end_byte, hash)
    @index = index
    @start_byte = start_byte
    @end_byte = end_byte
    @hash = hash
  end
  
end