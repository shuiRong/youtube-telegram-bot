require "telegram/bot"
require_relative "search.rb"
require "dotenv/load"

class Bot
  def initialize
    token = ENV["TELEGRAM_BOT_TOKEN"]

    Telegram::Bot::Client.run(token) do |bot|
      search(bot)

      # bot.listen do |message|
      #   case message
      #   when Telegram::Bot::Types::Message
      #     puts message.chat.id
      #   when Telegram::Bot::Types::PollAnswer
      #     # process_poll_answer(message)
      #   else
      #     bot.logger.info("Not sure what to do with this type of message")
      #   end
      # end
    end
  end
end
