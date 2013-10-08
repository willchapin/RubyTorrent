class FileWriterProcess

  def initialize(piece_to_write_queue, file_paths, folder)
    @queue = piece_to_write_queue
    @folder = folder
    @file_paths = file_paths
    @files = []
    initialize_files 
  end
  
  def initialize_files    
    
    if @folder
      Dir.mkdir("downloads/" + @folder)
      @file_paths.each do |path|
        File.new("downloads/" + @folder + "/" + path[:name], "w+")
        @files << File.open("downloads/" + @folder + "/" + path[:name], "r+")
      end
    else
      File.new("downloads/" + @file_paths.first[:name], "w+")
      @files << File.open("downloads/" + @file_paths.first[:name], "r+")
    end
  end
  
  def run!
    loop { write_to_file(@queue.pop) }
  end
   
  def write_to_file(piece)
    @files[0].seek(piece.byte_offset_in_file)
    @files[0].write(piece.a_to_s)
  end
end


#commit 'modify to separate files correctly'