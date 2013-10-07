class FileWriterProcess

  def initialize(piece_to_write_queue, file_name)
    @queue = piece_to_write_queue
    @file_name = file_name
    @file = set_file 
  end
  
  def set_file
    File.new("downloads/" + @file_name, "w+")
    File.open("downloads/" + @file_name, "r+")
  end
  
  def run!
    loop { write_to_file(@queue.pop) }
  end
   
  def write_to_file(piece)
    @file.seek(piece.byte_offset_in_file)
    @file.write(piece.a_to_s)
  end
end