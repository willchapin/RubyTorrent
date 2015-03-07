module Utils

  def join_threads
    Thread.list.each { |thread| thread.join unless current_thread?(thread) }
  end

  def current_thread?(thread)
    thread == Thread.current
  end

end

