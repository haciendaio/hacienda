require_relative 'content_handler'
module Hacienda
  class EnsureIdHandler < ContentHandler

    protected

    def do_process(data, query)
      data[:id] = query.id unless data[:id]
    end

  end

end