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
      default_value(key)
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
      default_value(nil)
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
      default_value(args[0])
    else
      raise ArgumentError, "wrong number of arguments (#{args.size} for 0..1)"
    end
  end

  def default=(default)
    raise_error_if_frozen
    @default_proc = nil
    @default = default
  end

  def default_proc
    @default_proc
  end

  def default_proc=(arg)
    raise_error_if_frozen
    if !arg.nil?
      if !arg.is_a?(Proc)
        raise TypeError, "wrong default_proc type #{arg.class} (expected Proc)"
      end
      if arg.lambda? && arg.arity != 2
        raise TypeError, "default_proc takes two arguments (2 for #{arg.arity})"
      end
    end
    @default = nil
    @default_proc = arg
  end

  def replace(other_bh)
    raise_error_if_frozen
    if !other_bh.is_a?(Bihash)
      raise TypeError, "wrong replace type #{other_bh.class} (expected Bihash)"
    end
    @forward = other_bh.instance_variable_get(:@forward).dup
    @reverse = other_bh.instance_variable_get(:@reverse).dup
    self
  end

  def compare_by_identity
    @forward.compare_by_identity
    @reverse.compare_by_identity
    self
  end

  def delete_if(&block)
    if block_given?
      raise_error_if_frozen
      @forward.each { |k,v| delete(k) if block.call(k,v) }
      self
    else
      @forward.delete_if
    end
  end

  def keep_if(&block)
    if block_given?
      raise_error_if_frozen
      @forward.each { |k,v| delete(k) if !block.call(k,v) }
      self
    else
      @forward.delete_if
    end
  end

  def select!(&block)
    if block_given?
      raise_error_if_frozen
      old_size = size
      @forward.each { |k,v| delete(k) if !block.call(k,v) }
      old_size == size ? nil : self
    else
      @forward.delete_if
    end
  end

  def reject!(&block)
    if block_given?
      raise_error_if_frozen
      old_size = size
      @forward.each { |k,v| delete(k) if block.call(k,v) }
      old_size == size ? nil : self
    else
      @forward.delete_if
    end
  end

  def_delegator :@forward, :empty?
  def_delegator :@forward, :length
  def_delegator :@forward, :size
  def_delegator :@forward, :flatten
  def_delegator :@forward, :compare_by_identity?

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

  def default_value(key)
    @default_proc ? @default_proc.call(self, key) : @default
  end
end
