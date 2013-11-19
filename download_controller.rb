require_relative 'helpers'

class DownloadController

  require 'matrix'
  include Helpers # worryingly vague name

  BLOCK_SIZE = 2**14

  def initialize(metainfo, block_request_queue, incoming_block_queue, peers)
    @metainfo = metainfo
    @block_request_queue = block_request_queue
    @incoming_block_queue = incoming_block_queue
    @peers = peers
    @byte_array = ByteArray.new(@metainfo)
    @file_handler = FileHandler.new(@metainfo, @byte_array)
  end

  def run!
    Thread::abort_on_exception = true
    Thread.new { incoming_block_process }
    Thread.new { request_scheduler }
  end

  def request_scheduler
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
    requests.shuffle!
    requests.each { |request| @block_request_queue.push(request) }

  end

  def incoming_block_process
    loop do
      block = @incoming_block_queue.pop
      @file_handler.process_block(block)
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
