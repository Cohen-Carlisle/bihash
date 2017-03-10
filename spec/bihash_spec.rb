require 'spec_helper'

describe Bihash do
  it 'should be enumerable' do
    Bihash.must_include Enumerable
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

  describe '#==' do
    it 'should return true when two bihashes have the same pairs' do
      bh1, bh2 = Bihash[:k1 => 1, :k2 => 2], Bihash[2 => :k2, 1 => :k1]
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

  describe '#clone' do
    it 'should make a copy of the bihash' do
      bh = Bihash[1 => :one]
      clone = bh.clone
      clone[2] = :two
      bh[2].must_equal nil
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
      enum = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four].delete_if
      enum.must_be_instance_of Enumerator
      enum.each { |k1, k2| k1.even? }.must_equal Bihash[1 => :one, 3 => :three]
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
      enum = Bihash[:k1 => 'v1', :k2 => 'v2'].each
      enum.must_be_instance_of Enumerator
      enum.each { |pair| pair }.must_equal Bihash[:k1 => 'v1', :k2 => 'v2']
    end

    it 'should be aliased to #each_pair' do
      bh = Bihash.new
      bh.method(:each_pair).must_equal bh.method(:each)
    end
  end

  describe '#empty?' do
    it 'should indicate if the bihash is empty' do
      Bihash.new.empty?.must_equal true
      Bihash[:key => 'value'].empty?.must_equal false
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

    describe 'when the key is not found' do
      it 'should raise KeyError when not supplied any default' do
        -> { Bihash[].fetch(:not_a_key) }.must_raise KeyError
      end

      it 'should return the second arg when supplied with one' do
        Bihash[].fetch(:not_a_key, :second_arg).must_equal :second_arg
      end

      it 'should call the block if supplied with one' do
        Bihash[].fetch(404) { |k| "#{k} not found" }.must_equal '404 not found'
      end
    end
  end

  describe '#fetch_values' do
    it 'should return an array of values corresponding to the given keys' do
      Bihash[1 => :one, 2 => :two].fetch_values(1, 2).must_equal [:one, :two]
      Bihash[1 => :one, 2 => :two].fetch_values(:one, :two).must_equal [1, 2]
      Bihash[1 => :one, 2 => :two].fetch_values(1, :two).must_equal [:one, 2]
    end

    it 'should raise a KeyError if any key is not found' do
      -> { Bihash.new.fetch_values(404) }.must_raise KeyError
    end

    it 'should not duplicate entries if a key equals its value' do
      Bihash[:key => :key].fetch_values(:key).must_equal [:key]
    end

    it 'should return an empty array with no args' do
      Bihash[:key => 'value'].fetch_values.must_equal []
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

  describe '#hash' do
    it 'should return the same hash code if two bihashes have the same pairs' do
      bh1, bh2 = Bihash[:k1 => 1, :k2 => 2], Bihash[2 => :k2, 1 => :k1]
      bh1.hash.must_equal bh2.hash
    end
  end

  describe '#include?' do
    it 'should indicate if the bihash contains the argument' do
      bh = Bihash[:key => 'value']
      bh.include?(:key).must_equal true
      bh.include?('value').must_equal true
      bh.include?(:not_a_key).must_equal false
    end

    it 'should be aliased to #has_key?, #key?, and #member?' do
      bh = Bihash.new
      bh.method(:has_key?).must_equal bh.method(:include?)
      bh.method(:key?).must_equal bh.method(:include?)
      bh.method(:member?).must_equal bh.method(:include?)
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
      enum = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four].keep_if
      enum.must_be_instance_of Enumerator
      enum.each { |k1, k2| k1.even? }.must_equal Bihash[2 => :two, 4 => :four]
    end
  end

  describe '#length' do
    it 'should return the number of pairs in the bihash' do
      Bihash[1 => :one, 2 => :two].length.must_equal 2
    end
  end

  describe '#merge' do
    it 'should merge bihashes, assigning each arg pair to a copy of reciever' do
      receiver = Bihash[:chips => :salsa, :milk => :cookies, :fish => :rice]
      original_receiver = receiver.dup
      argument = Bihash[:fish => :chips, :soup => :salad]
      return_value = Bihash[:milk => :cookies, :fish => :chips, :soup => :salad]
      receiver.merge(argument).must_equal return_value
      receiver.must_equal original_receiver
    end

    it 'should raise TypeError if arg is not a bihash' do
      -> { Bihash.new.merge({:key => 'value'}) }.must_raise TypeError
    end
  end

  describe '#merge!' do
    it 'should merge bihashes, assigning each arg pair to the receiver' do
      receiver = Bihash[:chips => :salsa, :milk => :cookies, :fish => :rice]
      argument = Bihash[:fish => :chips, :soup => :salad]
      return_value = Bihash[:milk => :cookies, :fish => :chips, :soup => :salad]
      receiver.merge!(argument).must_equal return_value
      receiver.must_equal return_value
    end

    it 'should raise RuntimeError if called on a frozen bihash' do
      -> { Bihash.new.freeze.merge!(Bihash.new) }.must_raise RuntimeError
    end

    it 'should raise TypeError if arg is not a bihash' do
      -> { Bihash.new.merge!({:key => 'value'}) }.must_raise TypeError
    end

    it 'should be aliased to #update' do
      bh = Bihash.new
      bh.method(:update).must_equal bh.method(:merge!)
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

    it 'should raise RuntimeError if called when key duplicated outside pair' do
      bh = Bihash[[1], [2], [3], [4]]
      (bh[[4]] << 1).shift
      -> { bh.rehash }.must_raise RuntimeError
    end
  end

  describe '#reject' do
    describe 'should return a bihash with items not rejected by the block' do
      it 'when some items are rejected' do
        bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
        bh.reject { |k1,k2| k1.even? }.must_equal Bihash[1 => :one, 3 => :three]
        bh.must_equal Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      end

      it 'when no items are rejected' do
        bh = Bihash[1 => :one, 3 => :three, 5 => :five, 7 => :seven]
        bh.reject { |k1,k2| k1.even? }.must_equal bh
        bh.must_equal bh
      end
    end

    it 'should return an enumerator if not given a block' do
      enum = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four].reject
      enum.must_be_instance_of Enumerator
      enum.each { |k1,k2| k1.even? }.must_equal Bihash[1 => :one, 3 => :three]
    end
  end

  describe '#reject!' do
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
      enum = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four].reject!
      enum.must_be_instance_of Enumerator
      enum.each { |k1, k2| k1.even? }.must_equal Bihash[1 => :one, 3 => :three]
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

  describe '#select' do
    describe 'should return a bihash with items selected by the block' do
      it 'when only some items are selected' do
        bh = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
        bh.select { |k1,k2| k1.even? }.must_equal Bihash[2 => :two, 4 => :four]
        bh.must_equal Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four]
      end

      it 'when all items are selected' do
        bh = Bihash[2 => :two, 4 => :four, 6 => :six, 8 => :eight]
        bh.select { |k1,k2| k1.even? }.must_equal bh
        bh.must_equal bh
      end
    end

    it 'should return an enumerator if not given a block' do
      enum = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four].select
      enum.must_be_instance_of Enumerator
      enum.each { |k1,k2| k1.even? }.must_equal Bihash[2 => :two, 4 => :four]
    end
  end

  describe '#select!' do
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
      enum = Bihash[1 => :one, 2 => :two, 3 => :three, 4 => :four].select!
      enum.must_be_instance_of Enumerator
      enum.each { |k1, k2| k1.even? }.must_equal Bihash[2 => :two, 4 => :four]
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

  describe '#size' do
    it 'should return the number of pairs in the bihash' do
      Bihash[1 => :one, 2 => :two].size.must_equal 2
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

    it 'should be an alias of #to_hash' do
      bh = Bihash.new
      bh.method(:to_hash).must_equal bh.method(:to_h)
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

  describe '#initialize' do
    it 'should raise RuntimeError if called on a frozen bihash' do
      -> { Bihash.new.freeze.send(:initialize) }.must_raise RuntimeError
    end
  end
end
