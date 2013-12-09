RubyTorrent
===========

A simple BitTorrent client in Ruby

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
