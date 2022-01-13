#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'awesome_print'
require 'json'
require 'date'
require 'ruby-progressbar'

repeated = false
i = 500
petition_id = 92038

def woman?(name)
  name.end_with? 'вна' or name.end_with? 'vna'
end

total = 0
women = 0

progressbar = ProgressBar.create(:title => 'Women',
    :starting_at => 15,
    :total => 30,
    :format => '%t: |%B| %p%% %a')

while ! repeated do
  doc = Nokogiri::HTML(URI.open("https://petition.president.gov.ua/petition/#{petition_id}/votes/#{i}"), nil, 'UTF-8')

  # TODO handle 404
  doc.search('//div[@class="table_cell name"]').each do |elem|
    name = elem.text
    total += 1

    if woman?(name)
      women += 1
    end
  end

  progressbar.total = total
  progressbar.progress = women

  i += 1
  sleep 1
end

t = Time.new
t_str = t.strftime "%Y-%m-%d_%H%M%S"
