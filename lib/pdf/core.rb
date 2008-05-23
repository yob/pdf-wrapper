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

unless [].respond_to?(:sum)

  module Enumerable
    # borrowed from active support. No need to pull that entire beast in as a dependency
    def sum(identity = 0, &block)
      return identity unless size > 0

      if block_given?
        map(&block).sum
      else
        inject { |sum, element| sum + element }
      end
    end
  end
end
