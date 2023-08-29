#!/usr/bin/ruby

#
# Simple script to reset the data stored in memcache
#

require 'dalli'

mc_opts = {
  compress: false,
  raw: true
}

mc = Dalli::Client.new("127.0.0.1:11211", mc_opts)

puts mc.get('zl34_ping')

data = '{"lights":"off","time":1671872400,"since":1671872400,"endpoints":[{"name":"Вхід 1","up":false},{"name":"Вхід 3","up":false}]}'
data = '{"lights":"on","time":1676084684,"since":1676084684,"endpoints":[{"name":"Вхід 1","up":true}]}'
mc.set('zl34_ping', data, 0, { :raw => true})
