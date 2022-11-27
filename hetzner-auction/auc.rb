#!/usr/bin/ruby

require 'json'
require 'date'
require 'httparty'

LIVE_DATA_URL='https://www.hetzner.com/_resources/app/jsondata/live_data_sb.json?m='

data = nil

# if there's a command line argument - read JSON and do the calculation
if ARGV.length == 1
  data = JSON.parse( File.read(ARGV[0]) )
else
  url = LIVE_DATA_URL + DateTime.now.strftime('%Q')
  response = HTTParty.get(url)
  data = response.parsed_response
end

if ! data or ! data.has_key? 'server'
  puts "Could not load/parse auction data"
  exit 1
end

filtered = data['server'].select do |el|
  next if el['price'].to_f > 60 or el['ram_size'] < 32
  next unless el['specials'].include? 'SSD'

  true
#      "key": 1285511,
#      "name": "SB53",
#      "cpu": "Intel Xeon E3-1275V6",    "cpu_benchmark": 8564,        "cpu_count": 1 -> always 1,
#      "is_highio": false,
#      "is_ecc": true,
#      "ram_size": 64,                        "ram_hr": "64 GB",
#      "price": "44.5378",               "price_v": "44.5378",         "fixed_price": false,
#      "hdd_size": 4096,                 "hdd_count": 2,               "hdd_hr": "2x 4 TB",
#      "next_reduce": 1994,              "next_reduce_hr": "00h 33m",  "next_reduce_timestamp": 1600879038,
#      "datacenter": [ "HEL1-DC4", "HEL", "NBG1-DC1", "NBG", "FSN1-DC8", "FSN" ],
#      "specials": [ "ECC", "Ent. HDD", "iNIC", "NVMe SSD", "DC SSD", "SSD", "SAS", "HWR", "Red.PS" ],
#      "specialHdd": "Ent. HDD",
#      "freetext": "4x RAM 16384 MB DDR4 ECC 2x HDD SATA 4,0 TB Enterprise NIC 1 Gbit - Intel I219-LM 2x 4 TB Intel Xeon E3-1275V6 SB53 1285511 ECC Ent. HDD iNIC"
end

sorted = filtered.sort { |a,b| a['price'].to_f <=> b['price'].to_f }

def format_price(price)
  "%.2f" % price.to_f.round(2)
end

sorted.each do |el|
  puts "price: " + format_price(el['price']) +
    "(#{el['fixed_price'] ? "FP" : "  " }) " +
    "DC: #{el['datacenter'][1]} " +
    "RAM: #{el['ram_size']} " +
    "CPU: #{el['cpu']}(#{el['cpu_benchmark']}) " +
    "#{el['specials'].join(" ")}" #, descr: #{el['freetext']}"
end
