require 'forwardable'

class Bihash
  extend Forwardable

  def_delegators :@hash, :[], :empty?

  def initialize(hash={})
    if hash.values.uniq.count != hash.keys.count
      raise ArgumentError, "Hash #{hash} contains duplicate values"
    end
    @hash = hash.invert.merge(hash)
  end

  def []=(key1, key2)
    delete(key1)
    delete(key2)
    @hash[key2] = key1
    @hash[key1] = key2
  end

  def delete(key)
    if @hash.key?(key)
      @hash.delete(@hash[key])
      @hash.delete(key)
    end
  end
end
