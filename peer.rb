class Peer
  
  attr_accessor :connection, :initial_response, :bitfield, :state

  def initialize(ip_string, port, handshake)
    @connection = TCPSocket.new(IPAddr.new_ntoh(ip_string).to_s, port)
    @state = { is_choking: true, is_choked: true, is_interested: false, is_interesting: false }
    greet(handshake)
    set_initial_response
    set_bitfield
  end
  
  def greet(handshake)
    @connection.write(handshake)
  end
  
  def set_initial_response
    # TODO: check info_hash against metainfo file
    # if mismatched, disconnect
    pstrlen = @connection.getbyte
    @initial_response = { 
       pstrlen:   pstrlen,
       pstr:      @connection.read(pstrlen),
       reserved:  @connection.read(8),
       info_hash: @connection.read(20),
       peer_id:   @connection.read(20)
    }
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
