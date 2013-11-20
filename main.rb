require 'net/http'
require 'digest/sha1'
require 'thread'
require 'ipaddr'
require 'socket'
require 'timeout'
require 'pp'

require_relative 'ruby-bencode/lib/bencode.rb'
require_relative 'client'
require_relative 'piece'
require_relative 'block'
require_relative 'file_handler'
require_relative 'meta_info'
require_relative 'block_request_queue_creator'
require_relative 'block_request_process'
require_relative 'byte_array'
require_relative 'incoming_message_process'
require_relative 'tracker'
require_relative 'peer'
require_relative 'bitfield'
require_relative 'message'

client = Client.new(ARGV.first)
client.run!
client.join_threads
