class DownloadedByteArray

  def initialize(meta_info)
    # @length = meta_info.total_size
    @length = 100
    # @sparse_bytes = Array.new([[0, @length - 1, false]])
    @sparse_bytes = Array.new([[0, 99, false]])
  end
  
  def have_all(start, fin)
    check_range(start,fin)    
    start_index = nil
    end_index = nil
    @sparse_bytes.each_with_index do |element, index|
      start_index = index if start.between?(element[0],element[1])
      end_index = index if fin.between?(element[0],element[1])
    end
    
    #puts "start " + start_index.to_s
    #puts "end " + end_index.to_s
    
    #breaks at boundries!
    
    if @sparse_bytes[start_index][2] and @sparse_bytes[end_index][2]
      puts "un"
      first = [@sparse_bytes[start_index][0], @sparse_bytes[end_index][1], true]
      @sparse_bytes[start_index..end_index] = [first]
    elsif @sparse_bytes[start_index][2]
      puts 'dos'
      first = [@sparse_bytes[start_index][0], fin, @sparse_bytes[start_index][2]]
      second = [fin + 1, @sparse_bytes[end_index][1], @sparse_bytes[end_index][2]]
      @sparse_bytes[start_index..end_index] = [first, second]
    elsif @sparse_bytes[end_index][2]
      puts "tres"
      first = [@sparse_bytes[start_index][0], start - 1, @sparse_bytes[start_index][2]]
      second = [start, @sparse_bytes[end_index][1], true]
      @sparse_bytes[start_index..end_index] = [first, second]
    else
      puts "qua"
      first = [@sparse_bytes[start_index][0], start - 1, @sparse_bytes[start_index][2]]
      second = [start, fin, true]
      third = [fin + 1, @sparse_bytes[end_index][1], @sparse_bytes[end_index][2]]
      @sparse_bytes[start_index..end_index] = [first, second, third]
    end   
    @sparse_bytes
  end
  
  def have_all?(start, fin)
    check_range(start,fin)
    result = true
    @sparse_bytes.each do |i, j, bool|
      if !bool
        if intersect?(start, fin, i, j)
          result = false
        end     
      end
    end
    result
  end
  
  def intersect?(start, fin, i, j)
    !((start..fin).to_a & (i..j).to_a).empty?
  end
  
  def check_range(start,fin)
    if start < 0 or fin < 0 or 
                     start > @length - 1 or
                     fin > @length - 1
      raise "Byte Array: out of range" 
    end
  end
end
