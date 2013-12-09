class Peer
  
  attr_accessor :connection, :bitfield, :state, :id, :pending_requests

  def initialize(ip_string, port, handshake, correct_info_hash)
    @pending_requests = []
    @connection = TCPSocket.new(IPAddr.new_ntoh(ip_string).to_s, port)
    @state = { is_choking: true, is_choked: true, is_interested: false, is_interesting: false }
    @correct_info_hash = correct_info_hash
    greet(handshake)
    set_bitfield
  end
  
  def greet(handshake)
    @connection.write(handshake)
    set_initial_response
    verify_initial_response
    @id = @initial_response[:peer_id]
  end
  
  def set_initial_response
    pstrlen = @connection.getbyte
    @initial_response = { 
       pstrlen:   pstrlen,
       pstr:      @connection.read(pstrlen),
       reserved:  @connection.read(8),
       info_hash: @connection.read(20),
       peer_id:   @connection.read(20)
    }
  end
  
  def verify_initial_response
    disconnect unless @initial_response[:info_hash] == @correct_info_hash
  end
  
  def disconnect
    self.connection.close
  end
  
  def set_bitfield
    length = @connection.read(4).unpack("N")[0]
    message_id = @connection.read(1).bytes[0]
    if message_id == 5
      @bitfield = Bitfield.new(@connection.read(length - 1).unpack("B8" * (length - 1)))
    else
      puts "no bitfield!"
      @bitfield = nil
    end
  end
  
end
