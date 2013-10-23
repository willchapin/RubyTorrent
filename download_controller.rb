class DownloadController
  
  require 'pry'
  require 'matrix'
  
  BLOCK_SIZE = 2**14
  
  def initialize(meta_info, block_request_queue, incoming_block_queue, peers)
    @meta_info = meta_info
    @piece_bitfield = "0" * (@meta_info.number_of_pieces)
    @block_request_queue = block_request_queue
    @incoming_block_queue = incoming_block_queue
    @peers = peers
    @byte_array = DownloadedByteArray.new(meta_info)
    @piece_verification_table = [0] * num_pieces
    @blocks_to_write = Queue.new
    @pending_requests = 0
  end
  
  def run!
    Thread::abort_on_exception = true # remove later?
    Thread.new { FileWriterProcess.new(@blocks_to_write, @byte_array, @meta_info).run! } 
    Thread.new { incoming_block_process }    
    Thread.new { push_to_block_request_queue }
    
  end
  
  def push_to_block_request_queue
            
   # until done?
   #   rarest_piece_index = sorted_piece_indices[0]
   #   puts "rarest piece index: #{rarest_piece_index} !!!!"
   #   get_piece(rarest_piece_index)
   # end  
    
    requests = [] 
    
    0.upto(num_pieces - 2).each do |piece_num|
      0.upto(num_blocks_in_piece - 1).each do |block_num|
        requests.push({ connection: @peers.sample.connection, index: piece_num, offset: BLOCK_SIZE * block_num, size: BLOCK_SIZE })
      end
    end
    
    # last piece
    0.upto(num_full_blocks_in_last_piece - 1) do |block_num|
      requests.push({ connection: @peers.sample.connection, index: num_pieces - 1, offset: BLOCK_SIZE * block_num, size: BLOCK_SIZE })
    end
    
    # last block
    requests.push({ connection: @peers.sample.connection, index: num_pieces - 1, offset: BLOCK_SIZE * num_full_blocks_in_last_piece, size: last_block_size })
    
    requests.shuffle
    requests.each { |request| @block_request_queue.push(request) }
  
  end
  
  def get_piece(piece_index)
    puts "PIECE INDEX #{piece_index}"
    block_num = 0
    until verified?(piece_index)
      while @pending_requests <= 10
        # For the love of God refactor
        block_num.upto(num_blocks_in_piece - 1).each do |block_index|
          start, fin = byte_range(piece_index, block_index)
          puts start
          puts fin
          unless @byte_array.has_all?(start, fin)
            puts "block index: #{block_index}"
            @block_request_queue.push({ connection: @peers.sample.connection, index: piece_index, offset: BLOCK_SIZE * block_index, size: BLOCK_SIZE })
            @pending_requests += 1
          end
          block_num += 1
          break if @pending_requests > 10
        end
      end
    end
  end

  def incoming_block_process
    loop do
      process_block(@incoming_block_queue.pop)
      @pending_requests -= 1
    end
  end
  
  def process_block(block)
      
    @blocks_to_write.push(block)
    start_byte, end_byte = get_range(block)
    @byte_array.has_all(start_byte, end_byte)
    
    current_piece_size = current_piece_size(block.piece_index)
    piece_start_byte = block.piece_index * piece_size
    piece_end_byte = piece_start_byte + current_piece_size - 1
    
    puts "do we have the piece numbered #{block.piece_index}? #{@byte_array.has_all?(piece_start_byte, piece_end_byte)}"
    #puts @byte_array.inspect
     
  end
  
  def get_range(block)
    size = last_block?(block) ? last_block_size : BLOCK_SIZE  
    start_byte = block.piece_index * piece_size + block.offset_in_piece
    end_byte = start_byte + size - 1
    [start_byte, end_byte] 
  end

  def done?
    @piece_verification_table.count(0).zero?
  end
  
  def current_piece_size(piece_index)
    last_piece?(piece_index) ? last_piece_size : piece_size
  end

  def byte_range(piece_index, block_index)
    start = (piece_index * piece_size) + (block_index * BLOCK_SIZE)
    fin = start + BLOCK_SIZE - 1
    [start, fin]
  end

  def sorted_piece_indices
    # refactor? super confusing? exceptionally unclear?
    bit_sum = @peers.map { |peer| Matrix[peer.bitfield.bits] }.reduce(:+).to_a.flatten
    piece_list = remove_finished_pieces(bit_sum)
    sort_by_index(piece_list)
  end
  
  def last_block?(block)
    block.piece_index * num_blocks_in_piece + (block.offset_in_piece/BLOCK_SIZE) == total_num_blocks - 1
  end
  
  def sort_by_index(piece_list)
    piece_list.map.with_index.sort_by(&:first).map(&:last)
  end
  
  def remove_finished_pieces(bit_sum)
    puts bit_sum.class
    puts @piece_verification_table.class
    (0...num_pieces).map { |i| (@piece_verification_table[i] - 1).abs * bit_sum[i] }
  end
  
  def piece_size
    @meta_info.piece_length
  end
  
  def num_pieces
    (file_size.to_f/piece_size).ceil
  end
  
  def last_block_size
    file_size.remainder(BLOCK_SIZE)
  end
  
  def is_last_block?(total_blocks)
    total_blocks == num_full_blocks
  end
  
  def num_full_blocks
    @meta_info.total_size/BLOCK_SIZE
  end
  
  def total_num_blocks
    (@meta_info.total_size.to_f/BLOCK_SIZE).ceil
  end
  
  def file_size
    @meta_info.total_size
  end
  
  def last_piece_size 
    file_size - (piece_size * (@meta_info.number_of_pieces - 1))
  end
  
  def num_blocks_in_piece
    (piece_size.to_f/BLOCK_SIZE).ceil
  end
  
  def num_full_blocks_in_last_piece
    num_full_blocks.remainder(num_blocks_in_piece)   
  end
  
  def last_piece?(index)
    index == @meta_info.number_of_pieces - 1
  end
end

