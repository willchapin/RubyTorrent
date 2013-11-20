require 'fileutils'

class FileHandler
  include FileUtils

  def initialize(metainfo)
    @metainfo = metainfo
    @byte_array = ByteArray.new(@metainfo)
    @temp_name = "temp/" + ('a'..'z').to_a.shuffle.take(10).join
    @file = init_file
  end

  def init_file
    make_dir("temp") unless File.directory?("temp")
    File.open(@temp_name, "w+")
    File.open(@temp_name, "r+")
  end

  def process_block(block)
    write_block(block)
    record_block(block)

    piece_start = @metainfo.pieces[block.piece_index].start_byte
    piece_end = @metainfo.pieces[block.piece_index].end_byte

    if @byte_array.have_all?(piece_start, piece_end)
      verify_piece(block.piece_index)
    end

    finish if @byte_array.complete?
  end

  def write_block(block)
    @file.seek(block.start_byte)
    @file.write(block.data)
  end

  def record_block(block)
    @byte_array.have_all(block.start_byte, block.end_byte)
  end

  def verify_piece(index)
    piece = @metainfo.pieces[index]
    if piece.hash == hash_from_file(piece)
      puts "piece #{index} verified!"
    else
      puts "piece #{index} verification FAILED!"
    end
  end

  def hash_from_file(piece)
    Digest::SHA1.new.digest(read(piece.start_byte, piece.length))
  end

  def read(start, length)
    @file.seek(start)
    @file.read(length)
  end

  def finish
    puts "finishing!"
    @file.close
    if @metainfo.is_multi_file?
      split_files
      remove_temp_file
    else
      move_file
    end
  end

  def split_files
    dir = "downloads/" + @metainfo.folder
    make_dir(dir) unless File.directory?(dir)
    File.open(@temp_name, "r") do |temp_file|
      @metainfo.files.each do |file_info|
        File.open(dir + "/" + file_info[:name], "w") do |out_file|
          out_file.write(temp_file.read(file_info[:length]))
        end
      end
    end
  end

  def move_file
    make_dir("downloads") unless File.directory?("downloads")
    FileUtils.mv(@temp_name, "downloads/" + @metainfo.files[0][:name])
  end

  def make_dir(dir)
    Dir.mkdir(dir)
  end

  def remove_temp_file
    File.delete(@temp_name)
  end
end
