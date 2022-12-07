#!/usr/bin/ruby

# Usage:
# ruby ./three-word-domains.rb <list of tlds.txt> < <text.txt>
#
#

class Triple
  def append(word)
  end
end

class DomainList
  attr_accessor :domainlist

  def load_domains(list)
    domainlist = list # TODO copy, not just reference
  end
  def domain_in_list(domain)
    domain.in? domainlist
  end
end

ARGF.each do |word|
  puts "Got it: " + word
end

