class IncomingRequestProcess

  def initialize(message_queue, incoming_block_queue)
    @incoming_block_queue = incoming_block_queue
    @message_queue = message_queue
  end
  
  def run!
    loop do
      message = @message_queue.pop
      process_message(message)
    end
  end
  
  def process_message(message)
    case message.id
    when "-1"
      # TODO: keep-alive
      puts "keep alive!"
    when "0"
      message.peer.state[:is_choking] = true
      puts "is chokeing"
    when "1"
      message.peer.state[:is_choking] = false
      puts "not choking"
    when "2"
      message.peer.state[:is_interested] = false
      puts "is not interested"
    when "3"
      message.peer.state[:is_interested] = true
      puts "is interested"
    when "4"
      # TODO: have message
      puts "have"
    when "5"
      # bitfield - currently handled in peer initialization
      puts "bitfield"
    when "6"
      # TODO: request
      puts "request"
    when "7"
      puts "block: " + message.print
      push_to_block_queue(message.payload)
    when "8"
      puts "cancel"
      # TODO - Cancel - cancels block requests. Used if the same 
      # block is being downloaded from multiple peers, after block
      # is successfully downloaded, cancel transfers from other peers
    when "9"
      puts "port"
      # Port - enable for DTH tracker
    end
  end
  
  def push_to_block_queue(payload)
    piece_index, byte_offset, block_data = split_piece_payload(payload)
    @incoming_block_queue.push({ piece_index: piece_index,
                                 byte_offset: byte_offset,
                                 block_data: block_data
                                 })
  end
  
  def split_piece_payload(payload)
    piece_index = payload.slice!(0..3).unpack("N")[0]
    byte_offset = payload.slice!(0..3).unpack("N")[0]
    block_data = payload
    [piece_index, byte_offset, block_data]
  end

end