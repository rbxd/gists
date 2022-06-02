#!/usr/bin/ruby

# Practice with lazy init

n = 100

def isprime(num)
    (num==0 || num==1) ? false : (2...num).none? {|x| num%x==0}
end

def ispalindrome(num)
    num.to_s == num.to_s.reverse
end

palindromic_prime_array = -> (array_size) do
    current_number = 1
    1.upto(Float::INFINITY).lazy.map do |x|
        current_number += 1
        current_number += 1 until ispalindrome(current_number) && isprime(current_number)
        current_number
    end.first(array_size)
end

puts palindromic_prime_array.(n).to_s
