require "telegram/bot"
require_relative "search.rb"
require "dotenv/load"

class Bot
  def initialize
    token = ENV["TELEGRAM_BOT_TOKEN"]

    Telegram::Bot::Client.run(token) do |bot|
      bot.api.send_message(chat_id: 1479895880, text: "测试 123", date: Time.new)

      search(bot)
    end
  end
end
