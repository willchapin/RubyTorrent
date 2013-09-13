peers = ['aaaabb', 'ccccdd', 'eeeeff', 'gggghh']
peers.map! do |peer|
  peer.unpack('a4n')
end
peers.each do |ip, port| 
  puts ip.bytes
  puts port
end