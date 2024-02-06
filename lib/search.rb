require "yt"
require "dotenv/load"
require_relative "youtube_dl"

Yt.configure do |config|
  config.api_key = ENV["YOUTUBE_API_KEY"]
  config.log_level = "devel"
end

def get_video_title(title)
  # 通过正则替换标题中的于:/和空白字符
  title = title.gsub(/[:\/\s]/, "_")

  puts title

  title
end

def get_video_duration(video_id)
  shell_output = `#{get_youtube_dl_file} info #{video_id}`
  # 通过正则在多行文本中匹配时长字符串（类似：1h2m22s）
  # P.S. Duration也可能小于1小时，只需要返回时长的小时、分钟、秒部分字符串
  # 使用正则表达式匹配Duration的具体数据
  duration_match = shell_output.match(/Duration:\s*(\d+h)?(\d+m)?(\d+s)?/)

  # 提取匹配到的数据
  hours = duration_match[1].to_i if duration_match[1]
  minutes = duration_match[2].to_i if duration_match[2]
  seconds = duration_match[3].to_i if duration_match[3]

  # 把时长转换成秒
  # hours 可能为nil
  duration = (hours || 0) * 3600 + (minutes || 0) * 60 + (seconds || 0)

  puts duration

  duration
end

def get_video_path(video_id, title)
  # 下载视频到本地
  output = `#{get_youtube_dl_file} download -q 139 #{video_id} -d ./tmp -o #{title}.m4a`
  puts output

  # 获取下载的视频文件路径
  audio_path = File.expand_path("./tmp/#{title}.m4a")

  puts audio_path

  audio_path
end

def search(bot)
  channel = Yt::Channel.new id: ENV["YOUTUBE_CHANNEL_ID"]

  # 获取当初的时间戳
  now = Time.now.to_i

  # 数组顺序反转一下
  channel.videos.where(order: "date", eventType: "completed", part: "id,snippet").first(20).reverse.each do |video|
    # 如果视频时间戳在当前的一个小时之内
    # 下载该视频的音频文件到本地，然后发送到telegram
    if now - video.published_at.to_i < 3600
      video_title = video.title
      title = get_video_title(video_title)

      audio_duration = get_video_duration(video.id)

      audio_path = get_video_path(video.id, title)

      # 把 2024-02-05 17:21:41 UTC 时间转换成东京时区时间
      published_at_japan_timezone = video.published_at.getlocal("+09:00").strftime("%Y-%m-%d %H:%M:%S")

      # 多行字符，并且使用 video_title 变量
      caption = <<~HEREDOC
        #{video_title}

        视频发布时间（东京时区）：#{published_at_japan_timezone}
        YouTube链接：https://www.youtube.com/watch?v=#{video.id}
      HEREDOC

      bot.api.send_audio(chat_id: ENV["TELEGRAM_CHANNEL_ID"], duration: audio_duration, title: video_title, performer: "王剑", caption: caption, thumbnail: video.thumbnail_url(:medium), audio: Faraday::UploadIO.new(audio_path, "audio/mpeg"))
    end
  end
end
