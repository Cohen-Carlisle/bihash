class Bihash
  def initialize(hash={})
    if (hash.keys | hash.values).count != hash.keys.count * 2
      raise ArgumentError, "Converting #{hash} to Bihash creates duplicate keys"
    end
    @forward = hash
    @backward = hash.invert
  end

  def [](key)
    @forward.has_key?(key) ? @forward[key] : @backward[key]
  end

  def []=(key1, key2)
    @forward[key1] = key2
    @backward[key2] = key1
  end

  def empty?
    @forward.empty?
  end
end
