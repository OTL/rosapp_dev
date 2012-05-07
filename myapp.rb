require 'sinatra'
require 'ros'

master = ROS::MasterProxy.new('/ros', ENV['ROS_MASTER_URI'], 'dummy')

get '/' do
  'Hello world!'
end

get '/nodes' do
  "Hello #{master.get_system_state}"
end

get '/topics' do
  @topics = master.get_system_state[0]
  erb :topics
end

get '/sub' do
  @topics = master.get_system_state[1]
  erb :topics
end

get '/service' do
  @topics = master.get_system_state[2]
  erb :topics
end
