module Hacienda
  class ContentHandler

  def process!(data, query)
    do_process(data, query) if handles?(query)
  end

  protected

  def do_process(data, query); end

  def handles?(query)
    true
  end

  end
end
