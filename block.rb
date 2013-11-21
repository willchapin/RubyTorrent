class Block
  attr_accessor :start_byte, :end_byte, :data, :piece_index, :peer, :offset

  def initialize(piece_index, offset, data, piece_length, peer)
    @offset = offset
    @peer = peer
    @data = data
    @piece_index = piece_index
    @offset = offset
    @start_byte = get_start_byte(piece_length)
    @end_byte = get_end_byte
  end

  def inspect
    "piece #{@piece_index}, offset #{@offset_in_piece}, data len #{@data.length}"
  end

  private

    def get_start_byte(piece_length)
      @piece_index * piece_length + @offset
    end

    def get_end_byte
      @start_byte + @data.length - 1
    end

end

  
