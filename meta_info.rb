class MetaInfo
  
  attr_accessor :info_hash, :announce, :number_of_pieces, :files, :total_size, :piece_length, :pieces_hash, :folder
  
  def initialize(meta_info)
    @meta_info = meta_info
    @piece_length = @meta_info["info"]["piece length"]
    @info_hash = Digest::SHA1.new.digest(@meta_info['info'].bencode)
    @pieces_hash = @meta_info["info"]["pieces"]
    @announce = @meta_info["announce"]
    @number_of_pieces = @meta_info["info"]["pieces"].length/20
    set_total_size
    set_folder
    set_files
  end
  
  def set_total_size
    if is_multi_file?
      @total_size = @meta_info["info"]["files"].inject(0) do |start_byte, file| 
        start_byte + file["length"]
      end
    else
      @total_size = @meta_info["info"]["length"]
    end
    puts @total_size
  end
  
  def set_folder
    @folder = is_multi_file? ? @meta_info["info"]["name"] : nil
  end
  
  def set_files
    @files = []
    if is_multi_file?
      @meta_info["info"]["files"].inject(0) do |start_byte, file| 
        @files << { name:       file["path"][0],
                    length:     file["length"],
                    start_byte: start_byte }
        start_byte + file["length"]
      end
      
    else
      @files << { name:       @meta_info["info"]["name"],
                  length:     @meta_info["info"]["length"],
                  start_byte: 0 }
    end
  end
  
  def is_multi_file?
    !@meta_info["info"]["files"].nil?
  end
  
end