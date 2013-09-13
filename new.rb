require 'net/http'
require 'digest/sha1'
require 'ipaddr'
require 'socket'
require 'timeout'
require_relative 'ruby-bencode/lib/bencode.rb'
require_relative 'client'
require_relative 'tracker'
require_relative 'peer'
require_relative 'bitfield'

my_cly = Client.new(ARGV.first)
