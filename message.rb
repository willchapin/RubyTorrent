class Message
  
  MESSAGE_IDS = { 
    -1: "keep alive",
     0: "choke",
     1: "unchoke",
     2: "interested",
     3: "not interested",
     4: "have",
     5: "bitfield",
     6: "request",
     7: "piece",
     8: "cancel"
  }
  
  attr_accessor :type, :length, :payload
  
  def initailize(id, length, payload)
    @length = connection.read(4).unpack("N")[0]
    @id = connection.read(1).bytes
    get_payload
  end
  
  def get_payload
    @payload = connection.read(@length - 1) unless @length < 0
  end
  
  

end