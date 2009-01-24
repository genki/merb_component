module Merb
  module GlobalHelpers
    def h_up(*args) header(-1, *args) end
    def h_down(*args) header(1, *args) end
    def h_next(*args) header(0, *args) end

  private
    def header(level, label, options = {})
      @header_level ||= 1
      @header_level += level
      tag "h#{@header_level}", h(label), options
    end
  end
end
