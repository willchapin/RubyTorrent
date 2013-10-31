class FileBuilder
  
  def initialize(metainfo)
    @metainfo = metainfo
    @temp_name = ('a'..'z').to_a.shuffle.take(10).join
    @file = init_file
  end
  
  def init_file
    File.new("temp/" + @temp_name, "w+")
    File.open("temp/" + @temp_name, "r+")
  end
  
  def write_block(block)
    @file.seek(block.start_byte)
    @file.write(block.data)
  end
end
    