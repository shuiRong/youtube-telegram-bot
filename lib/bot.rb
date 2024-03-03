require "telegram/bot"
require "dotenv/load"
require_relative "search.rb"

$bot = nil

class Bot
  def initialize
    token = ENV["TELEGRAM_BOT_TOKEN"]

    Telegram::Bot::Client.run(token) do |bot|
      $bot = bot

      bot.listen do |message|
        case message
        when Telegram::Bot::Types::Message
          case message.text
          when '/start'
            bot.api.send_message(chat_id: message.chat.id, text: "发送王剑的 YouTube 视频链接给 bot 将会触发程序下载该视频的音频文件到本地，然后上传到王剑频道里。")
          end

          if message.text.include?("youtube.com")
            search_by_url(bot, message, message.chat.id)
          end
        when Telegram::Bot::Types::PollAnswer
          # process_poll_answer(message)
        else
          bot.logger.info("Not sure what to do with this type of message")
        end
      end
    end
  end
end
