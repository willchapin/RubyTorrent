class ByteArray

  def initialize(meta_info)
    @length = meta_info.total_size
#    @length = 100
    @bytes = Array.new([[0, @length - 1, false]])
  end

  def have_all(start, fin)
    check_range(start,fin)
    start_item, end_item = boundry_items(start, fin)
    
    # so horrible
    start_index = @bytes.index(start_item)
    end_index = @bytes.index(end_item)

    result = Array.new(3,nil)
    first, second, third = nil

    if start_item[2] and end_item[2]
      result[0] = [start_item[0], end_item[1], true]
    elsif start_item[2]
      result[0] = [start_item[0], fin, start_item[2]]
      result[1] = [fin + 1, end_item[1], end_item[2]]
    elsif end_item[2]
      result[0] = [start_item[0], start - 1, start_item[2]]
      result[1] = [start, end_item[1], true]
    else
      result[0] = [start_item[0], start - 1, start_item[2]]
      result[1] = [start, fin, true]
      result[2] = [fin + 1, end_item[1], end_item[2]]
    end

    # hacky edge case fix
        
    result.map! do |item|
      unless item.nil?
        item = nil if item[0] > item[1]
      end
      item
    end
    
    @bytes[start_index..end_index] = result.compact    
    consolidate!
    @bytes
  end
  
  def consolidate!
    0.upto(@bytes.length - 2).each do |n|
      if @bytes[n][2] == @bytes[n+1][2]
        @bytes[n+1][0] = @bytes[n][0]
        @bytes[n] = nil 
      end
    end
    @bytes.compact!
  end

  def boundry_items(start, fin)
    start_item, end_item = nil
    @bytes.each_with_index do |element, index|
      start_item = @bytes[index] if start.between?(element[0],element[1])
      end_item = @bytes[index] if fin.between?(element[0],element[1])
    end
    [start_item, end_item]
  end

  def have_all?(start, fin)
    check_range(start, fin)
    @bytes.each do |i, j, bool|
      if bool == false
        if intersect?(start, fin, i, j)
          return false
        end
      end
    end
    true
  end

  def intersect?(start, fin, i, j)
    start.between?(i, j)     ||
      fin.between?(i,j)      ||
      i.between?(start, fin) ||
      j.between?(start, fin)
  end
  
  def complete?
    @bytes == [[0, @length - 1, true]]
  end

  def check_range(start,fin)
    if start < 0 or
       fin < 0 or
       start > @length - 1 or
       fin > @length - 1 or
       start > fin
      raise "Byte Array: out of range"
    end
  end
end
