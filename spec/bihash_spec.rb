gem 'minitest'
require 'minitest/spec'
require 'minitest/autorun'
require 'bihash'

describe Bihash do
  it 'should be enumerable' do
    Bihash.must_include Enumerable
  end

  describe '::new' do
    it 'should create an empty bihash with a default of nil if no args' do
      bh = Bihash.new
      bh.must_be_instance_of Bihash
      bh.must_be_empty
      bh[:not_a_key].must_equal nil
    end

    it 'should create an empty bihash with a default if given an object arg' do
      bh = Bihash.new('default')
      bh.must_be_instance_of Bihash
      bh.must_be_empty
      bh[:not_a_key].must_equal 'default'
      bh[:not_a_key].tr!('ealt', '3417')
      bh[:still_not_a_key].must_equal 'd3f4u17'
    end

    it 'should create an empty bihash with a default if given a block arg' do
      bh = Bihash.new { 'd3f4u17' }
      bh.must_be_instance_of Bihash
      bh.must_be_empty
      bh[:not_a_key].must_equal 'd3f4u17'
      bh[:not_a_key].tr!('3417', 'ealt')
      bh[:not_a_key].must_equal 'd3f4u17'
    end

    it 'should allow assignment of new pairs if given a block arg' do
      bh = Bihash.new { |bihash, key| bihash[key] = key.to_s }
      bh[404].must_equal '404'
      bh.size.must_equal 1
      bh.must_include 404
      bh.must_include '404'
    end

    it 'should not accept both an object and a block' do
      -> { Bihash.new('default 1') { 'default 2' } }.must_raise ArgumentError
    end
  end

  describe '#initialize' do
    it 'should raise RuntimeError if called on a frozen bihash' do
      -> { Bihash.new.freeze.send(:initialize) }.must_raise RuntimeError
    end
  end

  describe '::[]' do
    it 'should be able to create an empty bihash' do
      bh = Bihash[]
      bh.must_be_instance_of Bihash
      bh.must_be_empty
    end

    it 'should convert a hash to a bihash' do
      bh = Bihash[:key => 'value']
      bh.must_be_instance_of Bihash
      bh[:key].must_equal 'value'
      bh['value'].must_equal :key
    end

    it 'should not accept a hash with duplicate values' do
      -> { Bihash[:k1 => 'val', :k2 => 'val'] }.must_raise ArgumentError
    end

    it 'should not accept a hash that would result in ambiguous mappings' do
      -> { Bihash[1, 2, 2, 3] }.must_raise ArgumentError
    end

    it 'should accept a hash where a key equals its value' do
      bh = Bihash[:key => :key]
      bh.must_be_instance_of Bihash
      bh[:key].must_equal :key
    end

    it 'should always return the value object if key-value pairs are equal' do
      key, value = [], []
      bh = Bihash[key => value]
      bh.must_be_instance_of Bihash
      bh[key].object_id.must_equal value.object_id
      bh[value].object_id.must_equal value.object_id
    end

    it 'should accept an even number of arguments' do
      bh = Bihash[:k1, 1, :k2, 2]
      bh.must_be_instance_of Bihash
      bh[:k1].must_equal 1
      bh[:k2].must_equal 2
      bh[1].must_equal :k1
      bh[2].must_equal :k2
    end

    it 'should accept an array of key-value pairs packaged in arrays' do
      array = [[:k1, 1], [:k2, 2]]
      bh = Bihash[array]
      bh.must_be_instance_of Bihash
      bh[:k1].must_equal 1
      bh[:k2].must_equal 2
      bh[1].must_equal :k1
      bh[2].must_equal :k2
    end
  end

  describe '::try_convert' do
    it 'should convert an object to a bihash if it responds to #to_hash' do
      hash = {:k1 => 1, :k2 => 2}
      bh = Bihash.try_convert(hash)
      bh.must_be_instance_of Bihash
      bh[:k1].must_equal 1
      bh[:k2].must_equal 2
      bh[1].must_equal :k1
      bh[2].must_equal :k2
    end

    it 'should return nil if the object does not respond to #to_hash' do
      Bihash.try_convert(Object.new).must_equal nil
    end

    it 'should not accept a hash with duplicate values' do
      -> { Bihash.try_convert(:k1 => 1, :k2 => 1) }.must_raise ArgumentError
    end
  end

  describe '#[]' do
    it 'should return the other pair' do
      bh = Bihash[:key => 'value']
      bh[:key].must_equal 'value'
      bh['value'].must_equal :key
    end

    it 'should return falsey values correctly' do
      bh1 = Bihash[nil => false]
      bh1[nil].must_equal false
      bh1[false].must_equal nil

      bh2 = Bihash[false => nil]
      bh2[false].must_equal nil
      bh2[nil].must_equal false
    end
  end

  describe '#[]=' do
    it 'should allow assignment of new pairs' do
      bh = Bihash.new
      bh[:key] = 'value'
      bh[:key].must_equal 'value'
      bh['value'].must_equal :key
    end

    it 'should remove old pairs if old keys are re-assigned' do
      bh = Bihash[1 => 'one', 2 => 'two']
      bh[1] = 'uno'
      bh[1].must_equal 'uno'
      bh['uno'].must_equal 1
      bh.wont_include 'one'
    end

    it 'should always return the value object if key-value pairs are equal' do
      key, value = [], []
      bh = Bihash.new
      bh[key] = value
      bh[key].object_id.must_equal value.object_id
      bh[value].object_id.must_equal value.object_id
    end

    it 'should be aliased to #store' do
      bh = Bihash.new
      bh.method(:store).must_equal bh.method(:[]=)
      bh.store(:key, 'value')
      bh[:key].must_equal 'value'
      bh['value'].must_equal :key
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      -> { Bihash.new.freeze[:key] = 'value' }.must_raise RuntimeError
    end
  end

  describe '#delete' do
    it 'should return the other key if the given key is found' do
      Bihash[:key => 'value'].delete(:key).must_equal 'value'
      Bihash[:key => 'value'].delete('value').must_equal :key
    end

    it 'should remove both keys' do
      bh1 = Bihash[:key => 'value']
      bh1.delete(:key)
      bh1.wont_include :key
      bh1.wont_include 'value'

      bh2 = Bihash[:key => 'value']
      bh2.delete('value')
      bh2.wont_include :key
      bh2.wont_include 'value'
    end

    it 'should call the block (if given) when the key is not found' do
      out = Bihash[:key => 'value'].delete(404) { |key| "#{key} not found" }
      out.must_equal '404 not found'
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      -> { Bihash.new.freeze.delete(:key) }.must_raise RuntimeError
    end
  end

  describe '#each' do
    it 'should iterate over each pair in the bihash' do
      array = []
      Bihash[:k1 => 'v1', :k2 => 'v2'].each { |pair| array << pair }
      array.must_equal [[:k1, 'v1'], [:k2, 'v2']]
    end

    it 'should return the bihash if given a block' do
      bh = Bihash.new
      bh.each { |p| }.must_be_instance_of Bihash
      bh.each { |p| }.object_id.must_equal bh.object_id
    end

    it 'should return an enumerator if not given a block' do
      Bihash.new.each.must_be_instance_of Enumerator
      array = []
      Bihash[:k1 => 'v1', :k2 => 'v2'].each { |pair| array << pair }
      array.must_equal [[:k1, 'v1'], [:k2, 'v2']]
    end

    it 'should be aliased to #each_pair' do
      bh = Bihash.new
      bh.method(:each_pair).must_equal bh.method(:each)
    end
  end

  describe '#==' do
    it 'should return true when two bihashes have the same pairs' do
      bh1, bh2 = Bihash[:k1 => 1, :k2 => 2], Bihash[:k2 => 2, :k1 => 1]
      (bh1 == bh2).must_equal true
    end

    it 'should return false when two bihashes do not have the same pairs' do
      bh1, bh2 = Bihash[:k1 => 1, :k2 => 2], Bihash[:k1 => 1, :k2 => 99]
      (bh1 == bh2).must_equal false
    end

    it 'should be aliased to #eql?' do
      bh = Bihash.new
      bh.method(:eql?).must_equal bh.method(:==)
    end
  end

  describe '#empty?' do
    it 'should indicate if the bihash is empty' do
      Bihash.new.empty?.must_equal true
      Bihash[:key => 'value'].empty?.must_equal false
    end
  end

  describe '#key?' do
    it 'should indicate if the bihash contains the argument' do
      bh = Bihash[:key => 'value']
      bh.key?(:key).must_equal true
      bh.key?('value').must_equal true
      bh.key?(:not_a_key).must_equal false
    end

    it 'should be aliased to #has_key?, #include?, and #member?' do
      bh = Bihash.new
      bh.method(:has_key?).must_equal bh.method(:key?)
      bh.method(:include?).must_equal bh.method(:key?)
      bh.method(:member?).must_equal bh.method(:key?)
    end
  end

  describe '#fetch' do
    it 'should return the other pair' do
      bh = Bihash[:key => 'value']
      bh.fetch(:key).must_equal 'value'
      bh.fetch('value').must_equal :key
    end

    it 'should return falsey values correctly' do
      bh1 = Bihash[nil => false]
      bh1.fetch(nil).must_equal false
      bh1.fetch(false).must_equal nil

      bh2 = Bihash[false => nil]
      bh2.fetch(false).must_equal nil
      bh2.fetch(nil).must_equal false
    end

    it 'should raise KeyError if key does not exist' do
      -> { Bihash.new.fetch(:not_a_key) }.must_raise KeyError
    end
  end

  describe '#clear' do
    it 'should remove all pairs and return the bihash' do
      bh = Bihash[:key => 'value']
      bh.clear.object_id.must_equal bh.object_id
      bh.must_be_empty
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      -> { Bihash.new.freeze.clear }.must_raise RuntimeError
    end
  end

  describe '#length' do
    it 'should return the number of pairs in the bihash' do
      Bihash[1 => :one, 2 => :two].length.must_equal 2
    end
  end

  describe '#size' do
    it 'should return the number of pairs in the bihash' do
      Bihash[1 => :one, 2 => :two].size.must_equal 2
    end
  end

  describe '#rehash' do
    it 'should recompute all key hash values and return the bihash' do
      bh = Bihash[[] => :array]
      bh[:array] << 1
      bh[[1]].must_equal nil
      bh.rehash[[1]].must_equal :array
      bh[[1]].must_equal :array
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      -> { Bihash.new.freeze.rehash }.must_raise RuntimeError
    end
  end

  describe '#to_h' do
    it 'should return a copy of the forward hash' do
      bh = Bihash[:key1 => 'val1', :key2 => 'val2']
      h = bh.to_h
      h.must_equal Hash[:key1 => 'val1', :key2 => 'val2']
      h.delete(:key1)
      bh.must_include :key1
    end

    it 'should be aliased to #to_hash' do
      bh = Bihash.new
      bh.method(:to_hash).must_equal bh.method(:to_h)
    end
  end

  describe '#values_at' do
    it 'should return an array of values corresponding to the given keys' do
      Bihash[1 => :one, 2 => :two].values_at(1, 2).must_equal [:one, :two]
      Bihash[1 => :one, 2 => :two].values_at(:one, :two).must_equal [1, 2]
      Bihash[1 => :one, 2 => :two].values_at(1, :two).must_equal [:one, 2]
    end

    it 'should use the default if a given key is not found' do
      bh = Bihash.new(404)
      bh[1] = :one
      bh[2] = :two
      bh.values_at(1, 2, 3).must_equal [:one, :two, 404]
      bh.values_at(:one, :two, :three).must_equal [1, 2, 404]
    end

    it 'should not duplicate entries if a key equals its value' do
      Bihash[:key => :key].values_at(:key).must_equal [:key]
    end

    it 'should return an empty array with no args' do
      Bihash[:key => 'value'].values_at.must_equal []
    end
  end

  describe '#flatten' do
    it 'extract the pairs into an array' do
      Bihash[:k1 => 'v1', :k2 => 'v2'].flatten.must_equal [:k1, 'v1', :k2, 'v2']
    end

    it 'should not flatten array keys if no argument is given' do
      Bihash[:key => ['v1', 'v2']].flatten.must_equal [:key, ['v1', 'v2']]
    end

    it 'should flatten to the level given as an argument' do
      Bihash[:key => ['v1', 'v2']].flatten(2).must_equal [:key, 'v1', 'v2']
    end
  end

  describe '#shift' do
    it 'should remove the oldest pair from the bihash and return it' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three]
      bh.shift.must_equal [1, :one]
      bh.must_equal Bihash[2 => :two, 3 => :three]
    end

    it 'should return the default value if bihash is empty' do
      Bihash.new.shift.must_equal nil
      Bihash.new(404).shift.must_equal 404
      Bihash.new { 'd3f4u17' }.shift.must_equal 'd3f4u17'
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      -> { Bihash.new.freeze.shift }.must_raise RuntimeError
    end
  end

  describe '#assoc' do
    it 'should return the pair if the argument is a key' do
      bh = Bihash[:k1 => 'v1', :k2 => 'v2']
      bh.assoc(:k1).must_equal [:k1, 'v1']
      bh.assoc('v2').must_equal ['v2', :k2]
    end

    it 'should return nil if the argument is not a key' do
      bh = Bihash.new(404)
      bh.assoc(:not_a_key).must_equal nil
    end

    it 'should find the key using #==' do
      bh = Bihash[[] => 'array']
      bh['array'] << 'modified'
      bh.assoc(['modified']).must_equal [['modified'], 'array']
      bh.assoc([]).must_equal nil
    end
  end

  describe '#to_s' do
    it 'should return a nice string representing the bihash' do
      bh = Bihash[:k1 => 'v1', :k2 => [:v2], :k3 => {:k4 => 'v4'}]
      bh.to_s.must_equal 'Bihash[:k1=>"v1", :k2=>[:v2], :k3=>{:k4=>"v4"}]'
    end

    it 'should be aliased to #inspect' do
      bh = Bihash.new
      bh.method(:inspect).must_equal bh.method(:to_s)
    end
  end

  describe '#hash' do
    it 'should provide a hash code' do
      b__h = Bihash[:k1 => 'v1', :k2 => 'v2']
      same = Bihash[:k2 => 'v2', :k1 => 'v1']
      diff = Bihash[:k1 => 'v2', :k2 => 'v1']
      b__h.hash.must_equal same.hash
      b__h.hash.wont_equal diff.hash
    end
  end

  describe '#dup' do
    it 'should make a copy of the bihash' do
      bh = Bihash[1 => :one]
      dup = bh.dup
      dup[2] = :two
      bh[2].must_equal nil
    end
  end

  describe '#clone' do
    it 'should make a copy of the bihash' do
      bh = Bihash[1 => :one]
      clone = bh.clone
      clone[2] = :two
      bh[2].must_equal nil
    end
  end

  describe '#select' do
    it 'should return a bihash with the items selected by the block' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      bh.select { |k1,k2| k1.even? }.must_equal Bihash[2 => :two, 4 => :four]
      bh.must_equal Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
    end

    it 'should return an enumerator if not given a block' do
      Bihash[1 => :one, 2 => :two].select.must_be_instance_of Enumerator
    end
  end

  describe '#reject' do
    it 'should return a bihash with the items not rejected by the block' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      bh.reject { |k1,k2| k1.even? }.must_equal Bihash[1 => :one, 3 => :three]
      bh.must_equal Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
    end

    it 'should return an enumerator if not given a block' do
      Bihash[1 => :one, 2 => :two].reject.must_be_instance_of Enumerator
    end
  end

  describe '#default' do
    it 'should not accept more than one argument' do
      -> { Bihash.new.default(1,2) }.must_raise ArgumentError
    end

    describe 'when there is not a default proc' do
      it 'should return the default' do
        bh1 = Bihash[:key => 'value']
        bh1.default.must_equal nil
        bh1.default(:not_a_key).must_equal nil
        bh1.default(:key).must_equal nil

        bh2 = Bihash.new(404)
        bh2[:key] = 'value'
        bh2.default.must_equal 404
        bh2.default(:not_a_key).must_equal 404
        bh2.default(:key).must_equal 404
      end
    end

    describe 'when there is a default proc' do
      it 'should return the default if called with no argument' do
        Bihash.new { 'proc called' }.default.must_equal nil
      end

      it 'should call the default proc when called with an argument' do
        bh = Bihash.new { |bihash, key| bihash[key] = key.to_s }
        bh[:key] = 'value'

        bh.default(:key).must_equal 'key'
        bh[:key].must_equal 'key'

        bh.default(404).must_equal '404'
        bh[404].must_equal '404'
      end
    end
  end

  describe '#default=' do
    it 'should set the default object' do
      bh = Bihash.new { 'proc called' }
      bh[:not_a_key].must_equal 'proc called'
      (bh.default = 404).must_equal 404
      bh[:not_a_key].must_equal 404
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      -> { Bihash.new.freeze.default = 404 }.must_raise RuntimeError
    end
  end

  describe '#default_proc' do
    it 'should return the default proc if it exists' do
      bh = Bihash.new { |bihash, key| bihash[key] = key }
      prc = bh.default_proc
      array = []
      prc.call(array, 2)
      array.must_equal [nil, nil, 2]
    end

    it 'should return nil if there is no default proc' do
      Bihash.new.default_proc.must_equal nil
      Bihash.new(404).default_proc.must_equal nil
    end
  end

  describe '#default_proc=' do
    it 'should set the default proc' do
      bh = Bihash.new(:default_object)
      bh[:not_a_key].must_equal :default_object
      (bh.default_proc = ->(bihash, key) { '404' }).must_be_instance_of Proc
      bh[:not_a_key].must_equal '404'
    end

    it 'should set the default value to nil if argument is nil' do
      bh = Bihash.new(:default_object)
      bh[:not_a_key].must_equal :default_object
      (bh.default_proc = nil).must_equal nil
      bh[:not_a_key].must_equal nil
    end

    it 'should raise TypeError if not given a non-proc (except nil)' do
      -> { Bihash.new.default_proc = :not_a_proc }.must_raise TypeError
    end

    it 'should raise TypeError given a lambda without 2 args' do
      -> { Bihash.new.default_proc = -> { '404' } }.must_raise TypeError
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      -> { Bihash[].freeze.default_proc = proc { '' } }.must_raise RuntimeError
    end
  end

  describe '#replace' do
    it 'should replace the contents of receiver with the contents of the arg' do
      receiver = Bihash[]
      original_id = receiver.object_id
      arg = Bihash[:key => 'value']
      receiver.replace(arg).must_equal Bihash[:key => 'value']
      arg[:another_key] = 'another_value'
      receiver.object_id.must_equal original_id
      receiver.must_equal Bihash[:key => 'value']
    end

    it 'should raise TypeError if arg is not a bihash' do
      -> { Bihash.new.replace({:key => 'value'}) }.must_raise TypeError
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      -> { Bihash.new.freeze.replace(Bihash[:k, 'v']) }.must_raise RuntimeError
    end
  end

  describe '#compare_by_identity' do
    it 'should set bihash to compare by identity instead of equality' do
      bh = Bihash.new.compare_by_identity
      key1, key2 = 'key', 'value'
      bh[key1] = key2
      bh['key'].must_equal nil
      bh['value'].must_equal nil
      bh[key1].must_equal 'value'
      bh[key2].must_equal 'key'
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      -> { Bihash.new.freeze.compare_by_identity }.must_raise RuntimeError
    end
  end

  describe '#compare_by_identity?' do
    it 'should indicate whether bihash is comparing by identity' do
      Bihash.new.compare_by_identity.compare_by_identity?.must_equal true
      Bihash.new.compare_by_identity?.must_equal false
    end
  end

  describe '#delete_if' do
    it 'should delete any pairs for which the block evaluates to true' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      bh_id = bh.object_id
      bh.delete_if { |key1, key2| key1.even? }.object_id.must_equal bh_id
      bh.must_equal Bihash[1 => :one, 3 => :three]
    end

    it 'should raise RuntimeError if called on a frozen bihash with a block' do
      -> { Bihash.new.freeze.delete_if { false } }.must_raise RuntimeError
    end

    it 'should return an enumerator if not given a block' do
      Bihash.new.freeze.delete_if.must_be_instance_of Enumerator
    end
  end

  describe '#keep_if' do
    it 'should retain any pairs for which the block evaluates to true' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      bh_id = bh.object_id
      bh.keep_if { |key1, key2| key1.even? }.object_id.must_equal bh_id
      bh.must_equal Bihash[2 => :two, 4 => :four]
    end

    it 'should raise RuntimeError if called on a frozen bihash with a block' do
      -> { Bihash.new.freeze.keep_if { true } }.must_raise RuntimeError
    end

    it 'should return an enumerator if not given a block' do
      Bihash.new.freeze.keep_if.must_be_instance_of Enumerator
    end
  end

  describe 'select!' do
    it 'should retain any pairs for which the block evaluates to true' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      bh_id = bh.object_id
      bh.select! { |key1, key2| key1.even? }.object_id.must_equal bh_id
      bh.must_equal Bihash[2 => :two, 4 => :four]
    end

    it 'should return nil if no changes were made to the bihash' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      bh.select! { |key1, key2| key1 < 5 }.must_equal nil
      bh.must_equal Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
    end

    it 'should raise RuntimeError if called on a frozen bihash with a block' do
      -> { Bihash.new.freeze.select! { true } }.must_raise RuntimeError
    end

    it 'should return an enumerator if not given a block' do
      Bihash.new.freeze.select!.must_be_instance_of Enumerator
    end
  end

  describe 'reject!' do
    it 'should delete any pairs for which the block evaluates to true' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      bh_id = bh.object_id
      bh.reject! { |key1, key2| key1.even? }.object_id.must_equal bh_id
      bh.must_equal Bihash[1 => :one, 3 => :three]
    end

    it 'should return nil if no changes were made to the bihash' do
      bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      bh.reject! { |key1, key2| key1 > 5 }.must_equal nil
      bh.must_equal Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
    end

    it 'should raise RuntimeError if called on a frozen bihash with a block' do
      -> { Bihash.new.freeze.reject! { false } }.must_raise RuntimeError
    end

    it 'should return an enumerator if not given a block' do
      Bihash.new.freeze.reject!.must_be_instance_of Enumerator
    end
  end
end
