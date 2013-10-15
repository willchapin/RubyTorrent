class DownloadController
  
  require 'pry'
  require 'matrix'
  
  BLOCK_SIZE = 2**14
  
  def initialize(meta_info, block_request_queue, incoming_block_queue, peers)
    @meta_info = meta_info
    @piece_bitfield = "0" * (@meta_info.number_of_pieces)
    @pieces = []
    @block_request_queue = block_request_queue
    @incoming_block_queue = incoming_block_queue
    @peers = peers
    @verification_table = [0] * num_pieces
    calculate_sorted_piece_list
    @blocks_to_write = Queue.new
  end
  
  def run!
    Thread.new { FileWriterProcess.new(@blocks_to_write, @meta_info).run! } 
    Thread.new { push_to_block_request_queue }
    Thread.new { loop { process_block(@incoming_block_queue.pop) } }        
  end
  
  def push_to_block_request_queue
    piece = 0
    block_count = 0
    peer = @peers.last

    requests = [] 
    
    0.upto(num_pieces - 2).each do |piece_num|
      0.upto(num_blocks_in_piece - 1).each do |block_num|
        requests.push({ connection: peer.connection, index: piece_num, offset: BLOCK_SIZE * block_num, size: BLOCK_SIZE })
      end
    end
    
    # last piece
    0.upto(num_full_blocks_in_last_piece - 1) do |block_num|
      requests.push({ connection: peer.connection, index: num_pieces - 1, offset: BLOCK_SIZE * block_num, size: BLOCK_SIZE })
    end
    
    # last block
    requests.push({ connection: peer.connection, index: num_pieces - 1, offset: BLOCK_SIZE * num_full_blocks_in_last_piece, size: last_block_size })
    
    puts "# of requests = #{requests.length}"
    requests.shuffle!
    requests.each { |request| @block_request_queue.push(request) }
  
  end
  
  def process_block(block)
    
    puts block.inspect
    
    if new_piece?(block)
      make_new_piece(block)
    end
    
    piece = @pieces.find { |piece| piece.index == block.piece_index }
    piece.write_block(block)
    
    @blocks_to_write.push(block)
    
    if piece.is_complete?
      puts "piece #{piece.index} (#{piece.size} bytes) has been downloaded"
      if piece.is_verified?
        puts "piece #{piece.index} (#{piece.size} bytes) has been verified"
        @verification_table[piece.index] = 1
        calculate_sorted_piece_list
      end
    end
  end

  def new_piece?(block)
    @pieces.none? { |piece| piece.index == block.piece_index }
  end 

  def make_new_piece(block)
        
    if last_piece?(block.piece_index)
      size = last_piece_size
    else
      size = @meta_info.piece_length
    end
    
    hash_begin_index = block.piece_index * 20
    hash_end_index = hash_begin_index + 20
    @pieces << Piece.new(size,
                         block.piece_index,
                         @meta_info.pieces_hash[hash_begin_index...hash_end_index])
  end
  
  def calculate_sorted_piece_list
    # refactor?
    bit_sum = @peers.map { |peer| Matrix[peer.bitfield.bits] }.reduce(:+).to_a.flatten
    piece_list = remove_finished_pieces(bit_sum)
    sorted_piece_index = sort_by_index(piece_list)
  end
  
  def sort_by_index(piece_list)
    piece_list.map.with_index.sort_by(&:first).map(&:last)
  end
  
  def remove_finished_pieces(bit_sum)
    (0...num_pieces).map { |i| (@verification_table[i] - 1).abs * bit_sum[i] }
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

