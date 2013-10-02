require 'uri'

class Tracker
  
  attr_accessor :response 
  
  def initialize(uri_string)
    @uri = URI(uri_string)
  end
  
  def make_request(params)
    request = @uri
    request.query = URI.encode_www_form(params)
    temp = Net::HTTP.get_response(request).body
    puts temp
    @response = BEncode.load(temp)
    
  end

end