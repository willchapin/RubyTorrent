class Message
  
  attr_accessor :peer, :length, :id, :payload
  
  def initialize(peer, length, id, payload)
    @peer = peer
    @length = length
    @id = id
    @payload = payload
  end
  
  def self.has_payload?(id)
    # message ids associated with payload
    /[456789]/.match(id)
  end
  
  def print
    "index: #{ self.payload[0..3].unpack("N")}, offset: #{self.payload[4..8].unpack("N") }"
  end
  
  def self.parse_stream(peer, message_queue)
    loop do      
        length = peer.connection.read(4).unpack("N")[0]
        id = length.zero? ? "-1" : peer.connection.readbyte.to_s
        payload = has_payload?(id) ? peer.connection.read(length - 1) : nil
        message_queue << self.new(peer, length, id, payload)
    end
  end
  
  
  
  def self.send_interested(peer)
    length = "\0\0\0\1"
    id = "\2"
    peer.connection.write(length + id) 
  end
end