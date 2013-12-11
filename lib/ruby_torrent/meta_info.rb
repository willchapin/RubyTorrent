class MetaInfo

  attr_accessor :info_hash, :announce, :number_of_pieces,
                :pieces, :files, :total_size, :piece_length,
                :pieces_hash, :folder, :download_folder
  
  def initialize(meta_info, download_folder)
    @info = meta_info["info"]
    @download_folder = download_folder
    @piece_length = @info["piece length"]
    @info_hash = Digest::SHA1.new.digest(@info.bencode)
    @pieces_hash = @info["pieces"]
    @announce = meta_info["announce"]
    @number_of_pieces = @info["pieces"].length/20
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
    @total_size = @info["files"].inject(0) do |start_byte, file| 
      start_byte + file["length"]
    end
  end
  
  def set_single_file_size
    @total_size = @info["length"]
  end

  def set_folder
    @folder = is_multi_file? ? @info["name"] : nil
  end

  def set_files
    @files = []
    if is_multi_file?
      set_multi_files
    else
      add_file(@info["name"], @info["length"], 0, @info["length"] - 1)
    end
  end

  def set_multi_files
    @info["files"].inject(0) do |start_byte, file| 
      name, length, start_byte, end_byte = get_add_file_args(start_byte, file)
      add_file(name, length, start_byte, end_byte)      
      start_byte + file["length"]
    end
  end

  def get_add_file_args(start_byte, file)
    name = file["path"][0]
    length = file["length"]
    start_byte = start_byte
    end_byte = start_byte + file["length"] - 1
    
    return name, length, start_byte, end_byte
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
    @info["pieces"][20 * index...20 * (index+1)]
  end
    
  def is_multi_file?
    !@info["files"].nil?
  end
  
end
