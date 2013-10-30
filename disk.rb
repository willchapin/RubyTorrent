class Disk

  def initialize(meta_info)
    @meta_info = meta_info
    @file_infos = @meta_info.files
    @files = set_files
  end
 
  def set_files
    files = []
    if @meta_info.is_multi_file?
      Dir.mkdir("downloads/" + @meta_info.folder)
      byte_counter = 0
      @file_infos.each_with_index do |file_info, index|
      File.new("downloads/" + @meta_info.folder + "/" + file_info[:name], "w+")
      files << FileWrapper.new(
                  File.open("downloads/" + @meta_info.folder + "/" + file_info[:name], "r+"),
                  file_info,
                  index)
      end 
    else
      File.new("downloads/" + @file_infos.first[:name], "w+")
      files << FileWrapper.new(
                        File.open("downloads/" + @file_infos.first[:name], "r+"),
                        @file_infos.first,
                        0)
    end
    files
  end
 
  def write(block)
    file_wrap = starting_file(block)
    offset = file_offset(block, file_wrap)
    write_to_disk(file_wrap, offset, block)
    puts "writing block #{block.inspect}"
  end
  
  def write_to_disk(file_wrap, offset, block)
    if block_fits_in_file?(file_wrap, offset, block)
      data_to_write = block.data
      block.done = true
    else
      data_to_write = block.data.slice!(0..space_in_file(file_wrap, offset))
    end
    file_wrap.file.seek(offset)
    file_wrap.file.write(data_to_write)
    write_to_disk(@files[file_wrap.index + 1], 0, block) unless block.is_done?
  end
  
  def read(start_byte, end_byte)
    puts "reading from file start_byte: #{start_byte}, end_byte: #{end_byte}"
    file_wrap = get_starting_file(start_byte)
    puts "file wrap index: #{file_wrap.index}"
    puts @files.length
    result = ""
    file_wrap.file.seek(start_byte - file_wrap.info[:start_byte])
    puts "FILE WRAP: #{file_wrap.inspect}"
    if spans_two_file?(file_wrap, end_byte)
      current_file_index = @files.index(file_wrap)
      next_file = @files[current_file_index + 1]
      result << read(next_file.info[:start_byte], end_byte)
    else
      result << file_wrap.file.read(end_byte - start_byte)
    end
    result
  end
  
  def get_starting_file(start_byte)
    if @meta_info.is_multi_file?
      file_index = 0
      1.upto(@file_infos.length - 1).each do |i|
        if @file_infos[i][:start_byte] > start_byte
          break
        else
          file_index += 1
        end
      end
      return @files[file_index]     
    else
      return @files[0]
    end
  end
  
  def spans_two_file?(file_wrap, end_byte)
    puts "file end: #{file_wrap.info[:end_byte]}, total_end: #{end_byte}" 
    file_wrap.info[:end_byte] < end_byte
  end
  
  def space_in_file(file_wrap, offset)
    file_wrap.info[:length] - offset 
  end
  
  def block_fits_in_file?(file_wrap, offset, block)
    block.data.length <= file_wrap.info[:length] - offset
  end
  
  def file_offset(block, file_wrap)
    global_start(block) - file_wrap.info[:start_byte]
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

  def starting_file(block)
    if @meta_info.is_multi_file?
      file_index = 0
      1.upto(@file_infos.length - 1).each do |i|
        if @file_infos[i][:start_byte] > global_start(block)
          break
        else
          file_index += 1
        end
      end
      return @files[file_index]     
    else
      return @files[0]
    end
  end

end