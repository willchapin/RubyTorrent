class IncomingMessageProcess

  def initialize(message_queue, incoming_block_queue, metainfo)
    @incoming_block_queue = incoming_block_queue
    @metainfo = metainfo

    loop do
      process_message(message_queue.pop)
    end
  end

  def process_message(message)
    puts "Peer #{message.peer.id} has sent you a #{message.type} message"
    send(message.type, message)
  end

  def keep_alive(message)
  end

  def choking(message)
    message.peer.state[:is_choking] = true
  end

  def unchoke(message)
    message.peer.state[:is_choking] = false
  end

  def not_interested(message)
    message.peer.state[:is_interested] = false
  end

  def interested(message)
    message.peer.state[:is_interested] = true
  end

  def have(message)
    puts "have"
    message.peer.bitfield.have_piece(message.payload.unpack("N")[0])
    puts message.peer.bitfield
  end

  def bitfield(message)
  end

  def request(message)
  end

  # A piece is really a block, not a whole piece.
  def piece(message)
    piece_index, byte_offset, block_data = split_piece_payload(message.payload)
    puts @metainfo.class
    @incoming_block_queue.push(Block.new(piece_index, byte_offset, block_data, @metainfo.piece_length))
  end

  def cancel(message)
  end

  # needed for DHT implementation
  def port(message)
  end

  def split_piece_payload(payload)
    piece_index = payload.slice!(0..3).unpack("N")[0]
    byte_offset = payload.slice!(0..3).unpack("N")[0]
    block_data = payload
    [piece_index, byte_offset, block_data]
  end

end
