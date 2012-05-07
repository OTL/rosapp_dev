require 'sinatra/base' # sinatra
require 'ros'
require 'set'
require 'em-websocket'# eventmachine
require 'thin'

EventMachine.run do

class MyApp < Sinatra::Base
  def initialize(*args)
    super(*args)
    @master = ROS::MasterProxy.new('/ros', ENV['ROS_MASTER_URI'], 'dummy')
    @node = ROS::Node.new('/this_app')

    @topics = []
    @services = []
    @nodes = []
    @menu = ['node', 'topic', 'service']
    @active = 'node'
    @sockets = []

    @node.subscribe('/rosout_agg', Rosgraph_msgs::Log) do |msg|
      @sockets.each do |ws|
        case msg.level
        when 2
          level = 'alert-info'
        when 4
          level = ''
        when 8
          level = 'alert-error'
        else
          level = 'alert-error'
        end
        ws.send("<div class=\"alert #{level}\"><button class=\"close\" data-dismiss=\"alert\">x</button>#{msg.msg}</div>")
      end
    end

    sleep(1.0)
    p 'hoge'
    t = Thread.new do
      p 'start'
      while @node.ok?
        @node.spin_once
        sleep(0.1)
      end
      p 'end'
    end

    EventMachine::WebSocket.start(:host => "localhost", :port => 8080) do |ws|
      ws.onopen do
        @sockets << ws
      end
      ws.onmessage { |msg| ws.send "Pong: #{msg}" }
      ws.onclose   { puts "WebSocket closed" }
    end

  end

  def print_nav
    output = ''
    @menu.each do |title|
      if title == @active
        output += "<li class=\"active\"><a href=\"#{title}\">#{title.capitalize}</a></li>\n"
      else
        output += "<li><a href=\"#{title}\">#{title.capitalize}</a></li>\n"
      end
    end
    output
  end

  get '/' do
    'Hello world!'
  end

  def get_nodes
    nodes = Set.new
    @master.get_system_state.each do |states|
      states.each do |topic, publishers|
        publishers.each do |pub|
          if pub != @node.node_name
            nodes.add(pub)
          end
        end
      end
    end
    nodes.to_a
  end

  def get_topics
    topics = Set.new
    @master.get_system_state[0,2].each do |states|
      states.each do |topic, publishers|
        topics.add(topic)
      end
    end
    topics.to_a
  end

  def get_services
    @master.get_system_state[2].map do |service, publishers|
      service
    end
  end

  get '/node' do
    @active = 'node'
    @nodes = get_nodes
    erb :node
  end


  get '/topic' do
    @topics = get_topics
    @active = 'topic'
    erb :topic
  end

  get '/service' do
    @services = get_services
    @active = 'service'
    erb :service
  end
end
Thin::Server.start MyApp, '0.0.0.0', 9090
end
