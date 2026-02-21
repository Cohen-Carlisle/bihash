require 'forwardable'
require 'bihash/version'
require 'bihash/unimplemented_methods'

class Bihash
  include Enumerable
  extend Forwardable

  def self.[](*args)
    new_from_hash(Hash[*args])
  end

  def self.try_convert(arg)
    if arg.is_a?(self)
      arg
    else
      h = Hash.try_convert(arg)
      h && self[h]
    end
  end

  def <(rhs)
    raise_error_unless_bihash(rhs)
    size < rhs.size && subset?(rhs)
  end

  def <=(rhs)
    raise_error_unless_bihash(rhs)
    size <= rhs.size && subset?(rhs)
  end

  def ==(rhs)
    rhs.is_a?(self.class) &&
      size == rhs.size &&
      merged_hash_attrs.eql?(rhs.send(:merged_hash_attrs))
  end

  def >(rhs)
    raise_error_unless_bihash(rhs)
    size > rhs.size && rhs.send(:subset?, self)
  end

  def >=(rhs)
    raise_error_unless_bihash(rhs)
    size >= rhs.size && rhs.send(:subset?, self)
  end

  def [](key)
    if @forward.key?(key)
      @forward[key]
    elsif @reverse.key?(key)
      @reverse[key]
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

  def compact
    dup.tap { |d| d.compact! }
  end

  def compact!
    reject! { |k1, k2| k1.nil? || k2.nil? }
  end

  def compare_by_identity
    raise_error_if_frozen
    if illegal_state?(compare_by_id: true)
      raise 'Cannot set compare_by_identity while a key is duplicated outside its own pair'
    end
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

  def deconstruct_keys(_keys)
    merged_hash_attrs
  end

  def delete(key)
    raise_error_if_frozen
    if @forward.key?(key)
      @reverse.delete(@forward[key])
      @forward.delete(key)
    elsif @reverse.key?(key)
      @forward.delete(@reverse[key])
      @reverse.delete(key)
    else
      yield(key) if block_given?
    end
  end

  def delete_if
    if block_given?
      raise_error_if_frozen
      @forward.each { |k,v| delete(k) if yield(k,v) }
      self
    else
      to_enum(:delete_if)
    end
  end

  def dig(*keys)
    (@forward.key?(keys[0]) ? @forward : @reverse).dig(*keys)
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

  def except(*args)
    dup_without_defaults.tap do |bh|
      args.each do |arg|
        bh.delete(arg)
      end
    end
  end

  def fetch(key, *default, &block)
    (@forward.key?(key) ? @forward : @reverse).fetch(key, *default, &block)
  end

  def fetch_values(*keys, &block)
    keys.map { |key| fetch(key, &block) }
  end

  def filter(&block)
    if block_given?
      dup_without_defaults.tap { |d| d.select!(&block) }
    else
      to_enum(:select)
    end
  end

  def filter!(&block)
    if block_given?
      raise_error_if_frozen
      old_size = size
      keep_if(&block)
      old_size == size ? nil : self
    else
      to_enum(:select!)
    end
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

  def keep_if
    if block_given?
      raise_error_if_frozen
      @forward.each { |k,v| delete(k) unless yield(k,v) }
      self
    else
      to_enum(:keep_if)
    end
  end

  alias :key? :has_key?

  def_delegator :@forward, :length

  alias :member? :has_key?

  def merge(*other_bhs)
    dup.merge!(*other_bhs)
  end

  def merge!(*other_bhs)
    # NOTE: merge/merge!/update intentionally do not implement block support yet
    #       see https://github.com/Cohen-Carlisle/bihash/issues/17
    raise_error_if_frozen
    other_bhs.each do |other_bh|
      raise_error_unless_bihash(other_bh)
      other_bh.each { |k,v| store(k,v) }
    end
    self
  end

  def rehash
    raise_error_if_frozen
    if illegal_state?
      raise 'Cannot rehash while a key is duplicated outside its own pair'
    end
    @forward.rehash
    @reverse.rehash
    self
  end

  def reject(&block)
    if block_given?
      dup_without_defaults.tap { |d| d.reject!(&block) }
    else
      to_enum(:reject)
    end
  end

  def reject!(&block)
    if block_given?
      raise_error_if_frozen
      old_size = size
      delete_if(&block)
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
    @default = other_bh.default
    @default_proc = other_bh.default_proc
    self
  end

  alias :select :filter

  alias :select! :filter!

  def shift
    raise_error_if_frozen
    @reverse.shift
    @forward.shift
  end

  def_delegator :@forward, :size

  def slice(*args)
    self.class.new.tap do |bh|
      bh.compare_by_identity if self.compare_by_identity?
      args.each do |arg|
        bh[arg] = self[arg] if key?(arg)
      end
    end
  end

  alias :store :[]=

  def to_h
    if block_given?
      @forward.to_h { |k,v| yield(k,v) }
    else
      @forward.dup
    end
  end

  def to_hash
    to_h
  end

  def to_proc
    method(:[]).to_proc
  end

  alias :to_s :inspect

  alias :update :merge!

  def values_at(*keys)
    keys.map { |key| self[key] }
  end

  private

  def self.new_from_hash(h)
    h = Hash[h.to_a] if h.compare_by_identity? && RUBY_VERSION.to_f < 3.3
    bihash = new
    bihash.instance_variable_set(:@reverse, h.invert)
    bihash.instance_variable_set(:@forward, h)
    if bihash.send(:illegal_state?)
      raise ArgumentError, 'A key would be duplicated outside its own pair'
    end
    bihash
  end
  private_class_method :new_from_hash

  def default_value(key)
    @default_proc ? @default_proc.call(self, key) : @default
  end

  def dup_without_defaults
    dup.tap { |bh| bh.default = nil }
  end

  def illegal_state?(compare_by_id: compare_by_identity?)
    if compare_by_id
      unique_members = (@forward.keys + @forward.values).uniq(&:object_id).count
      duplicate_pairs = @forward.count { |k,v| k.equal?(v) }
    else
      unique_members = (@forward.keys | @forward.values).count
      duplicate_pairs = @forward.count { |k,v| k.eql?(v) }
    end
    unique_members + duplicate_pairs < @forward.length * 2
  end

  def initialize(*args, &block)
    raise_error_if_frozen
    if block_given? && !args.empty?
      raise ArgumentError, "wrong number of arguments (#{args.size} for 0)"
    elsif args.size > 1
      raise ArgumentError, "wrong number of arguments (#{args.size} for 0..1)"
    end
    super()
    @forward, @reverse = {}, {}
    @default, @default_proc = args[0], block
  end

  alias :initialize_copy :replace

  def merged_hash_attrs
    @reverse.merge(@forward)
  end

  def raise_error_if_frozen
    raise FrozenError, "can't modify frozen Bihash" if frozen?
  end

  def raise_error_unless_bihash(obj)
    unless obj.is_a?(Bihash)
      raise TypeError, "wrong argument type #{obj.class} (expected Bihash)"
    end
  end

  def subset?(other_bh)
    @forward.all? { |k,v| other_bh.key?(k) && other_bh[k].eql?(v) }
  end
end
