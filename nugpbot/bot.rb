#!/usr/bin/ruby

# TODO kick
# TODO pluginize

require 'cinch'

class NSFWNinja
	include Cinch::Plugin

	match /(\.jpg|\.jpeg|\.png)/, use_prefix: false

	def execute(m)
		debug("NSFW: New matching msg: #{m}")
	end
end

class User < Struct.new(:who, :where, :time, :idle, :nugp)
  def to_s
    "[#{time.asctime}] #{who} was seen in #{where}."
  end

  def expected_idle
    (idle + (Time.now-time)).to_i
  end
end

class KnownUser < Struct.new(:name, :user, :host)
  def to_s
    "#{name}!#{user}@#{host}"
  end
end

$users = {}
$known = {}
$known['MastaYoda'] = KnownUser.new('MastaYoda|2','~kvirc',     '37.212.178.169')
$known['Cordon']    = KnownUser.new('Cordon',     '~c',         '91.205.216.175')
$known['ctype']     = KnownUser.new('ctype',      '~ctype',     '243.ip-167-114-114.net')
$known['SergK']     = KnownUser.new('SergK',      '~sergk',     '88.214.207.62')
$known['z0l']       = KnownUser.new('z0l',        '~papaz0l',   '46.101.211.29')
$known['virus']     = KnownUser.new('virus',      'virus',      'nat.capsida.net')
$known['green']     = KnownUser.new('green',      '~green',     'linuxhacker.ru')
$known['Baklan']    = KnownUser.new('Baklan',     'baklan',     'nest.pro-manage.net')
$known['Promim']    = KnownUser.new('Promim',     '~Lang',      '212.rtOct.bfbxC.in-addr')
$known['Kabanec']   = KnownUser.new('Kabanec',    'kabanec',    'nest.pro-manage.net')
$known['button_']   = KnownUser.new('button_',    '~~me',       'my.batovsky.com')
$known['alt']       = KnownUser.new('alt',        'alt',        'nest.pro-manage.net')
$known['moronoid']  = KnownUser.new('moronoid',   'nick',       'ist.zzzz.io')
$known['vad']       = KnownUser.new('vad',        '~vad',       '46.101.188.226')
$known['kyxap']     = KnownUser.new('kyxap',      'kyxap',      'nest.pro-manage.net')
$known['crabcore']  = KnownUser.new('liquidfreak','~crabcore',  '185.14.31.80')
$known['Simfi']     = KnownUser.new('Simfi',      '~sergk',     '88.214.207.62')
$known['maple']     = KnownUser.new('maple',      '~maple',     '88.214.195.147')
$known['stuff']     = KnownUser.new('stuff',      '~stuff',     'gw.teamave.com')
$known['shepilove'] = KnownUser.new('shepilove',  '~shepilove', 'obdbackup.datagroup.com.ua')
$known['smer']			= KnownUser.new('smer|2',  		'~smersmer',	'37-147-58-132.broadband.corbina.ru')
$known['vlad']		  = KnownUser.new('grisha1',		'~grisha',		'213.231.51.57.pool.breezein.net')
$known['UKRop']			= KnownUser.new('UKRop',			'~UA',				'213.59.174.26')

def known_user(user)
  found = { matched: 0, user: nil }

  $known.each do |k,v|
    matched = 0
    matched += 1 if v['name'] == user.name
    matched += 1 if v['user'] == user.user
    matched += 1 if v['host'] == user.host

    if matched > found[:matched]
      debug("New match: %s (i: %i)" % [v, matched])
      found = { matched: matched, user: v }
    end
  end

  debug("Found Known User: %s (i: %i)" % [found[:user], found[:matched]])

  found[:user]
end

def refresh_user(user)
  debug("Updating whois for %s" % user.mask)
  user.refresh

  sleep 0.1 while user.in_whois
  debug("Updated whois for %s" % user.mask)

  user
end

def check_user(user)
  user = refresh_user(user)

  if user.idle > 30
    debug("User %s is not nugp (idle for %i)" % [user.mask, user.idle])
    return false
  elsif ($users[user.nick].expected_idle - user.idle).abs > 3
    debug("User %s is nugp (idle: %i, expected: %i)" % [user.mask, user.idle, $users[user.nick].expected_idle])
    return true
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = SRV_ADDR
    c.port = 7770
    c.ssl.use = true
    c.channels = [ SRV_CHANNEL ]
    c.password = SRV_PASSWORD
    c.nick = SRV_BNC_USER
    c.user = SRV_USERNAME
		c.plugins.plugins = [NSFWNinja]
  end

  on :join do |m|
    if m.user.nick == bot.nick
      debug("Hello, it's me: %s" % m.user.mask)
      next
    end

    unless bot.channels.include?(m.channel.name)
      debug("Not reacting to join - not controlling channel %s" % m.channel.name)
      next
    end

    if f = known_user(m.user)
			msg = "Known user joined: %s (matched %s)" % [ m.user.mask, f]
      info(msg)
			Cinch::UserList.new(bot).find_ensured('moronoid').notice(msg)
      next
    end

    refresh_user(m.user)

    if ! $users.has_key?(m.user.nick) || ! $users[m.user.nick].is_a?(User)
      $users[m.user.nick] = User.new(m.user.nick, m.channel, Time.now, m.user.idle, 0)
    end

    info("Starting idle checks for %s (n: %i)" % [ m.user.mask, $users[m.user.nick]['nugp']])

    5.times do |i|
      sleep 10

      # check that the user is still on the channel
      if ! m.user || ! m.user.channels.include?(m.channel.name)
        debug("%s is no longer in the channel %s" % [m.user.name, m.channel.name])
        break
      end

      if check_user(m.user)
        $users[m.user.nick]['nugp'] += 1
        debug("%s: nugp++" % m.user.mask) unless $users[m.user.nick]['nugp'] > 0
      else
        $users[m.user.nick]['nugp'] -= 1
        debug("%s: nugp--" % m.user.mask) if $users[m.user.nick]['nugp'] > 0
      end
    end

		next if ! m.user || ! m.user.channels.include?(m.channel.name)

    if $users[m.user.nick]['nugp'] > 0
      info("User %s is nugp after 10 checks" % m.user.nick)
      prefix = [
				"кажется, %s - nugp",
				"выглядит так что %s - nugp",
                "по-моему, %s - nugp",
				"думаю, %s - nugp",
				"%s, на тебя жаловались",
				"%s, на тебя жаловались, что ты nugp"
			]
      msg = prefix[(rand*100).to_i%prefix.length] % [ m.user.nick ]
      m.channel.send(msg)

      msg = msg + " (%s, n: %i)" % [ m.user.mask, $users[m.user.nick]['nugp']]
      Cinch::UserList.new(bot).find_ensured('moronoid').send(msg)
    else
			msg = "User %s is fine after 10 checks (n: %i)" % [ m.user.mask, $users[m.user.nick]['nugp']]
      info(msg)
      Cinch::UserList.new(bot).find_ensured('moronoid').notice(msg)

    end
  end

  # FIXME kicked?
  #on :leaving do |m, user|
  #  $users[m.user.nick] = nil
  #end

  on :message do |m|
    if $users.has_key?(m.user.nick)
      debug("Updating user info - %s" % m.user.nick)
      $users[m.user.nick]['time'] = Time.now
      $users[m.user.nick]['idle'] = 0
    else
      debug("No records - creating for %s" % m.user.nick)
      $users[m.user.nick] = User.new(m.user.nick, m.channel, Time.now, 0)
    end
  end
end

bot.loggers << Cinch::Logger::FormattedLogger.new(File.open("/tmp/log.log", "a"))
bot.loggers.level = :debug
bot.loggers.first.level  = :info

bot.start
