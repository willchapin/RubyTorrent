RubyTorrent
===========

A simple BitTorrent client in Ruby. This client can download single- or multi-file torrents from multiple peers concurrently.

INSTALL
----
Clone RubyTorrent locally.
CD into the RubyTorrent directory and run the following commands:

```
git submodule init
git submodule update
```

RUN
----
To download a file using RubyTorrent, run the following from the root directory:

```
ruby lib/ruby_torrent.rb path/to/torrent_file 
```

The downloaded file will be placed in RubyTorrent/downloads/

REQUIREMENTS
----
Ruby 2.0 \n
The torrent file must have a reference to a tracker. DTH torrent files are not yet supported.
