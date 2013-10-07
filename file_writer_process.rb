class FileWriterProcess

  def initialize(piece_to_write_queue, files)
    @queue = piece_to_write_queue
    @files = files
    @file = set_file 
  end
  
  def set_file
    File.new("downloads/" + @files[0][:name], "w+")
    File.open("downloads/" + @files[0][:name], "r+")
  end
  
  def run!
    loop { write_to_file(@queue.pop) }
  end
   
  def write_to_file(piece)
    @file.seek(piece.byte_offset_in_file)
    @file.write(piece.a_to_s)
  end
end