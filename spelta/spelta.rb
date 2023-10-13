#!/usr/bin/ruby

require 'dotenv'
require 'httparty'
require 'json'
require 'telegram/bot'

Dotenv.load

HLIB_URL = 'https://spelta.choiceqr.com/api/public/menu/section/section:hlib?lang=uk'
USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/120.0'
REFERER = 'https://spelta.choiceqr.com/section:hlib'
PREV_ITEMS = "/tmp/spelta-items.txt"

TG_CHAT_ID = ENV['TG_CHAT_ID']
TG_BOT_TOKEN = ENV['TG_BOT_TOKEN']

begin
  res = HTTParty.get(HLIB_URL,
    :query => {
      lang: 'uk'
    },
    :headers => {
      "User-Agent" => USER_AGENT,
      "Referer" => REFERER,
      "Content-Type": "application/json"
    }
  )

  items = res.parsed_response['menu'].map { |x| x['name'] }.sort
rescue
  # if for watever reasons we can't get it - assume it's empty
  items = []
end

prev_items = []

if File.exist?(PREV_ITEMS)
  File.open(PREV_ITEMS, "r") do |f|
    f.each_line do |line|
      prev_items << line
    end
  end
end

def compare_arrays(a, b)
  added = []
  removed = []

  added = b.sort.reject { |_| a.include? _ }
  removed = a.sort.reject { |_| b.include? _ }

  return added, removed
end

added, removed = compare_arrays(prev_items, items)

msg = []

unless added.empty?
  msg << "*Додано:*"
  added.each { |item| msg << "- #{item}" }
  msg << ""
end

unless removed.empty?
  msg << "*Закінчилося:*"
  removed.each { |item| msg << "- #{item}" }
end

unless msg.empty?
  Telegram::Bot::Client.run(TG_BOT_TOKEN) do |bot|
    bot.api.send_message(chat_id: TG_CHAT_ID, text: msg.join("\n"), parse_mode: 'markdown')
  end
end

File.open(PREV_ITEMS, "w") do |file|
  file.write items.join("\n")
end
