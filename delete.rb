f = File.new("pic.jpg", "w")
f.close
f = File.open("pic.jpg", "r+")
f.seek 40
f.write "R"
f.seek 20
f.write "Wasfd"
f.close