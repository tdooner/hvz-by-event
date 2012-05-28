$: << "."
require 'sinatra'
require 'mongo_mapper'
require 'rack/cache'
Dir["mongomodels/*.rb"].map{|f| require f }

use Rack::Cache

configure do
    MongoMapper.connection = Mongo::Connection.new('localhost', 27017)
    MongoMapper.database = "conversion"
    disable :protection
    enable :cross_origin
end

get '/games/:id' do
    response['Access-Control-Allow-Origin'] = "*"
    cache_control :public, :max_age => 60
    @game = MongoModels::Game.where(name: params[:id]).first
    @game.to_json
end

get '/games/:id/players' do
    response['Access-Control-Allow-Origin'] = "*"
    cache_control :public, :max_age => 60
    @game = MongoModels::Game.where(name: params[:id]).first
    @players = MongoModels::Player.where(game: @game.id).all
    @players.to_json
end
