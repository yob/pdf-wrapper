class Hash
  # raise an error if this hash has any keys that aren't in the supplied list
  # - borrowed from activesupport
  def assert_valid_keys(*valid_keys)
    unknown_keys = keys - [valid_keys].flatten
    raise(ArgumentError, "Unknown key(s): #{unknown_keys.join(", ")}") unless unknown_keys.empty?
  end
end
