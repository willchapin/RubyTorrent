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
    request_scheduler
    incoming_block_process
  end

  def request_scheduler
    requests = []

    0.upto(num_pieces - 2).each do |piece_num|
      0.upto(num_blocks_in_piece - 1).each do |block_num|
        requests.push(create_request(@peers.sample.connection,
                                     piece_num,
                                     BLOCK_SIZE * block_num,
                                     BLOCK_SIZE))
      end
    end

    # last piece
    0.upto(num_full_blocks_in_last_piece - 1) do |block_num|
      requests.push(create_request(@peers.sample.connection,
                                   num_pieces - 1,
                                   BLOCK_SIZE * block_num,
                                   BLOCK_SIZE))
    end

    # last block
    requests.push(create_request(@peers.sample.connection,
                                 num_pieces - 1,
                                 BLOCK_SIZE * num_full_blocks_in_last_piece,
                                 last_block_size))

    requests.shuffle.each { |request| @block_request_queue.push(request) }
  end

  def incoming_block_process
    loop do
      block = @incoming_block_queue.pop
      @file_handler.process_block(block)
    end
  end

  private

    def create_request(connection, index, offset, size)
      { connection: connection, index: index, offset: offset, size: size }
    end
end
