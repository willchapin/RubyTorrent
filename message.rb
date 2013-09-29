class Message
  
  attr_accessor :length, :id, :payload
  
  def initialize(length, id, payload)
    @length = length
    @id = id
    @payload = payload
  end
  
  def self.has_payload?(id)
    # message ids associated payload
    /[456789]/.match(id)
  end
  
  def self.parse_stream(peer)
    
    loop do
      # maybe ternary assignments hard to read?
      length = peer.connection.read(4).unpack("N")[0]
      id = length.zero? ? "-1" : peer.connection.readbyte.to_s
      payload = has_payload?(id) ? peer.connection.read(length - 1) : nil
      peer.queue << self.new(length, id, payload)
      puts peer.queue.inspect
      puts "\n"
    end
    
  end


#  MESSAGE_IDS = { 
#     "-1" => "keep alive",
#     "0"  => "choke",
#     "1"  => "unchoke",
#     "2"  => "interested",
#     "3"  => "not interested",
#     "4"  => "have",
#     "5"  => "bitfield",
#     "6"  => "request",
#     "7"  => "piece",
#     "8"  => "cancel"
#  }


#  def build_message
#    case @type
#    when MESSAGE_IDS["-1"]
#      build_keep_alive
#    when MESSAGE_IDS["0"]
#      build_choke
#    when MESSAGE_IDS["1"]
#      build_unchoke
#    when MESSAGE_IDS["2"]
#      build_interested
#    when MESSAGE_IDS["3"]
#      build_not_interested
#    when MESSAGE_IDS["4"]
#      build_have
#    when MESSAGE_IDS["5"]
#      build_bitfield
#    when MESSAGE_IDS["6"]
#      build_request
#    when MESSAGE_IDS["7"]
#      build_piece
#    when MESSAGE_IDS["8"]
#      build_cancel
#  end
  
#  def build_interested
#    length = "\0\0\0\1"
#    id = "\2"
#    @binary_data = length + id
#  end

end