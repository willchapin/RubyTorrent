class DownloadedByteArray

  def initialize(meta_info)
    @length = meta_info.total_size
    @byte_table = Array.new([[0, @length - 1, false]])
  end

  def have_all(start, fin)
    check_range(start,fin)
    start_item, end_item = boundry_items(start, fin)
    
    # so horrible
    start_index = @byte_table.index(start_item)
    end_index = @byte_table.index(end_item)

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
    
    @byte_table[start_index..end_index] = result.compact    
    consolidate!
    @byte_table
  end
  
  def consolidate!
    0.upto(@byte_table.length - 2).each do |n|
      if @byte_table[n][2] == @byte_table[n+1][2]
        @byte_table[n+1][0] = @byte_table[n][0]
        @byte_table[n] = nil 
      end
    end
    @byte_table.compact!
  end

  def boundry_items(start, fin)
    start_item, end_item = nil
    @byte_table.each_with_index do |element, index|
      start_item = @byte_table[index] if start.between?(element[0],element[1])
      end_item = @byte_table[index] if fin.between?(element[0],element[1])
    end
    [start_item, end_item]
  end

  def have_all?(start, fin)
    check_range(start, fin)
    @byte_table.each do |i, j, bool|
      if !bool
        if intersect?(start, fin, i, j)
          return false
        end
      end
    end
    true
  end

  def intersect?(start, fin, i, j)
    (start >= i and start <= j) or 
    (fin >= i and fin <= j)
  end
  
  def complete?
    @byte_table == [[0, @length - 1, true]]
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
