gem 'minitest'
require 'minitest/spec'
require 'minitest/autorun'
require 'bihash'

describe Bihash do
  describe '#new' do
    it 'should convert a hash to a bihash' do
      bh = Bihash.new({key: 'value'})
      bh[:key].must_equal 'value'
      bh['value'].must_equal :key
    end
  end
end
