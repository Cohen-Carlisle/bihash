class Bihash
  def initialize(hash)
    @forward = hash
    @backward = hash.invert
  end

  def [](key)
    @forward[key] || @backward[key]
  end
end
