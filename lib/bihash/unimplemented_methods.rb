require 'set'

class Bihash
  UNIMPLEMENTED_METHODS = Set[
    # expected to only deal with half the hash: keys or values
    'keys',
    'values',
    'each_key',
    'each_value',
    'transform_values',
    'transform_values!',
    # O(n) reverse lookups
    'key',
    'index',
    'rassoc',
    'value?',
    'has_value?',
    # meaningless on bihash as both sides already hashed
    'invert'
  ]

  def respond_to?(method, private = false)
    UNIMPLEMENTED_METHODS.include?(method.to_s) ? false : super
  end

  UNIMPLEMENTED_METHODS.each do |method|
    define_method(method) do |*|
      raise NoMethodError, "Bihash##{method} not implemented"
    end
  end
end
