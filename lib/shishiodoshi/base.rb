module Shishiodoshi
  class Base
    def initialize(id:, flushed_at:, max_items: )
      @id = id
      @flushed_at = flushed_at
      @max_items = max_items
      @items = []
    end

    def push(notification)
      items.push(notification)
    end

    def flush!
      self.items = []
    end

    def flush?
      full? || expired?
    end

    def full?
      items.count >= @max_items
    end

    def expired?
      Time.now > @flushed_at
    end

    private

    attr_accessor :items
  end
end
