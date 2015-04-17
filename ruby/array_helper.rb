class Array
  # Pattern match function
  # Checks whether the pattern array is a sub-array of this instance
  def =~(pattern = [])
    return false unless pattern.kind_of?(self.class) || self.kind_of?(pattern.class)
    return true if self == pattern
    return true if pattern - self == []

    pattern.each_index do |i|
      # Type mismatch
      return false unless self[i].kind_of?(pattern[i].class) || pattern[i].kind_of?(self[i].class)

      if pattern[i] != self[i]
        if pattern[i].kind_of?(Hash) || pattern[i].kind_of?(Array)
          return false unless self[i] =~ pattern[i]
        else
          return false
        end
      end
    end

    true
  end
end
