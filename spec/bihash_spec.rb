gem 'minitest'
require 'minitest/spec'
require 'minitest/autorun'
require 'bihash'

describe Bihash do
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

    it 'should not accept both an object and a block' do
      -> { Bihash.new('default 1') { 'default 2' } }.must_raise ArgumentError
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

    it 'should accept a hash where a key equals its value' do
      bh = Bihash[:key => :key]
      bh.must_be_instance_of Bihash
      bh[:key].must_equal :key
    end

    it "should always return the value object if key-value pairs are equal" do
      key, value = [], []
      bh = Bihash[key => value]
      bh.must_be_instance_of Bihash
      bh[key].object_id.must_equal value.object_id
      bh[value].object_id.must_equal value.object_id
    end

    it "should accept an even number of arguments" do
      bh = Bihash[:k1, 1, :k2, 2]
      bh.must_be_instance_of Bihash
      bh[:k1].must_equal 1
      bh[:k2].must_equal 2
      bh[1].must_equal :k1
      bh[2].must_equal :k2
    end

    it "should accept an array of key-value pairs packaged in arrays" do
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

    it 'should return nil if the object does not repond to #to_hash' do
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
      bh.key?('one').must_equal false
    end

    it "should always return the value object if key-value pairs are equal" do
      key, value = [], []
      bh = Bihash.new
      bh[key] = value
      bh[key].object_id.must_equal value.object_id
      bh[value].object_id.must_equal value.object_id
    end
  end

  describe '#delete' do
    it 'should remove both keys' do
      bh1 = Bihash[:key => 'value']
      bh1.delete(:key)
      bh1.key?(:key).must_equal false
      bh1.key?('value').must_equal false

      bh2 = Bihash[:key => 'value']
      bh2.delete('value')
      bh2.key?(:key).must_equal false
      bh2.key?('value').must_equal false
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

    it 'should be aliased to #has_key?' do
      Bihash.new.method(:has_key?).original_name.must_equal :key?
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
  end
end
