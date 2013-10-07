class MetaInfo
  
  attr_accessor :info_hash, :announce, :number_of_pieces, :file_name, :file_size, :piece_length, :pieces_hash
  
  def initialize(meta_info)
    @meta_info = meta_info
    @file_name = @meta_info["info"]["name"]
    @piece_length = @meta_info["info"]["piece length"]
    @file_size = @meta_info["info"]["length"]
    @info_hash = Digest::SHA1.new.digest(@meta_info['info'].bencode)
    @pieces_hash = @meta_info["info"]["pieces"]
    @announce = @meta_info["announce"]
    @number_of_pieces = @meta_info["info"]["pieces"].length/20
  end
  
  def is_multi_file?
    @meta_info["info"]["files"] != nil
  end
  
end