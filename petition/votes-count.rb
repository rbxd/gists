#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'awesome_print'
require 'json'
require 'date'
require 'ruby-progressbar'

repeated = false
i = 1

# TODO support full URL
if ARGV.length != 1
  puts "Usage: ./votes_count.rb <petition id or url>"

  exit 1
end

arg = ARGV.shift

if m = arg.match(/^(\d+)$/)
  petition_url = "https://petition.president.gov.ua/petition/#{arg}"
else
  petition_url = arg
end

def woman?(name)
  name.end_with? 'вна' or name.end_with? 'лінічна'
end

def man?(name)
  name.end_with? 'вич' or name.end_with? 'лліч'
end

$total = 0
$women = 0
$t = Time.now

puts "Petition: #{petition_url}"

# TODO handle 404
doc = Nokogiri::HTML(URI.open("#{petition_url}"), nil, 'UTF-8')
title = doc.at('h1').text
puts "Title: #{title}"

progressbar = ProgressBar.create(:title => '  Women',
    :length => 80,
    :starting_at => 15,
    :total => 30,
    :format => '%t: |%B| %p%% %a')

def final_stats(exception)
    puts "\n"
    puts "Elapsed time: #{Time.at(Time.now-$t).utc.strftime("%H:%M:%S")}"
    puts "Total votes: #{$total}, Women: #{$women} (#{(100*$women.to_f/$total).round()}% of all votes)"
end

begin
  while ! repeated do
    doc = Nokogiri::HTML(URI.open("#{petition_url}/votes/#{i}"), nil, 'UTF-8')

    # TODO handle 404
    doc.search('//div[@class="table_cell name"]').each do |elem|
      name = elem.text
      $total += 1

      if woman?(name)
        $women += 1
      elsif !man?(name)
        puts "\n WARN: #{name}"
      end
    end

    progressbar.total = $total
    progressbar.progress = $women

    i += 1
    sleep 1
  end
rescue Interrupt, Exception => e
    final_stats(e)
end

t = Time.new
t_str = t.strftime "%Y-%m-%d_%H%M%S"
