class Block
  
  attr_accessor :piece_index, :offset_in_piece, :data, :done
  
  def initialize(piece_index, offset, data)
    @piece_index = piece_index
    @offset_in_piece = offset
    @data = data
    @done = false
  end
  
  def is_done?
    @done
  end
  
  def inspect
    "piece #{@piece_index}, offset #{@offset_in_piece}, data len #{@data.length}"
  end
  
end