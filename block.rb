require_relative 'helpers'
class Block
  
  include Helpers
  
  attr_accessor :start_byte, :end_byte, :data
  
  def initialize(piece_index, offset, data, metainfo)
    @metainfo = metainfo
    @data = data
    @piece_index = piece_index
    @offset = offset
    @start_byte = get_start_byte
    @end_byte = get_end_byte
  end
  
  def inspect
    "piece #{@piece_index}, offset #{@offset_in_piece}, data len #{@data.length}"
  end
  
  private
  
    def get_start_byte
      @piece_index * piece_size + @offset
    end
    
    def get_end_byte
      @start_byte + @data.length - 1
    end
  
end