require 'sinatra'
require 'sinatra/custom_logger'
require 'sinatra/reloader' if settings.development?
require 'dotenv/load' if settings.development?
require 'logger'
require 'slack'

Slack.configure do |config|
  config.token = ENV['SLACK_BOT_TOKEN']
end

module Donut
  class App < Sinatra::Base
    helpers Sinatra::CustomLogger

    ###
    #
    # Custom logging
    #
    ###
    def self.logger
      @logger ||= Logger.new(STDERR)
    end

    configure :development, :production do
      register Sinatra::Reloader
      set :logger, Donut::App.logger
    end

    ###
    #
    # Routes
    #
    ###
    post '/interactions' do
      payload = JSON.parse(params[:payload])
      Donut::App.logger.info "\n[+] Interaction type #{payload['type']} recieved."
      Donut::App.logger.info "\n[+] Payload:\n#{JSON.pretty_generate(payload)}"

      client = Slack::Web::Client.new
      user_id = payload['user']['id']
      channel_id = client.conversations_open(users: user_id).channel.id
      client.chat_postMessage(channel: channel_id, text: "Hello, <@#{user_id}>!")

      200
    end

    # Use this to verify that your server is running and handling requests.
    get '/' do
      'Hello, world!'
    end
  end
end
