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
  puts "Usage: ./votes_count.rb <petition id>"

  exit 1
end

petition_id = ARGV.shift

puts "Petition id: #{petition_id}"

def woman?(name)
  name.end_with? 'вна' or name.end_with? 'vna'
end

$total = 0
$women = 0
$t = Time.now

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

# TODO output petition URL and title

begin
  while ! repeated do
    doc = Nokogiri::HTML(URI.open("https://petition.president.gov.ua/petition/#{petition_id}/votes/#{i}"), nil, 'UTF-8')

    # TODO handle 404
    doc.search('//div[@class="table_cell name"]').each do |elem|
      name = elem.text
      $total += 1

      if woman?(name)
        $women += 1
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
