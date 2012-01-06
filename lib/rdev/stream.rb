module DerParser
  class EndOfStream < Exception
  end

  # Apparently Ruby doesn't ship with a default stream implementation... or
  # I simply can't find it.
  #
  # This is a lazy stream.
  class Stream
    def next?
      raise "Not implemented for #{self.class.name}"
    end

    def next
      raise "Not implemented for #{self.class.name}"
    end

    def remaining
      raise "Not implemented for #{self.class.name}"
    end
  end

  class StringStream < Stream
    def initialize(str)
      @string = str
      @position = 0
    end

    def next?
      @position < @string.length
    end

    def next
      raise EndOfStream.new unless next?

      result = @string[@position]
      @position = @position + 1
      result
    end

    def raw
      @string.dup
    end

    def remaining
      StringStream.new(@string[@position .. -1])
    end
  end
end
