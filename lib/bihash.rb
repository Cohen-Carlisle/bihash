require 'forwardable'

class Bihash
  include Enumerable
  extend Forwardable

  def initialize(*args, &block)
    @reverse = Hash.new(*args, &block)
    @forward = Hash.new
  end

  def self.[](*args)
    new_from_hash(Hash[*args])
  end

  def self.try_convert(arg)
    h = Hash.try_convert(arg)
    h ? self[h] : nil
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

  def each(&block)
    if block_given?
      @forward.each(&block)
      self
    else
      @forward.each
    end
  end

  def ==(rhs)
    rhs.is_a?(self.class) && rhs.instance_variable_get(:@forward) == @forward
  end

  def_delegators :@forward, :empty?

  def self.new_from_hash(hash)
    if hash.values.uniq.length != hash.length
      raise ArgumentError, "Hash #{hash} contains duplicate values"
    end
    bihash = new
    bihash.instance_variable_set(:@reverse, hash.invert)
    bihash.instance_variable_set(:@forward, hash)
    bihash
  end
  private_class_method :new_from_hash

end
