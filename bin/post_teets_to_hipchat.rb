#!/usr/bin/env ruby

# require 'twitter'
require 'hipchat'
require 'faraday'
require 'faraday_middleware'
require 'redis'


class TwitterSearch
  ROOT_URL = 'http://search.twitter.com/'

  def connection
    options = {
      :url => ROOT_URL,
    }
    @connection ||= Faraday.new(options) do |faraday|
      faraday.request :json
      faraday.adapter Faraday.default_adapter
      faraday.use FaradayMiddleware::ParseJson
    end
  end

  def request(params = {})
    path = "/search.json"
    response = connection.get do |req|
      req.headers['Content-Type'] = 'application/json'
      req.url path, params
    end
    response.body
  end
end

api_token = ENV['HIPCHAT_TOKEN']
client = HipChat::Client.new(api_token)
room_id = ENV['HIPCHAT_ROOM_ID']
hipchat_username = 'Twitter'

redis = Redis.new( url: ENV['REDISCLOUD_URL'] )
last_id = redis.get('last_id')

query = ENV['TWITTER_SEARCH_QUERY']
lang = ENV['TWITTER_SEARCH_LANG']
params = { rpp: 100, result_type: 'recent', lang: lang, q: query, since_id: last_id }
puts params
response = TwitterSearch.new.request(params)
puts response

response['results'].reverse.each do |result|
  tweet_url = "https://twitter.com/#{result['from_user']}/status/#{result['id']}"
  puts tweet_url
  client[room_id].send(hipchat_username, tweet_url, message_format: 'text', color: 'gray', notify: 1)
end

max_id = response['max_id']
puts max_id
puts redis.set('last_id', max_id.to_s)
