require 'net/http'
require 'digest/sha1'
require 'thread'
require 'ipaddr'
require 'socket'
require 'timeout'
require 'pp'

require_relative 'ruby_torrent/ruby-bencode/lib/bencode.rb'
require_relative 'ruby_torrent/client'
require_relative 'ruby_torrent/piece'
require_relative 'ruby_torrent/block'
require_relative 'ruby_torrent/file_handler'
require_relative 'ruby_torrent/meta_info'
require_relative 'ruby_torrent/block_request_scheduler'
require_relative 'ruby_torrent/block_request_process'
require_relative 'ruby_torrent/byte_array'
require_relative 'ruby_torrent/incoming_message_process'
require_relative 'ruby_torrent/tracker'
require_relative 'ruby_torrent/peer'
require_relative 'ruby_torrent/bitfield'
require_relative 'ruby_torrent/message'

client = Client.new(ARGV.first)
client.run!
client.join_threads
