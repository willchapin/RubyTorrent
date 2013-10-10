class FileWrapper
  
  attr_accessor :file, :info, :index
  
  def initialize(file, info, index)
    @file = file
    @info = info
    @index = index
  end
end