class MetaInfo
    
  attr_accessor :info_hash, :announce, :number_of_pieces, :pieces, :files, :total_size, :piece_length, :pieces_hash, :folder, :download_folder
  
  def initialize(meta_info, download_folder)
    @meta_info = meta_info
    @download_folder = download_folder
    @piece_length = @meta_info["info"]["piece length"]
    @info_hash = Digest::SHA1.new.digest(@meta_info['info'].bencode)
    @pieces_hash = @meta_info["info"]["pieces"]
    @announce = @meta_info["announce"]
    @number_of_pieces = @meta_info["info"]["pieces"].length/20
    set_total_size
    set_folder
    set_files
    set_pieces
  end
  
  def set_pieces
    @pieces = []
    (0...@number_of_pieces).each do |i|
      index = i
      start_byte = i * @piece_length 
      if i == @number_of_pieces - 1
        end_byte = @total_size - 1
      else
        end_byte = start_byte + @piece_length - 1
      end
      hash = @meta_info["info"]["pieces"][20*i...20*(i+1)]
      @pieces << Piece.new(index, start_byte, end_byte, hash)
    end
  end
  
  def set_total_size
    if is_multi_file?
      @total_size = @meta_info["info"]["files"].inject(0) do |start_byte, file| 
        start_byte + file["length"]
      end
    else
      @total_size = @meta_info["info"]["length"]
    end
  end
  
  def set_folder
    @folder = is_multi_file? ? @meta_info["info"]["name"] : nil
  end
  
  def set_files
    @files = []
    if is_multi_file?
      @meta_info["info"]["files"].inject(0) do |start_byte, file| 
        @files << { name: file["path"][0],
                    length: file["length"],
                    start_byte: start_byte,
                    end_byte: start_byte + file["length"] - 1
                  }
        start_byte + file["length"]
      end
    else
      @files << { name: @meta_info["info"]["name"],
                  length: @meta_info["info"]["length"],
                  start_byte: 0,
                  end_byte: @meta_info["info"]["length"] - 1 }
    end
  end
  
  def is_multi_file?
    !@meta_info["info"]["files"].nil?
  end
  
end
