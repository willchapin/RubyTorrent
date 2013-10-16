class FileWriterProcess

  BLOCK_SIZE = 2**14

  def initialize(blocks_to_write_queue, byte_array, meta_info)
    @byte_array = byte_array
    @queue = blocks_to_write_queue
    @disk = Disk.new(meta_info) 
  end
    
  def run!
    loop do
      @disk.write(@queue.pop)
    end
  end
end

