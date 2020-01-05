#!/usr/bin/ruby
#
# Publish server presence to ZooKeeper.
# Creates an ephemeral sequential node, for example with default settings:
#   /cluster/nodes/base0000001
#
# Requirements:
#   gem install zk logger
#

require 'optparse'
require 'zk'
require 'json'
require 'socket'
require 'logger'

options = {
  daemonize:   false,
  logfile:     nil,
  verbose:     false,
  zk_addr:     '127.0.0.1:2181',
  node_prefix: '/cluster/nodes',
  node_role:   'base'
}

version        = '0.0.1'
daemonize_help = 'run daemonized in the background (default: false)'
logfile_help   = 'log file name'
verbose_help   = 'Verbose logging'
zk_addr_help   = 'ZooKeeper server address, e.g. 10.0.0.1:2181'
prefix_help    = 'Node prefix, e.g. /cluster/nodes'
node_role_help = 'Node role, <web|db|lb> (default: base)'

op = OptionParser.new
op.banner =  'ZooKeeper presence announcement daemon.'
op.separator ''
op.separator "Usage: #{$PROGRAM_NAME} [options]"
op.separator ''

op.separator 'General options:'
op.on('-d', '--daemonize',   daemonize_help) {         options[:daemonize] = true  }
op.on('-l', '--log LOGFILE', logfile_help) { |value| options[:logfile]   = value }
op.on('-V', '--verbose',     verbose_help) {         options[:verbose]   = true  }
op.on('-z', '--zk host:port', zk_addr_help) { |value| options[:zk_addr]   = value }
# TODO check PREFIX
op.on('-p', '--prefix PREFIX', prefix_help) { |value| options[:node_prefix] = value }
op.on('-r', '--role ROLE',   node_role_help) { |value| options[:node_role] = value }
op.separator ''

op.separator 'Common options:'
op.on('-h', '--help') do
  puts op.to_s
  exit
end
op.on('-v', '--version') do
  puts version
  exit
end
op.separator ''

op.parse!(ARGV)

def zk_create_path(zk_instance, path)
  require 'zk'

  fail IOError, 'Not connected to ZooKeeper' unless zk_instance.connected?
  fail ArgumentError, 'Path is incorrect' unless path.is_a?(String) && path.start_with?('/')

  path_nodes = path.split('/')
  i = 1

  # Recursively create path
  until zk_instance.exists?(path) || i == path_nodes.size
    cpath = path_nodes[0..i].join('/')
    zk_instance.create(cpath) unless zk_instance.exists?(cpath)
    i += 1
  end

  zk_instance.exists?(path)
end

if options[:logfile]
  File.open(options[:logfile], ::File::WRONLY | File::APPEND | ::File::CREAT)
  log = Logger.new(options[:logfile])
else
  log = Logger.new(STDOUT)
end

log.level = options[:verbose] ? Logger::DEBUG : Logger::INFO

log.info 'Connecting to ZooKeeper'

# Connect to ZooKeeper
begin
  zoo = ZK.new(options[:zk_addr])
  log.info('Connected to ZooKeeper server %s' % options[:zk_addr])
  fail 'Connection failed' unless zoo.connected?
rescue => err
  log.fatal('Cannot connect to ZooKeeper server %s' % options[:zk_addr])
  log.fatal(err)
  exit 1
end

# Check if the prefix exists and create otherwise
unless zoo.exists?(options[:node_prefix])
  log.debug("Node prefix '#{options[:node_prefix]}' doesn't exist. Creating.")

  if zk_create_path(zoo, options[:node_prefix])
    log.debug("Node prefix '#{options[:node_prefix]}' created")
  else
    log.fatal("Failed to create '#{options[:node_prefix]}' prefix path. Exiting'")
    exit 2
  end
end

if options[:daemonize]
  log.debug('Daemonizing...')

  # Double fork with session detachment
  exit if fork
  Process.setsid
  exit if fork
  Dir.chdir '/'

  log.debug('Reopening inherited ZooKeeper connection.')
  zoo.reopen
  log.debug('Checking that ZooKeeper is still connected: %s' % zoo.connected?)

  @quit = false

  trap(:TERM) do   # graceful shutdown of run! loop
    @quit = true
  end
end

zk_node_name = ::File.join(options[:node_prefix], options[:node_role])

until @quit
  unless zoo.exists?(zk_node_name)
    zk_node_content = {
      hostname: Socket.gethostname
    }
    log.info("Creating ephemeral sequential node '#{zk_node_name}'")
    zk_node_name = zoo.create(zk_node_name,
                              zk_node_content.to_json,
                              mode: :ephemeral_sequential)
    log.info("Created ephemeral sequential node '#{zk_node_name}'")
  end

  sleep(2)
end

log.info('Exiting.')
