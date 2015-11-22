require 'forwardable'

class Bihash
  include Enumerable
  extend Forwardable

  def self.[](*args)
    new_from_hash(Hash[*args])
  end

  def self.try_convert(arg)
    h = Hash.try_convert(arg)
    h && new_from_hash(h)
  end

  def ==(rhs)
    rhs.is_a?(self.class) && rhs.send(:merged_hash_attrs) == merged_hash_attrs
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

  def assoc(key)
    @forward.assoc(key) || @reverse.assoc(key)
  end

  def clear
    raise_error_if_frozen
    @forward.clear
    @reverse.clear
    self
  end

  def compare_by_identity
    raise_error_if_frozen
    @forward.compare_by_identity
    @reverse.compare_by_identity
    self
  end

  def_delegator :@forward, :compare_by_identity?

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

  attr_reader :default_proc

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

  def delete_if(&block)
    if block_given?
      raise_error_if_frozen
      @forward.each { |k,v| delete(k) if block.call(k,v) }
      self
    else
      to_enum(:delete_if)
    end
  end

  def each(&block)
    if block_given?
      @forward.each(&block)
      self
    else
      to_enum(:each)
    end
  end

  alias :each_pair :each

  def_delegator :@forward, :empty?

  alias :eql? :==

  def fetch(key)
    @forward.key?(key) ? @forward.fetch(key) : @reverse.fetch(key)
  end

  def_delegator :@forward, :flatten

  def has_key?(arg)
    @forward.has_key?(arg) || @reverse.has_key?(arg)
  end

  def hash
    self.class.hash ^ merged_hash_attrs.hash
  end

  alias :include? :has_key?

  def inspect
    "Bihash[#{@forward.to_s[1..-2]}]"
  end

  def keep_if(&block)
    if block_given?
      raise_error_if_frozen
      @forward.each { |k,v| delete(k) if !block.call(k,v) }
      self
    else
      to_enum(:keep_if)
    end
  end

  alias :key? :has_key?

  def_delegator :@forward, :length

  alias :member? :has_key?

  def merge(other_bh)
    dup.merge!(other_bh)
  end

  def merge!(other_bh)
    raise_error_if_frozen
    raise_error_unless_bihash(other_bh)
    other_bh.each { |k,v| store(k,v) }
    self
  end

  def rehash
    raise_error_if_frozen
    @forward.rehash
    @reverse.rehash
    self
  end

  def reject(&block)
    if block_given?
      dup.delete_if(&block)
    else
      to_enum(:reject)
    end
  end

  def reject!(&block)
    if block_given?
      raise_error_if_frozen
      old_size = size
      @forward.each { |k,v| delete(k) if block.call(k,v) }
      old_size == size ? nil : self
    else
      to_enum(:reject!)
    end
  end

  def replace(other_bh)
    raise_error_if_frozen
    raise_error_unless_bihash(other_bh)
    @forward = other_bh.instance_variable_get(:@forward).dup
    @reverse = other_bh.instance_variable_get(:@reverse).dup
    self
  end

  def select(&block)
    if block_given?
      dup.keep_if(&block)
    else
      to_enum(:select)
    end
  end

  def select!(&block)
    if block_given?
      raise_error_if_frozen
      old_size = size
      @forward.each { |k,v| delete(k) if !block.call(k,v) }
      old_size == size ? nil : self
    else
      to_enum(:select!)
    end
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

  def_delegator :@forward, :size

  alias :store :[]=

  def to_h
    @forward.dup
  end

  alias :to_s :inspect

  alias :update :merge!

  def values_at(*keys)
    keys.map { |key| self[key] }
  end

  private

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

  def default_value(key)
    @default_proc ? @default_proc.call(self, key) : @default
  end

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

  def initialize_copy(source)
    super
    @forward, @reverse = @forward.dup, @reverse.dup
  end

  def merged_hash_attrs
    @reverse.merge(@forward)
  end

  def raise_error_if_frozen
    raise "can't modify frozen Bihash" if frozen?
  end

  def raise_error_unless_bihash(obj)
    unless obj.is_a?(Bihash)
      raise TypeError, "wrong argument type #{obj.class} (expected Bihash)"
    end
  end
end
