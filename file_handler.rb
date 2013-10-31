class FileHandler
  
  def initialize(metainfo)
    @metainfo = metainfo
    @temp_name = ('a'..'z').to_a.shuffle.take(10).join
    @file = init_file
  end
  
  def init_file
    File.open("temp/" + @temp_name, "w+")
    File.open("temp/" + @temp_name, "r+")
  end
  
  def write_block(block)
    puts block.end_byte
    @file.seek(block.start_byte)
    @file.write(block.data)
  end
  
end
    