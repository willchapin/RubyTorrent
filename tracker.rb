require 'uri'

class Tracker
  
  attr_accessor 
  
  def initialize(uri_string)
    @uri = URI(uri_string)
  end
  
  def make_request(params)
    request = @uri
    request.query = URI.encode_www_form(params)
    BEncode.load(Net::HTTP.get_response(request).body)
  end

end