module BlockRequestQueueCreator

  require 'matrix'

  BLOCK_SIZE = 2**14

  def self.create(peers, metainfo)
    requests = []

    0.upto(num_pieces(metainfo) - 2).each do |piece_num|
      0.upto(num_blocks_in_piece(metainfo) - 1).each do |block_num|
        requests.push(create_request(peers.sample.connection,
                                     piece_num,
                                     BLOCK_SIZE * block_num,
                                     BLOCK_SIZE))
      end
    end

    # last piece
    0.upto(num_full_blocks_in_last_piece(metainfo) - 1) do |block_num|
      requests.push(create_request(peers.sample.connection,
                                   num_pieces(metainfo) - 1,
                                   BLOCK_SIZE * block_num,
                                   BLOCK_SIZE))
    end

    # last block
    requests.push(create_request(peers.sample.connection,
                                 num_pieces(metainfo) - 1,
                                 BLOCK_SIZE * num_full_blocks_in_last_piece(metainfo),
                                 last_block_size(metainfo)))

    queue = Queue.new
    requests.shuffle.each { |request| queue.push(request) }
    queue
  end

  def self.create_request(connection, index, offset, size)
    { connection: connection, index: index, offset: offset, size: size }
  end

  def self.num_pieces(metainfo)
    (metainfo.total_size.to_f/metainfo.piece_length).ceil
  end

  def self.last_block_size(metainfo)
    metainfo.total_size.remainder(BLOCK_SIZE)
  end

  def self.num_full_blocks(metainfo)
    metainfo.total_size/BLOCK_SIZE
  end

  def total_num_blocks
    (@metainfo.total_size.to_f/BLOCK_SIZE).ceil
  end

  def last_piece_size
    file_size - (metainfo.piece_length * (metainfo.number_of_pieces - 1))
  end

  def self.num_blocks_in_piece(metainfo)
    (metainfo.piece_length.to_f/BLOCK_SIZE).ceil
  end

  def self.num_full_blocks_in_last_piece(metainfo)
    num_full_blocks(metainfo).remainder(num_blocks_in_piece(metainfo))
  end

  def total_num_blocks_in_last_piece(metainfo)
    self.num_full_blocks_in_last_piece(metainfo) + 1
  end
end
