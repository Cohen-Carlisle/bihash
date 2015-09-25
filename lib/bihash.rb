require 'forwardable'

class Bihash
  extend Forwardable

  def_delegators :@hash, :[], :empty?

  def initialize(hash={})
    if (hash.keys | hash.values).count != hash.keys.count * 2
      raise ArgumentError, "Converting #{hash} to Bihash creates duplicate keys"
    end
    @hash = hash.merge(hash.invert)
  end

  def []=(key1, key2)
    @hash[key2] = key1
    @hash[key1] = key2
  end
end
