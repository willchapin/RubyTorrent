class Piece
  
  attr_accessor :index, :start_byte, :end_byte, :length, :hash
  
  def initialize(index, start_byte, end_byte, hash)
    @index = index
    @start_byte = start_byte
    @end_byte = end_byte
    @length = @end_byte - @start_byte + 1
    @hash = hash
  end
  
end