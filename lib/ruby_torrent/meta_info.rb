class MetaInfo

  attr_accessor :info_hash, :announce, :number_of_pieces,
                :pieces, :files, :total_size, :piece_length,
                :pieces_hash, :folder, :download_folder
  
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

  def set_total_size
    if is_multi_file?
      set_multi_file_size
    else
      set_single_file_size
    end
  end

  def set_multi_file_size
    @total_size = @meta_info["info"]["files"].inject(0) do |start_byte, file| 
      start_byte + file["length"]
    end
  end
  
  def set_single_file_size
    @total_size = @meta_info["info"]["length"]
  end

  def set_folder
    @folder = is_multi_file? ? @meta_info["info"]["name"] : nil
  end

  def set_files
    @files = []
    if is_multi_file?
      set_multi_files
    else
      set_single_file
    end
  end

  def set_multi_files
    @meta_info["info"]["files"].inject(0) do |start_byte, file| 
      name = file["path"][0]
      length = file["length"]
      start_byte = start_byte
      end_byte = start_byte + file["length"] - 1
      add_file(name, length, start_byte, end_byte)
      
      start_byte + file["length"]
    end
  end

  def set_single_file
    name =  @meta_info["info"]["name"]
    length = @meta_info["info"]["length"]
    start_byte = 0
    end_byte =  @meta_info["info"]["length"] - 1
    add_file(name, length, start_byte, end_byte)
  end
  
  def add_file(name, length, start, fin)
    @files << { name: name, length: length, start_byte: start, end_byte: fin }
  end
 
  def set_pieces
    @pieces = []
    (0...@number_of_pieces).each do |index|
      start_byte = index * @piece_length 
      end_byte = get_end_byte(start_byte, index)
      hash = get_correct_hash(index)
      @pieces << Piece.new(index, start_byte, end_byte, hash)
    end
  end

  def get_end_byte(start_byte, index)
    return @total_size - 1 if last_piece?(index)
    start_byte + @piece_length - 1
  end
    
  def last_piece?(index)
    index == @number_of_pieces - 1
  end

  def get_correct_hash(index)
    @meta_info["info"]["pieces"][20 * index...20 * (index+1)]
  end
    
  def is_multi_file?
    !@meta_info["info"]["files"].nil?
  end
  
end
