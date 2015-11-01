require 'forwardable'

class Bihash
  include Enumerable
  extend Forwardable

  def initialize(*args, &block)
    raise_error_if_frozen
    if block_given? && !args.empty?
      raise ArgumentError, "wrong number of arguments (#{args.size} for 0)"
    elsif args.size > 1
      raise ArgumentError, "wrong number of arguments (#{args.size} for 0..1)"
    end
    super()
    @forward, @reverse = Hash.new, Hash.new
    @default, @default_proc = args[0], block
  end

  def self.[](*args)
    new_from_hash(Hash[*args])
  end

  def self.try_convert(arg)
    h = Hash.try_convert(arg)
    h ? self[h] : nil
  end

  def [](key)
    if key?(key)
      @forward.key?(key) ? @forward[key] : @reverse[key]
    else
      get_default(key)
    end
  end

  def []=(key1, key2)
    raise_error_if_frozen
    delete(key1)
    delete(key2)
    @reverse[key2] = key1
    @forward[key1] = key2
  end
  alias :store :[]=

  def delete(key, &block)
    raise_error_if_frozen
    if @forward.key?(key)
      @reverse.delete(@forward[key])
      @forward.delete(key)
    elsif @reverse.key?(key)
      @forward.delete(@reverse[key])
      @reverse.delete(key)
    else
      @reverse.delete(key, &block)
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
  alias :each_pair :each

  def ==(rhs)
    rhs.is_a?(self.class) && rhs.instance_variable_get(:@forward) == @forward
  end
  alias :eql? :==

  def key?(arg)
    @forward.key?(arg) || @reverse.key?(arg)
  end
  alias :has_key? :key?
  alias :include? :key?
  alias :member? :key?

  def fetch(key)
    @forward.key?(key) ? @forward.fetch(key) : @reverse.fetch(key)
  end

  def clear
    raise_error_if_frozen
    @forward.clear
    @reverse.clear
    self
  end

  def rehash
    raise_error_if_frozen
    @forward.rehash
    @reverse.rehash
    self
  end

  def to_h
    @forward.dup
  end
  alias :to_hash :to_h

  def values_at(*keys)
    keys.map { |key| self[key] }
  end

  def shift
    raise_error_if_frozen
    if empty?
      get_default(nil)
    else
      @reverse.shift
      @forward.shift
    end
  end

  def assoc(key)
    @forward.assoc(key) || @reverse.assoc(key)
  end

  def to_s
    "Bihash[#{@forward.to_s[1..-2]}]"
  end
  alias :inspect :to_s

  def hash
    self.class.hash ^ @forward.hash
  end

  def select(&block)
    if block_given?
      self.class[@forward.select(&block)]
    else
      @forward.select
    end
  end

  def reject(&block)
    if block_given?
      self.class[@forward.reject(&block)]
    else
      @forward.reject
    end
  end

  def default(*args)
    case args.count
    when 0
      @default
    when 1
      get_default(args[0])
    else
      raise ArgumentError, "wrong number of arguments (#{args.size} for 0..1)"
    end
  end

  def_delegators :@forward, :empty?, :length, :size, :flatten

  def self.new_from_hash(h)
    if (h.keys | h.values).size + h.select { |k,v| k == v }.size < h.size * 2
      raise ArgumentError, 'A key would be duplicated outside its own pair'
    end
    bihash = new
    bihash.instance_variable_set(:@reverse, h.invert)
    bihash.instance_variable_set(:@forward, h)
    bihash
  end
  private_class_method :new_from_hash

  private

  def initialize_copy(source)
    super
    @forward, @reverse = @forward.dup, @reverse.dup
  end

  def raise_error_if_frozen
    raise "can't modify frozen Bihash" if frozen?
  end

  def get_default(key)
    @default_proc ? @default_proc.call(self, key) : @default
  end
end
