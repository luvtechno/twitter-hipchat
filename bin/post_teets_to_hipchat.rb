#!/usr/bin/env ruby

# require 'twitter'
require 'hipchat'
require 'faraday'
require 'faraday_middleware'

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

last_id = nil
query = "Wantedly"
params = { rpp: 3, result_type: 'recent', lang: 'ja', q: query, since_id: last_id }
response = TwitterSearch.new.request(params)
puts response

response['results'].each do |result|
  tweet_url = "https://twitter.com/#{result['from_user']}/status/#{result['id']}"
  puts tweet_url
  client[room_id].send(hipchat_username, tweet_url, message_format: 'text', color: 'gray')
end

max_id = response['max_id']
puts max_id
