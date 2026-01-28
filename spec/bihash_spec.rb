require 'spec_helper'

describe Bihash do
  it 'should be enumerable' do
    _(Bihash).must_include Enumerable
  end

  Bihash::UNIMPLEMENTED_METHODS.each do |method|
    it "should report that it does not respond to ##{method}" do
      _(Bihash.new.respond_to?(method)).must_equal false
    end

    it "should raise NoMethodError if ##{method} is called" do
      error = _(-> { Bihash.new.send(method) }).must_raise NoMethodError
      _(error.message).must_equal "Bihash##{method} not implemented"
    end
  end

  describe '::[]' do
    it 'should be able to create an empty bihash' do
      bh = Bihash[]
      _(bh).must_be_instance_of Bihash
      _(bh).must_be_empty
    end

    it 'should convert a hash to a bihash' do
      bh = Bihash[:key => 'value']
      _(bh).must_be_instance_of Bihash
      _(bh[:key]).must_equal 'value'
      _(bh['value']).must_equal :key
    end

    it 'should not accept a hash with duplicate values' do
      _(-> { Bihash[:k1 => 'val', :k2 => 'val'] }).must_raise ArgumentError
    end

    it 'should not accept a hash that would result in ambiguous mappings' do
      _(-> { Bihash[1, 2, 2, 3] }).must_raise ArgumentError
    end

    it 'should accept a hash where a key equals its value' do
      bh = Bihash[:key => :key]
      _(bh).must_be_instance_of Bihash
      _(bh[:key]).must_equal :key
    end

    it 'should always return the value object if key-value pairs are equal' do
      key, value = [], []
      bh = Bihash[key => value]
      _(bh).must_be_instance_of Bihash
      _(bh[key].object_id).must_equal value.object_id
      _(bh[value].object_id).must_equal value.object_id
    end

    it 'should accept an even number of arguments' do
      bh = Bihash[:k1, 1, :k2, 2]
      _(bh).must_be_instance_of Bihash
      _(bh[:k1]).must_equal 1
      _(bh[:k2]).must_equal 2
      _(bh[1]).must_equal :k1
      _(bh[2]).must_equal :k2
    end

    it 'should accept an array of key-value pairs packaged in arrays' do
      array = [[:k1, 1], [:k2, 2]]
      bh = Bihash[array]
      _(bh).must_be_instance_of Bihash
      _(bh[:k1]).must_equal 1
      _(bh[:k2]).must_equal 2
      _(bh[1]).must_equal :k1
      _(bh[2]).must_equal :k2
    end
  end

  describe '::new' do
    it 'should create an empty bihash with a default of nil if no args' do
      bh = Bihash.new
      _(bh).must_be_instance_of Bihash
      _(bh).must_be_empty
      _(bh[:not_a_key]).must_be_nil
    end

    it 'should create an empty bihash with a default if given an object arg' do
      bh = Bihash.new('default')
      _(bh).must_be_instance_of Bihash
      _(bh).must_be_empty
      _(bh[:not_a_key]).must_equal 'default'
      bh[:not_a_key].tr!('ealt', '3417')
      _(bh[:still_not_a_key]).must_equal 'd3f4u17'
    end

    it 'should create an empty bihash with a default if given a block arg' do
      bh = Bihash.new { 'd3f4u17' }
      _(bh).must_be_instance_of Bihash
      _(bh).must_be_empty
      _(bh[:not_a_key]).must_equal 'd3f4u17'
      bh[:not_a_key].tr!('3417', 'ealt')
      _(bh[:not_a_key]).must_equal 'd3f4u17'
    end

    it 'should allow assignment of new pairs if given a block arg' do
      bh = Bihash.new { |bihash, key| bihash[key] = key.to_s }
      _(bh[404]).must_equal '404'
      _(bh.size).must_equal 1
      _(bh).must_include 404
      _(bh).must_include '404'
    end

    it 'should not accept both an object and a block' do
      _(-> { Bihash.new('default 1') { 'default 2' } }).must_raise ArgumentError
    end
  end

  describe '::try_convert' do
    it 'should convert an object to a bihash if it responds to #to_hash' do
      hash = {:k1 => 1, :k2 => 2}
      bh = Bihash.try_convert(hash)
      _(bh).must_be_instance_of Bihash
      _(bh[:k1]).must_equal 1
      _(bh[:k2]).must_equal 2
      _(bh[1]).must_equal :k1
      _(bh[2]).must_equal :k2
    end

    it 'should convert a bihash to a bihash' do
      bh = Bihash[:key => 'value']
      _(Bihash.try_convert(bh)).must_equal bh
    end

    it 'should return nil if the object does not respond to #to_hash' do
      _(Bihash.try_convert(Object.new)).must_be_nil
    end

    it 'should not accept a hash with duplicate values' do
      _(-> { Bihash.try_convert(:k1 => 1, :k2 => 1) }).must_raise ArgumentError
    end
  end

  describe '#<' do
    it 'should raise an error if the right hand side is not a bihash' do
      _(-> { Bihash[a: 1, b: 2] < {a: 1, b: 2, c: 3} }).must_raise TypeError
    end

    it 'should return true when the argument is a strict subset of self' do
      _((Bihash[a: 1, b: 2] < Bihash[a: 1, b: 2, c: 3])).must_equal true
    end

    it 'should return false when the argument is equal to self' do
      _((Bihash[a: 1, b: 2] < Bihash[a: 1, b: 2])).must_equal false
    end

    it 'should return false when the argument is not a subset of self' do
      _((Bihash[a: 1, b: 2, c: 3] < Bihash[a: 1, b: 2])).must_equal false
    end
  end

  describe '#<=' do
    it 'should raise an error if the right hand side is not a bihash' do
      _(-> { Bihash[a: 1, b: 2] <= {a: 1, b: 2, c: 3} }).must_raise TypeError
    end

    it 'should return true when the argument is a strict subset of self' do
      _((Bihash[a: 1, b: 2] <= Bihash[a: 1, b: 2, c: 3])).must_equal true
    end

    it 'should return true when the argument is equal to self' do
      _((Bihash[a: 1, b: 2] <= Bihash[a: 1, b: 2])).must_equal true
    end

    it 'should return false when the argument is not a subset of self' do
      _((Bihash[a: 1, b: 2, c: 3] <= Bihash[a: 1, b: 2])).must_equal false
    end
  end

  describe '#==' do
    it 'should return true when two bihashes have the same pairs' do
      bh1, bh2 = Bihash[:k1 => 1, :k2 => 2], Bihash[2 => :k2, 1 => :k1]
      _((bh1 == bh2)).must_equal true
    end

    it 'should return false when two bihashes do not have the same pairs' do
      bh1, bh2 = Bihash[:k1 => 1, :k2 => 2], Bihash[:k1 => 1, :k2 => 99]
      _((bh1 == bh2)).must_equal false
    end

    it 'should be aliased to #eql?' do
      bh = Bihash.new
      _(bh.method(:eql?)).must_equal bh.method(:==)
    end
  end

  describe '#>' do
    it 'should raise an error if the right hand side is not a bihash' do
      _(-> { Bihash[a: 1, b: 2] > {a: 1, b: 2, c: 3} }).must_raise TypeError
    end

    it 'should return true when the argument is a strict superset of self' do
      _((Bihash[a: 1, b: 2, c: 3] > Bihash[a: 1, b: 2])).must_equal true
    end

    it 'should return false when the argument is equal to self' do
      _((Bihash[a: 1, b: 2] > Bihash[a: 1, b: 2])).must_equal false
    end

    it 'should return false when the argument is not a superset of self' do
      _((Bihash[a: 1, b: 2] > Bihash[a: 1, b: 2, c: 3])).must_equal false
    end
  end

  describe '#>=' do
    it 'should raise an error if the right hand side is not a bihash' do
      _(-> { Bihash[a: 1, b: 2] >= {a: 1, b: 2, c: 3} }).must_raise TypeError
    end

    it 'should return true when the argument is a strict superset of self' do
      _((Bihash[a: 1, b: 2, c: 3] >= Bihash[a: 1, b: 2])).must_equal true
    end

    it 'should return true when the argument is equal to self' do
      _((Bihash[a: 1, b: 2] >= Bihash[a: 1, b: 2])).must_equal true
    end

    it 'should return false when the argument is not a superset of self' do
      _((Bihash[a: 1, b: 2] >= Bihash[a: 1, b: 2, c: 3])).must_equal false
    end
  end

  describe '#[]' do
    it 'should return the other pair' do
      bh = Bihash[:key => 'value']
      _(bh[:key]).must_equal 'value'
      _(bh['value']).must_equal :key
    end

    it 'should return falsey values correctly' do
      bh1 = Bihash[nil => false]
      _(bh1[nil]).must_equal false
      _(bh1[false]).must_be_nil

      bh2 = Bihash[false => nil]
      _(bh2[false]).must_be_nil
      _(bh2[nil]).must_equal false
    end
  end

  describe '#[]=' do
    it 'should allow assignment of new pairs' do
      bh = Bihash.new
      bh[:key] = 'value'
      _(bh[:key]).must_equal 'value'
      _(bh['value']).must_equal :key
    end

    it 'should remove old pairs if old keys are re-assigned' do
      bh = Bihash[1 => 'one', 2 => 'two']
      bh[1] = 'uno'
      _(bh[1]).must_equal 'uno'
      _(bh['uno']).must_equal 1
      _(bh).wont_include 'one'
    end

    it 'should always return the value object if key-value pairs are equal' do
      key, value = [], []
      bh = Bihash.new
      bh[key] = value
      _(bh[key].object_id).must_equal value.object_id
      _(bh[value].object_id).must_equal value.object_id
    end

    it 'should be aliased to #store' do
      bh = Bihash.new
      _(bh.method(:store)).must_equal bh.method(:[]=)
      bh.store(:key, 'value')
      _(bh[:key]).must_equal 'value'
      _(bh['value']).must_equal :key
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      _(-> { Bihash.new.freeze[:key] = 'value' }).must_raise RuntimeError
    end
  end

  describe '#assoc' do
    it 'should return the pair if the argument is a key' do
      bh = Bihash[:k1 => 'v1', :k2 => 'v2']
      _(bh.assoc(:k1)).must_equal [:k1, 'v1']
      _(bh.assoc('v2')).must_equal ['v2', :k2]
    end

    it 'should return nil if the argument is not a key' do
      bh = Bihash.new(404)
      _(bh.assoc(:not_a_key)).must_be_nil
    end

    it 'should find the key using #==' do
      bh = Bihash[[] => 'array']
      bh['array'] << 'modified'
      _(bh.assoc(['modified'])).must_equal [['modified'], 'array']
      _(bh.assoc([])).must_be_nil
    end
  end

  describe '#clear' do
    it 'should remove all pairs and return the bihash' do
      bh = Bihash[:key => 'value']
      _(bh.clear.object_id).must_equal bh.object_id
      _(bh).must_be_empty
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      _(-> { Bihash.new.freeze.clear }).must_raise RuntimeError
    end
  end

  describe '#clone' do
    it 'should make a copy of the bihash' do
      bh = Bihash[1 => :one]
      clone = bh.clone
      clone[2] = :two
      _(bh[2]).must_be_nil
    end
  end

  describe '#compare_by_identity' do
    it 'should set bihash to compare by identity instead of equality' do
      bh = Bihash.new.compare_by_identity
      key1, key2 = 'key', 'value'
      bh[key1] = key2
      _(bh['key']).must_be_nil
      _(bh['value']).must_be_nil
      _(bh[key1]).must_equal 'value'
      _(bh[key2]).must_equal 'key'
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      _(-> { Bihash.new.freeze.compare_by_identity }).must_raise RuntimeError
    end
  end

  describe '#compare_by_identity?' do
    it 'should indicate whether bihash is comparing by identity' do
      _(Bihash.new.compare_by_identity.compare_by_identity?).must_equal true
      _(Bihash.new.compare_by_identity?).must_equal false
    end
  end

  describe '#default' do
    it 'should not accept more than one argument' do
      _(-> { Bihash.new.default(1,2) }).must_raise ArgumentError
    end

    describe 'when there is not a default proc' do
      it 'should return the default' do
        bh1 = Bihash[:key => 'value']
        _(bh1.default).must_be_nil
        _(bh1.default(:not_a_key)).must_be_nil
        _(bh1.default(:key)).must_be_nil

        bh2 = Bihash.new(404)
        bh2[:key] = 'value'
        _(bh2.default).must_equal 404
        _(bh2.default(:not_a_key)).must_equal 404
        _(bh2.default(:key)).must_equal 404
      end
    end

    describe 'when there is a default proc' do
      it 'should return the default if called with no argument' do
        _(Bihash.new { 'proc called' }.default).must_be_nil
      end

      it 'should call the default proc when called with an argument' do
        bh = Bihash.new { |bihash, key| bihash[key] = key.to_s }
        bh[:key] = 'value'

        _(bh.default(:key)).must_equal 'key'
        _(bh[:key]).must_equal 'key'

        _(bh.default(404)).must_equal '404'
        _(bh[404]).must_equal '404'
      end
    end
  end

  describe '#default=' do
    it 'should set the default object' do
      bh = Bihash.new { 'proc called' }
      _(bh[:not_a_key]).must_equal 'proc called'
      _((bh.default = 404)).must_equal 404
      _(bh[:not_a_key]).must_equal 404
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      _(-> { Bihash.new.freeze.default = 404 }).must_raise RuntimeError
    end
  end

  describe '#default_proc' do
    it 'should return the default proc if it exists' do
      bh = Bihash.new { |bihash, key| bihash[key] = key }
      prc = bh.default_proc
      array = []
      prc.call(array, 2)
      _(array).must_equal [nil, nil, 2]
    end

    it 'should return nil if there is no default proc' do
      _(Bihash.new.default_proc).must_be_nil
      _(Bihash.new(404).default_proc).must_be_nil
    end
  end

  describe '#default_proc=' do
    it 'should set the default proc' do
      bh = Bihash.new(:default_object)
      _(bh[:not_a_key]).must_equal :default_object
      _((bh.default_proc = ->(bihash, key) { '404' })).must_be_instance_of Proc
      _(bh[:not_a_key]).must_equal '404'
    end

    it 'should set the default value to nil if argument is nil' do
      bh = Bihash.new(:default_object)
      _(bh[:not_a_key]).must_equal :default_object
      _((bh.default_proc = nil)).must_be_nil
      _(bh[:not_a_key]).must_be_nil
    end

    it 'should raise TypeError if not given a non-proc (except nil)' do
      _(-> { Bihash.new.default_proc = :not_a_proc }).must_raise TypeError
    end

    it 'should raise TypeError given a lambda without 2 args' do
      _(-> { Bihash.new.default_proc = -> { '404' } }).must_raise TypeError
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      _(-> { Bihash[].freeze.default_proc = proc { '' } }).must_raise RuntimeError
    end
  end

  describe '#delete' do
    it 'should return the other key if the given key is found' do
      _(Bihash[:key => 'value'].delete(:key)).must_equal 'value'
      _(Bihash[:key => 'value'].delete('value')).must_equal :key
    end

    it 'should remove both keys' do
      bh1 = Bihash[:key => 'value']
      bh1.delete(:key)
      _(bh1).wont_include :key
      _(bh1).wont_include 'value'

      bh2 = Bihash[:key => 'value']
      bh2.delete('value')
      _(bh2).wont_include :key
      _(bh2).wont_include 'value'
    end

    it 'should call the block (if given) when the key is not found' do
      out = Bihash[:key => 'value'].delete(404) { |key| "#{key} not found" }
      _(out).must_equal '404 not found'
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      _(-> { Bihash.new.freeze.delete(:key) }).must_raise RuntimeError
    end
  end

  describe '#delete_if' do
    it 'should delete any pairs for which the block evaluates to true' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      bh_id = bh.object_id
      _(bh.delete_if { |key1, key2| key1.even? }.object_id).must_equal bh_id
      _(bh).must_equal Bihash[1 => :one, 3 => :three]
    end

    it 'should raise RuntimeError if called on a frozen bihash with a block' do
      _(-> { Bihash.new.freeze.delete_if { false } }).must_raise RuntimeError
    end

    it 'should return an enumerator if not given a block' do
      enum = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four].delete_if
      _(enum).must_be_instance_of Enumerator
      _(enum.each { |k1, k2| k1.even? }).must_equal Bihash[1 => :one, 3 => :three]
    end
  end

  describe '#dig' do
    it 'should traverse nested bihashes' do
      bh = Bihash[foo: Bihash[bar: Bihash[baz: 4]]]
      _(bh.dig(:foo, :bar, :baz)).must_equal 4
      _(bh.dig(:foo, :bar, 4)).must_equal :baz
    end

    it 'should traverse nested hashes' do
      bh = Bihash[foo: {bar: {baz: 4}}]
      _(bh.dig(:foo, :bar, :baz)).must_equal 4
    end

    it 'should traverse nested arrays' do
      bh = Bihash[foo: [[4]]]
      _(bh.dig(:foo, 0, 0)).must_equal 4
    end

    it 'should return nil if any intermediate step is nil' do
      bh = Bihash[foo: Bihash[bar: Bihash[baz: 4]]]
      _(bh.dig(:foo, :bur, :boz)).must_be_nil
    end
  end

  describe '#dup' do
    it 'should make a copy of the bihash' do
      bh = Bihash[1 => :one]
      dup = bh.dup
      dup[2] = :two
      _(bh[2]).must_be_nil
    end
  end

  describe '#each' do
    it 'should iterate over each pair in the bihash' do
      array = []
      Bihash[:k1 => 'v1', :k2 => 'v2'].each { |pair| array << pair }
      _(array).must_equal [[:k1, 'v1'], [:k2, 'v2']]
    end

    it 'should return the bihash if given a block' do
      bh = Bihash.new
      _(bh.each { |p| }).must_be_instance_of Bihash
      _(bh.each { |p| }.object_id).must_equal bh.object_id
    end

    it 'should return an enumerator if not given a block' do
      enum = Bihash[:k1 => 'v1', :k2 => 'v2'].each
      _(enum).must_be_instance_of Enumerator
      _(enum.each { |pair| pair }).must_equal Bihash[:k1 => 'v1', :k2 => 'v2']
    end

    it 'should be aliased to #each_pair' do
      bh = Bihash.new
      _(bh.method(:each_pair)).must_equal bh.method(:each)
    end
  end

  describe '#empty?' do
    it 'should indicate if the bihash is empty' do
      _(Bihash.new.empty?).must_equal true
      _(Bihash[:key => 'value'].empty?).must_equal false
    end
  end

  describe '#fetch' do
    it 'should return the other pair' do
      bh = Bihash[:key => 'value']
      _(bh.fetch(:key)).must_equal 'value'
      _(bh.fetch('value')).must_equal :key
    end

    it 'should return falsey values correctly' do
      bh1 = Bihash[nil => false]
      _(bh1.fetch(nil)).must_equal false
      _(bh1.fetch(false)).must_be_nil

      bh2 = Bihash[false => nil]
      _(bh2.fetch(false)).must_be_nil
      _(bh2.fetch(nil)).must_equal false
    end

    describe 'when the key is not found' do
      it 'should raise KeyError when not supplied any default' do
        _(-> { Bihash[].fetch(:not_a_key) }).must_raise KeyError
      end

      it 'should return the second arg when supplied with one' do
        _(Bihash[].fetch(:not_a_key, :second_arg)).must_equal :second_arg
      end

      it 'should call the block if supplied with one' do
        _(Bihash[].fetch(404) { |k| "#{k} not found" }).must_equal '404 not found'
      end
    end
  end

  describe '#fetch_values' do
    it 'should return an array of values corresponding to the given keys' do
      _(Bihash[1 => :one, 2 => :two].fetch_values(1, 2)).must_equal [:one, :two]
      _(Bihash[1 => :one, 2 => :two].fetch_values(:one, :two)).must_equal [1, 2]
      _(Bihash[1 => :one, 2 => :two].fetch_values(1, :two)).must_equal [:one, 2]
    end

    it 'should raise a KeyError if any key is not found' do
      _(-> { Bihash.new.fetch_values(404) }).must_raise KeyError
    end

    it 'should not duplicate entries if a key equals its value' do
      _(Bihash[:key => :key].fetch_values(:key)).must_equal [:key]
    end

    it 'should return an empty array with no args' do
      _(Bihash[:key => 'value'].fetch_values).must_equal []
    end
  end

  describe '#flatten' do
    it 'should extract the pairs into an array' do
      _(Bihash[:k1 => 'v1', :k2 => 'v2'].flatten).must_equal [:k1, 'v1', :k2, 'v2']
    end

    it 'should not flatten array keys if no argument is given' do
      _(Bihash[:key => ['v1', 'v2']].flatten).must_equal [:key, ['v1', 'v2']]
    end

    it 'should flatten to the level given as an argument' do
      _(Bihash[:key => ['v1', 'v2']].flatten(2)).must_equal [:key, 'v1', 'v2']
    end
  end

  describe '#hash' do
    it 'should return the same hash code if two bihashes have the same pairs' do
      bh1, bh2 = Bihash[:k1 => 1, :k2 => 2], Bihash[2 => :k2, 1 => :k1]
      _(bh1.hash).must_equal bh2.hash
    end
  end

  describe '#include?' do
    it 'should indicate if the bihash contains the argument' do
      bh = Bihash[:key => 'value']
      _(bh.include?(:key)).must_equal true
      _(bh.include?('value')).must_equal true
      _(bh.include?(:not_a_key)).must_equal false
    end

    it 'should be aliased to #has_key?, #key?, and #member?' do
      bh = Bihash.new
      _(bh.method(:has_key?)).must_equal bh.method(:include?)
      _(bh.method(:key?)).must_equal bh.method(:include?)
      _(bh.method(:member?)).must_equal bh.method(:include?)
    end
  end

  describe '#keep_if' do
    it 'should retain any pairs for which the block evaluates to true' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      bh_id = bh.object_id
      _(bh.keep_if { |key1, key2| key1.even? }.object_id).must_equal bh_id
      _(bh).must_equal Bihash[2 => :two, 4 => :four]
    end

    it 'should raise RuntimeError if called on a frozen bihash with a block' do
      _(-> { Bihash.new.freeze.keep_if { true } }).must_raise RuntimeError
    end

    it 'should return an enumerator if not given a block' do
      enum = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four].keep_if
      _(enum).must_be_instance_of Enumerator
      _(enum.each { |k1, k2| k1.even? }).must_equal Bihash[2 => :two, 4 => :four]
    end
  end

  describe '#length' do
    it 'should return the number of pairs in the bihash' do
      _(Bihash[1 => :one, 2 => :two].length).must_equal 2
    end
  end

  describe '#merge' do
    it 'should merge bihashes, assigning each arg pair to a copy of reciever' do
      receiver = Bihash[:chips => :salsa, :milk => :cookies, :fish => :rice]
      original_receiver = receiver.dup
      argument = Bihash[:fish => :chips, :soup => :salad]
      return_value = Bihash[:milk => :cookies, :fish => :chips, :soup => :salad]
      _(receiver.merge(argument)).must_equal return_value
      _(receiver).must_equal original_receiver
    end

    it 'should raise TypeError if arg is not a bihash' do
      _(-> { Bihash.new.merge({:key => 'value'}) }).must_raise TypeError
    end
  end

  describe '#merge!' do
    it 'should merge bihashes, assigning each arg pair to the receiver' do
      receiver = Bihash[:chips => :salsa, :milk => :cookies, :fish => :rice]
      argument = Bihash[:fish => :chips, :soup => :salad]
      return_value = Bihash[:milk => :cookies, :fish => :chips, :soup => :salad]
      _(receiver.merge!(argument)).must_equal return_value
      _(receiver).must_equal return_value
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      _(-> { Bihash.new.freeze.merge!(Bihash.new) }).must_raise RuntimeError
    end

    it 'should raise TypeError if arg is not a bihash' do
      _(-> { Bihash.new.merge!({:key => 'value'}) }).must_raise TypeError
    end

    it 'should be aliased to #update' do
      bh = Bihash.new
      _(bh.method(:update)).must_equal bh.method(:merge!)
    end
  end

  describe '#rehash' do
    it 'should recompute all key hash values and return the bihash' do
      bh = Bihash[[] => :array]
      bh[:array] << 1
      _(bh[[1]]).must_be_nil
      _(bh.rehash[[1]]).must_equal :array
      _(bh[[1]]).must_equal :array
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      _(-> { Bihash.new.freeze.rehash }).must_raise RuntimeError
    end

    it 'should raise RuntimeError if called when key duplicated outside pair' do
      bh = Bihash[[1], [2], [3], [4]]
      (bh[[4]] << 1).shift
      _(-> { bh.rehash }).must_raise RuntimeError
    end
  end

  describe '#reject' do
    describe 'when some items are rejected' do
      it 'should return a bihash with items not rejected by the block' do
        bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
        _(bh.reject { |k1,k2| k1.even? }).must_equal Bihash[1 => :one, 3 => :three]
        _(bh).must_equal Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      end
    end

    describe 'when no items are rejected' do
      it 'should return a bihash with items not rejected by the block' do
        bh = Bihash[1 => :one, 3 => :three, 5 => :five, 7 => :seven]
        _(bh.reject { |k1,k2| k1.even? }).must_equal bh
        _(bh).must_equal bh
      end
    end

    it 'should return an enumerator if not given a block' do
      enum = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four].reject
      _(enum).must_be_instance_of Enumerator
      _(enum.each { |k1,k2| k1.even? }).must_equal Bihash[1 => :one, 3 => :three]
    end
  end

  describe '#reject!' do
    it 'should delete any pairs for which the block evaluates to true' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      bh_id = bh.object_id
      _(bh.reject! { |key1, key2| key1.even? }.object_id).must_equal bh_id
      _(bh).must_equal Bihash[1 => :one, 3 => :three]
    end

    it 'should return nil if no changes were made to the bihash' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      _(bh.reject! { |key1, key2| key1 > 5 }).must_be_nil
      _(bh).must_equal Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
    end

    it 'should raise RuntimeError if called on a frozen bihash with a block' do
      _(-> { Bihash.new.freeze.reject! { false } }).must_raise RuntimeError
    end

    it 'should return an enumerator if not given a block' do
      enum = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four].reject!
      _(enum).must_be_instance_of Enumerator
      _(enum.each { |k1, k2| k1.even? }).must_equal Bihash[1 => :one, 3 => :three]
    end
  end

  describe '#replace' do
    it 'should replace the contents of receiver with the contents of the arg' do
      receiver = Bihash[]
      original_id = receiver.object_id
      arg = Bihash[:key => 'value']
      _(receiver.replace(arg)).must_equal Bihash[:key => 'value']
      arg[:another_key] = 'another_value'
      _(receiver.object_id).must_equal original_id
      _(receiver).must_equal Bihash[:key => 'value']
    end

    it 'should copy the default value' do
      receiver = Bihash[]
      arg = Bihash.new(404)
      receiver.replace(arg)
      _(receiver.default).must_equal 404
    end

    it 'should copy the default proc' do
      receiver = Bihash[]
      arg = Bihash.new { |_, key| key.to_s }
      receiver.replace(arg)
      _(receiver.default(:not_a_key)).must_equal 'not_a_key'
    end

    it 'should raise TypeError if arg is not a bihash' do
      _(-> { Bihash.new.replace({:key => 'value'}) }).must_raise TypeError
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      _(-> { Bihash.new.freeze.replace(Bihash[:k, 'v']) }).must_raise RuntimeError
    end
  end

  describe '#select' do
    describe 'when only some items are selected' do
      it 'should return a bihash with items selected by the block' do
        bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
        _(bh.select { |k1,k2| k1.even? }).must_equal Bihash[2 => :two, 4 => :four]
        _(bh).must_equal Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      end
    end

    describe 'when all items are selected' do
      it 'should return a bihash with items selected by the block' do
        bh = Bihash[2 => :two, 4 => :four, 6 => :six, 8 => :eight]
        _(bh.select { |k1,k2| k1.even? }).must_equal bh
        _(bh).must_equal bh
      end
    end

    it 'should return an enumerator if not given a block' do
      enum = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four].select
      _(enum).must_be_instance_of Enumerator
      _(enum.each { |k1,k2| k1.even? }).must_equal Bihash[2 => :two, 4 => :four]
    end

    it 'should be aliased to #filter' do
      bh = Bihash.new
      _(bh.method(:filter)).must_equal bh.method(:select)
    end
  end

  describe '#select!' do
    it 'should retain any pairs for which the block evaluates to true' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      bh_id = bh.object_id
      _(bh.select! { |key1, key2| key1.even? }.object_id).must_equal bh_id
      _(bh).must_equal Bihash[2 => :two, 4 => :four]
    end

    it 'should return nil if no changes were made to the bihash' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      _(bh.select! { |key1, key2| key1 < 5 }).must_be_nil
      _(bh).must_equal Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
    end

    it 'should raise RuntimeError if called on a frozen bihash with a block' do
      _(-> { Bihash.new.freeze.select! { true } }).must_raise RuntimeError
    end

    it 'should return an enumerator if not given a block' do
      enum = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four].select!
      _(enum).must_be_instance_of Enumerator
      _(enum.each { |k1, k2| k1.even? }).must_equal Bihash[2 => :two, 4 => :four]
    end

    it 'should be aliased to #filter!' do
      bh = Bihash.new
      _(bh.method(:filter!)).must_equal bh.method(:select!)
    end
  end

  describe '#shift' do
    it 'should remove the oldest pair from the bihash and return it' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three]
      _(bh.shift).must_equal [1, :one]
      _(bh).must_equal Bihash[2 => :two, 3 => :three]
    end

    it 'should return the default value if bihash is empty' do
      _(Bihash.new.shift).must_be_nil
      _(Bihash.new(404).shift).must_equal 404
      _(Bihash.new { 'd3f4u17' }.shift).must_equal 'd3f4u17'
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      _(-> { Bihash.new.freeze.shift }).must_raise RuntimeError
    end
  end

  describe '#size' do
    it 'should return the number of pairs in the bihash' do
      _(Bihash[1 => :one, 2 => :two].size).must_equal 2
    end
  end

  describe '#slice' do
    it 'should return a new bihash with only the pairs that are in the args' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three]
      _(bh.slice(1, :one, :two, "nope")).must_equal Bihash[1 => :one, 2 => :two]
      _(bh).must_equal Bihash[1 => :one, 2 => :two, 3 => :three]
    end

    it 'should return a vanilla bihash without default values, etc.' do
      sliced_bh = Bihash.new(404).slice
      _(sliced_bh.default).must_be_nil
    end
  end

  describe '#to_h' do
    it 'should return a copy of the forward hash' do
      bh = Bihash[:key1 => 'val1', :key2 => 'val2']
      h = bh.to_h
      _(h).must_equal Hash[:key1 => 'val1', :key2 => 'val2']
      h.delete(:key1)
      _(bh).must_include :key1
    end

    it 'should be aliased to #to_hash' do
      bh = Bihash.new
      _(bh.method(:to_hash)).must_equal bh.method(:to_h)
    end
  end

  describe '#to_proc' do
    it 'should convert the bihash to a proc' do
      _(Bihash[].to_proc).must_be_instance_of Proc
    end

    it 'should call #[] on the bihash when the proc is called' do
      _(Bihash[:key => 'value'].to_proc.call(:key)).must_equal 'value'
    end
  end

  describe '#to_s' do
    it 'should return a nice string representing the bihash' do
      bh = Bihash[:k1 => 'v1', :k2 => [:v2], :k3 => {:k4 => 'v4'}]
      _(bh.to_s).must_equal 'Bihash[:k1=>"v1", :k2=>[:v2], :k3=>{:k4=>"v4"}]'
    end

    it 'should be aliased to #inspect' do
      bh = Bihash.new
      _(bh.method(:inspect)).must_equal bh.method(:to_s)
    end
  end

  describe '#values_at' do
    it 'should return an array of values corresponding to the given keys' do
      _(Bihash[1 => :one, 2 => :two].values_at(1, 2)).must_equal [:one, :two]
      _(Bihash[1 => :one, 2 => :two].values_at(:one, :two)).must_equal [1, 2]
      _(Bihash[1 => :one, 2 => :two].values_at(1, :two)).must_equal [:one, 2]
    end

    it 'should use the default if a given key is not found' do
      bh = Bihash.new(404)
      bh[1] = :one
      bh[2] = :two
      _(bh.values_at(1, 2, 3)).must_equal [:one, :two, 404]
      _(bh.values_at(:one, :two, :three)).must_equal [1, 2, 404]
    end

    it 'should not duplicate entries if a key equals its value' do
      _(Bihash[:key => :key].values_at(:key)).must_equal [:key]
    end

    it 'should return an empty array with no args' do
      _(Bihash[:key => 'value'].values_at).must_equal []
    end
  end

  describe '#initialize' do
    it 'should raise RuntimeError if called on a frozen bihash' do
      _(-> { Bihash.new.freeze.send(:initialize) }).must_raise RuntimeError
    end
  end
end
