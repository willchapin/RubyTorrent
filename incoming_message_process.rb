class IncomingMessageProcess

  def initialize(message_queue, incoming_block_queue, piece_length)
    @incoming_block_queue = incoming_block_queue
    @piece_length = piece_length

    loop do
      process_message(message_queue.pop)
    end
  end

  def process_message(message)
    puts "Peer #{message.peer.id} has sent you a #{message.type} message"
    if message.type == :piece
      piece_index, byte_offset, block_data = split_piece_payload(message.payload)
      output.push(Block.new(piece_index, byte_offset, block_data, @piece_length))
    elsif message.type == :choking
      message.peer.state[:is_choking] = true
    elsif message.type == :unchoke
      message.peer.state[:is_choking] = false
    elsif message.type == :not_interested
      message.peer.state[:is_interested] = false
    elsif message.type == :interested
      message.peer.state[:is_interested] = true
    elsif message.type == :have
      message.peer.bitfield.have_piece(message.payload.unpack("N")[0])
      puts "have #{message.peer.bitfield}"
    end
  end

  private

  def split_piece_payload(payload)
    piece_index = payload.slice!(0..3).unpack("N")[0]
    byte_offset = payload.slice!(0..3).unpack("N")[0]
    block_data = payload
    [piece_index, byte_offset, block_data]
  end

end
