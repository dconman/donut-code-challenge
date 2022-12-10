require 'sinatra'
require 'sinatra/custom_logger'
require 'sinatra/reloader' if settings.development?
require 'dotenv/load' if settings.development?
require 'logger'
require 'slack'
require './lib/tasks.rb'

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
      also_reload './lib/tasks.rb'
      set :logger, Donut::App.logger

      after_reload do
        Donut::App.logger.info 'reloaded'
      end
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
      Tasks.new(client, logger: Donut::App.logger, &method(:erb)).handle_request(payload)
      200
    rescue => e
      Donut::App.logger.error(e.full_message(highlight: false, order: :top))
      500
    end

    # Use this to verify that your server is running and handling requests.
    get '/' do
      'Hello, world!'
    end
  end
end
