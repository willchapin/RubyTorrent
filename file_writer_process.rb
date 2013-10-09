class FileWriterProcess

  BLOCK_SIZE = 2**14

  def initialize(blocks_to_write_queue, meta_info, folder)
    @queue = blocks_to_write_queue
    @folder = folder
    @meta_info = meta_info
    @file_paths = @meta_info.files
    puts meta_info.files
    puts meta_info.total_size
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
    
  def write_to_file(block)
    file_index = get_starting_file_index(block)
    file_offset = byte_to_write(block, file_index)
    while block.data
      if remainder_in_file(file_index, file_offset) < block.data.length
        puts "hry!"
        data_to_write = block.data.slice!(remainder_in_file(file_index, file_offset))
      else
        data_to_write = block.data
        block.data = nil
      end 
      puts file_index
      @files[file_index].seek(file_offset)
      @files[file_index].write(data_to_write)
      file_offset = 0
      file_index += 1
    end
  end
  
  def remainder_in_file(file_index, file_offset)
    @meta_info.files[file_index][:length] - file_offset
  end
  
  def byte_to_write(block, file_index)
    global_start(block) - @meta_info.files[file_index][:start_byte]
  end
  
  def global_start(block)
    (block.piece_index * @meta_info.piece_length) + block.offset_in_piece
  end
  
  def global_end(block)
    global_start(block) + block.data.length
  end
  
  def get_starting_file_index(block)
    if @folder
      file_index = 0
      1.upto(@meta_info.files.length - 1).each do |i|
        if @meta_info.files[i][:start_byte] > global_start(block)
          break
        else
          file_index += 1
        end
      end
      return file_index      
    else
      return 0 
    end
  end
end

