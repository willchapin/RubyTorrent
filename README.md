RubyTorrent
===========

A simple BitTorrent client in Ruby.<br>
This client can download single- or multi-file torrents from multiple peers concurrently.

INSTALL
----
Clone RubyTorrent locally.<br>
CD into the RubyTorrent directory and run the following commands:

```
git submodule init
git submodule update
```

RUN
----
To download a file using RubyTorrent, run the following from the root directory:

```
ruby lib/ruby_torrent.rb <path/to/torrent_file> <path/to/downloads_folder> 
```
Example:
```
ruby lib/ruby_torrent.rb test_torrents/flagfromserver.torrent downloads/
```


REQUIREMENTS
----
Ruby 2.0 <br>
The torrent file must have a reference to a tracker. DTH torrent files are not yet supported.
