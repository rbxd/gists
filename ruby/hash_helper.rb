class Hash
  # Pattern match function
  # Checks whether the pattern hash is a sub-hash of this instance
  def =~(pattern = {})
    return false unless pattern.kind_of?(self.class) || self.kind_of?(pattern.class)
    return true if self == pattern

    pattern.each do |k,v|
      # No key
      return false unless self.has_key?(k)

      # Type mismatch
      return false unless self[k].kind_of?(v.class) || v.kind_of?(self[k].class)

      if self[k] != v
        if v.kind_of?(Hash) || v.kind_of?(Array)
          # We can recursively pattern-match instances of Hash and Array
          return false unless self[k] =~ v
        else
          # Values don't match and we can't compare this type
          return false
        end
      end
    end
    true
  end
end
