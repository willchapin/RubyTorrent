class Download

  attr_accessor :bitfield, :piece_hashes, :piece_length, :pieces, :number_of_pieces
  
  def initialize(meta_info)
    @number_of_pieces = meta_info["info"]["pieces"].length/20
    set_bitfield(@number_of_pieces)
    set_piece_hashes(meta_info)
    set_pieces
  end
  
  def set_bitfield(length)
    @bitfield = "0" * (length)
  end
     
  def set_piece_hashes(meta_info)
    @piece_hashes = meta_info["info"]["pieces"].scan(/.{20}/)
  end

  def set_pieces
    @pieces = Array.new(@number_of_pieces) { Piece.new }
  end
end