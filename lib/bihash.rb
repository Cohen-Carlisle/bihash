class Bihash
  def initialize(hash={})
    if hash.values.uniq.length != hash.length
      raise ArgumentError, "Hash #{hash} contains duplicate values"
    end
    @reverse = hash.invert
    @forward = hash
  end

  def [](key)
    @forward.key?(key) ? @forward[key] : @reverse[key]
  end

  def []=(key1, key2)
    delete(key1)
    delete(key2)
    @reverse[key2] = key1
    @forward[key1] = key2
  end

  def delete(key)
    if @forward.key?(key)
      @reverse.delete(@forward[key])
      @forward.delete(key)
    elsif @reverse.key?(key)
      @forward.delete(@reverse[key])
      @reverse.delete(key)
    end
  end
end
