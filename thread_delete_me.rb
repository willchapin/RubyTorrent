def one
  1.upto(20).each { puts "one"; sleep(0.8) }
end

def two
  1.upto(20).each { puts "two"; sleep(1) }
end

t1 = Thread.new { one }
t2 = Thread.new { two }

Thread.list.each { |t| puts t.inspect }

t1.join
t2.join