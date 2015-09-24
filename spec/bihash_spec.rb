gem 'minitest'
require 'minitest/spec'
require 'minitest/autorun'
require 'bihash'

describe Bihash do
  describe '#new' do
    it 'should be able to create an empty bihash' do
      assert_empty Bihash.new
    end

    it 'should convert a hash to a bihash' do
      bh = Bihash.new({:key => 'value'})
      bh[:key].must_equal 'value'
      bh['value'].must_equal :key
    end

    it 'should not accept hashes that would result in duplicate keys' do
      -> { Bihash.new({:k1 => 'val', :k2 => 'val'}) }.must_raise ArgumentError
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
  end
end
