# coding: utf-8

class Hash
  # raise an error if this hash has any keys that aren't in the supplied list
  # - borrowed from activesupport
  def assert_valid_keys(*valid_keys)
    unknown_keys = keys - [valid_keys].flatten
    raise(ArgumentError, "Unknown key(s): #{unknown_keys.join(", ")}") unless unknown_keys.empty?
  end

  def only(*keys)
    keys.flatten!
    self.dup.reject { |k,v|
      !keys.include? k.to_sym
    }
  end
end

class Array
  def sum
    s = 0
    each do |v|
      s += v.to_i
    end
    s
  end
end
