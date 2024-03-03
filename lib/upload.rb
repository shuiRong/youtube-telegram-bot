require "telegram/bot"
require "dotenv/load"
require_relative "search.rb"

class Upload
  def initialize
    token = ENV["TELEGRAM_BOT_TOKEN"]

    Telegram::Bot::Client.run(token) do |bot|
      search(bot)
    end
  end
end
