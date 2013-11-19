class DownloadController
  
  require 'matrix'
  include Helpers
  
  BLOCK_SIZE = 2**14
  
  def initialize(metainfo, block_request_queue, incoming_block_queue, peers)
    @metainfo = metainfo
    @block_request_queue = block_request_queue
    @incoming_block_queue = incoming_block_queue
    @peers = peers
    @byte_array = ByteArray.new(@metainfo)
    @file_handler = FileHandler.new(@metainfo, @byte_array)
    @remaining_requests = Queue.new
  end
  
  def run!
    Thread::abort_on_exception = true
    assemble_requests
    initiate_requests
    incoming_block_process
  end
  
  def get_piece(index)
    return get_last_piece if index == num_pieces - 1
    make_initial_requests(index)
  #  until # piece is finished
  #  end    
  end

  def assemble_requests
    
    0.upto(num_pieces - 2).each do |piece_num|
      0.upto(num_blocks_in_piece - 1).each do |block_num|
        @remaining_requests.push({ index: piece_num, offset: BLOCK_SIZE * block_num, size: BLOCK_SIZE })
      end
    end
    
    # last piece
    0.upto(num_full_blocks_in_last_piece - 1) do |block_num|
      @remaining_requests.push({ index: num_pieces - 1, offset: BLOCK_SIZE * block_num, size: BLOCK_SIZE })
    end
    
    # last block
    @remaining_requests.push({ index: num_pieces - 1, offset: BLOCK_SIZE * num_full_blocks_in_last_piece, size: last_block_size })

  end

  def initiate_requests
    @peers.each do |peer|
      20.times do
        request = @remaining_requests.pop
        peer.pending_requests << request
        @block_request_queue.push({ connection: peer.connection, index: request[:index], offset: request[:offset], size: request[:size]})
      end
    end
  end
  
  def make_initial_requests(piece_index)
    0.upto(num_blocks_in_piece - 1).each do |block_num|
      peer = @peers.sample
      start_byte = piece_index * piece_size + BLOCK_SIZE * block_num
      @block_request_queue.push({ connection: peer.connection, index: piece_index, offset: BLOCK_SIZE * block_num, size: BLOCK_SIZE })
      peer.pending_requests << { start_byte: start_byte }
    end
  end

  def get_last_piece
    0.upto(num_full_blocks_in_last_piece - 1) do |block_num|
      peer = @peers.sample
      start_byte = ((num_pieces - 1) * piece_size) + (BLOCK_SIZE * block_num)
      @block_request_queue.push({ connection: peer.connection, index: num_pieces - 1, offset: BLOCK_SIZE * block_num, size: BLOCK_SIZE })
      peer.pending_requests << { start_byte: start_byte }
    end

    # get last block
    peer = @peers.sample
    start_byte = ((num_pieces - 1) * piece_size) + (BLOCK_SIZE * num_full_blocks_in_last_piece) 
    @block_request_queue.push({ connection: peer.connection, index: num_pieces - 1, offset: BLOCK_SIZE * num_full_blocks_in_last_piece, size: last_block_size })
    peer.pending_requests << { start_byte: start_byte }
  end

  def request_scheduler

    # request one piece at a time, wait to request the next piece
    # until that one piece is finished.


    0.upto(num_pieces - 1).each {|n| get_piece(n)}


   # until done?
   #   rarest_piece_index = sorted_piece_indices[0]
   #   puts "rarest piece index: #{rarest_piece_index} !!!!"
   #   get_piece(rarest_piece_index)
   # end  
  end
  
  def incoming_block_process
    loop do
      block = @incoming_block_queue.pop
      ##check to see if peer has less than 20 pending requests
      ##make requests
      puts "block from #{block.peer}"
      puts block.peer.pending_requests.length
      remove_from_pending(block)
      @file_handler.process_block(block)
    end
  end
  
  def remove_from_pending(block)
    peer = block.peer
    peer.pending_requests.delete_if do |request|
      request[:index] == block.piece_index
      request[:offset] == block.offset
    end
  end
  
  private
    def sorted_piece_indices
      # refactor? super confusing? exceptionally unclear?
      bitfield_sum = @peers.map { |peer| Matrix[peer.bitfield.bits] }.reduce(:+).to_a.flatten
      piece_list = remove_finished_pieces(bitfield_sum)
      sort_by_index(piece_list)
    end
  
    def sort_by_index(piece_list)
      piece_list.map.with_index.sort_by(&:first).map(&:last)
    end
  
    def remove_finished_pieces(bitfield_sum)
      (0...num_pieces).map { |i| (@piece_verification_table[i] - 1).abs * bitfield_sum[i] }
    end
end

