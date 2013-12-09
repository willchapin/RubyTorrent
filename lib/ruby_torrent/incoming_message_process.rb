class IncomingMessageProcess
  def initialize(piece_length)
    @piece_length = piece_length
  end

  def pipe(message, output)
    puts "Peer #{message.peer.id} has sent you a #{message.type} message"
    if message.type == :piece
      piece_index, byte_offset, block_data = split_piece_payload(message.payload)
      block = Block.new(piece_index,
                        byte_offset,
                        block_data,
                        @piece_length,
                        message.peer)
      remove_from_pending(block)
      output.push(block)
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

  def remove_from_pending(block)
    peer = block.peer
    peer.pending_requests.delete_if do |req|
      if req
        req[:index] == block.piece_index and
        req[:offset] == block.offset
      end
    end
  end
  
  def split_piece_payload(payload)
    piece_index = payload.slice!(0..3).unpack("N")[0]
    byte_offset = payload.slice!(0..3).unpack("N")[0]
    block_data = payload
    [piece_index, byte_offset, block_data]
  end

end
