class Bihash
  def initialize(hash)
    if (hash.keys | hash.values).count != hash.keys.count * 2
      raise ArgumentError, "Converting #{hash} to Bihash creates duplicate keys"
    end
    @forward = hash
    @backward = hash.invert
  end

  def [](key)
    @forward[key] || @backward[key]
  end
end
