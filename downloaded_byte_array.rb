class DownloadedByteArray

  def initialize(meta_info)
    @length = meta_info.total_size
    @byte_table = Array.new([[0, @length - 1, false]])
  end

  def have_all(start, fin)
    check_range(start,fin)
    start_item, end_item = get_boundry_items
    first, second, third = nil

    if start_item[2] and end_item[2]
      first = [start_item[0], end_item[1], true]
    elsif start_item[2]
      first = [start_item[0], fin, start_item[2]]
      second = [fin + 1, end_item[1], end_item[2]]
    elsif end_item[2]
      first = [start_item[0], start - 1, start_item[2]]
      second = [start, end_item[1], true]
    else
      first = [start_item[0], start - 1, start_item[2]]
      second = [start, fin, true]
      third = [fin + 1, end_item[1], end_item[2]]
    end

    first = nil if start == 0
    third = nil if fin == @length - 1

    @byte_table[start_index..end_index] = [first, second, third].compact
    @byte_table
  end

  def get_boundry_items
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
      unless bool
        if intersect?(start, fin, i, j)
          return false
        end
      end
    end
    true
  end

  def intersect?(start, fin, i, j)
    !((start..fin).to_a & (i..j).to_a).empty?
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
