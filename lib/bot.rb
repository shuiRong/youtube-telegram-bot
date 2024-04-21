require "telegram/bot"
require "dotenv/load"
require_relative "search.rb"
require 'timers'
require 'async'

class Bot
  def initialize
    token = ENV["TELEGRAM_BOT_TOKEN"]

    Telegram::Bot::Client.run(token) do |bot|

      # 创建一个异步任务来处理定时事件和机器人监听
      Async do
        # 创建周期性任务
        timer_task = Async do |task|
          loop do
            task.sleep 60 * 60 # 暂停1小时
            puts "定时程序运行 #{Time.now}"
            search(bot)
          end
        end

        # 创建机器人监听任务
        bot_task = Async do |task|
          bot.listen do |message|
            case message
            when Telegram::Bot::Types::Message
              case message.text
              when '/start'
                bot.api.send_message(chat_id: message.chat.id, text: "发送王剑的 YouTube 视频链接给 bot 将会触发程序下载该视频的音频文件到本地，然后上传到王剑频道里。")
              end

              if message.text.include?("youtube.com")
                bot.api.send_message(chat_id: message.chat.id, text: "已收到链接，正在处理中，2分钟内没有上传则说明失败。（不见本消息，说明Bot程序没有在运行）")
                search_by_url(bot, message, message.chat.id)
              end
            when Telegram::Bot::Types::PollAnswer
              # process_poll_answer(message)
            else
              bot.logger.info("Not sure what to do with this type of message")
            end
          end
        end

        # 等待所有任务完成
        [timer_task, bot_task].each(&:wait)
      end

    end
  end
end
