#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'awesome_print'
require 'json'
require 'date'

def parse_daterange(dates)
  res = {
    start: nil,
    end: nil
  }

  # "з 08.10 по 21.10"
  m = dates.match(/з (\d+\.\d+) по (\d+\.\d+)*/i)

  if m and m[1] and m[2]
    res[:start] = Date.strptime(m[1], '%d.%m')
    res[:end] = Date.strptime(m[2], '%d.%m')
  end

  res
end


def parse_item(item)
  salep = item.css('div.percent-amount').text.delete("\t\r\n").strip
  name = item.css('a[@class="product-item-link"]').text.delete("\t\r\n").strip
  kind = name.split.first
  dates = parse_daterange(item.css('div.mb-time-countdown-container').text.delete("\t\r\n").strip)
  price = item.css('span[data-price-type="finalPrice"]/@data-price-amount').text
  href = item.css('a[@class="product-item-link"]').first['href']

  {
    salep: salep,
    kind: kind,
    name: name,
    dates: dates,
    price: price,
    href: href
  }
end

@res = Hash.new
repeated = false
i = 1

while ! repeated do
  doc = Nokogiri::HTML(URI.open("https://novus.ua/sales/alkogol.html?p=#{i}"))

  doc.search('//*[@id="layer-product-list"]/div[1]/ol/li').each do |item|
    parsed = parse_item(item)
    parsed[:page] = i

    unless @res.has_key? parsed[:kind]
      @res[ parsed[:kind] ] = Hash.new
    end

    if @res[ parsed[:kind] ].has_key? parsed[:name]
      # Stop if there's a duplicate
      puts "Found duplicate: #{parsed}"
      repeated = true
    else
      @res[ parsed[:kind] ][ parsed[:name] ] = parsed
    end
  end
  puts "Finished pass ##{i}"

  i += 1
  sleep 1
end

t = Time.new
t_str = t.strftime "%Y-%m-%d_%H%M%S"

File.open("./" + t_str + "-out.json","w") do |f|
  f.write(@res.to_json)
end
