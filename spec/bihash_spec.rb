gem 'minitest'
require 'minitest/spec'
require 'minitest/autorun'
require 'bihash'

describe Bihash do
  describe '::new' do
    it 'should be able to create an empty bihash' do
      bh = Bihash.new
      assert_empty bh.instance_variable_get(:@forward)
      assert_empty bh.instance_variable_get(:@reverse)
    end

    it 'should convert a hash to a bihash' do
      bh = Bihash.new({:key => 'value'})
      bh[:key].must_equal 'value'
      bh['value'].must_equal :key
    end

    it 'should not accept a hash with duplicate values' do
      -> { Bihash.new({:k1 => 'val', :k2 => 'val'}) }.must_raise ArgumentError
    end

    it 'should accept a hash where a key equals its value' do
      Bihash.new({:key => :key})[:key].must_equal :key
    end

    it "should maintain the returned value's id if key-value pairs are equal" do
      key, value = [], []
      bh = Bihash.new({key => value})
      bh[key].object_id.must_equal value.object_id
      bh[value].object_id.must_equal value.object_id
    end
  end

  describe '#[]' do
    it 'should return falsey values correctly' do
      bh1 = Bihash.new({nil => false})
      bh1[nil].must_equal false
      bh1[false].must_equal nil

      bh2 = Bihash.new({false => nil})
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
      bh = Bihash.new({1 => 'one', 2 => 'two'})
      bh[1] = 'uno'
      bh[1].must_equal 'uno'
      bh['uno'].must_equal 1
      bh['one'].must_equal nil
    end

    it "should maintain the returned value's id if key-value pairs are equal" do
      key, value = [], []
      bh = Bihash.new
      bh[key] = value
      bh[key].object_id.must_equal value.object_id
      bh[value].object_id.must_equal value.object_id
    end
  end

  describe '#delete' do
    it 'should remove both keys' do
      bh1 = Bihash.new({:key => 'value'})
      bh1.delete(:key)
      bh1[:key].must_equal nil
      bh1['value'].must_equal nil
      bh2 = Bihash.new({:key => 'value'})
      bh2.delete('value')
      bh1[:key].must_equal nil
      bh1['value'].must_equal nil
    end
  end
end
