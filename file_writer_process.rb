class FileWriterProcess

  def initialize(piece_to_write_queue, full_file_size)
    @queue = piece_to_write_queue
    @file = File.new('flag.jpg', 'w')
  end
  
  def run!
    loop  
      write_to_file(@queue.pop)
    end
  end
   
  def write_to_file(piece)
    
  end
end