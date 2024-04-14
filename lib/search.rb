require "yt"
require "dotenv/load"

Yt.configure do |config|
  config.api_key = ENV["YOUTUBE_API_KEY"]
  config.log_level = "devel"
end

def transform_video_title(title)
  # 通过正则替换标题中的于:/和空白字符
  title = title.gsub(/[:\/\s]/, "_")

  title
end

def get_video_duration(video_id, output)
  shell_output = output.empty? ? `youtubedr info #{video_id}` : output
  # 通过正则在多行文本中匹配时长字符串（类似：1h2m22s）
  # P.S. Duration也可能小于1小时，只需要返回时长的小时、分钟、秒部分字符串
  # 使用正则表达式匹配Duration的具体数据
  duration_match = shell_output.match(/Duration:\s*(\d+h)?(\d+m)?(\d+s)?/)

  if (duration_match.nil?)
    puts "duration_match is nil"
    puts "duration_match: #{duration_match}"
    puts "shell_output: #{shell_output}"
    return 0
  end

  # 提取匹配到的数据
  hours = duration_match[1].to_i if duration_match[1]
  minutes = duration_match[2].to_i if duration_match[2]
  seconds = duration_match[3].to_i if duration_match[3]

  # 把时长转换成秒
  # hours 可能为nil
  duration = (hours || 0) * 3600 + (minutes || 0) * 60 + (seconds || 0)

  duration
end

def get_video_title(video_url)
  puts "video_url #{video_url}"
  shell_output = `youtubedr info #{video_url}`
  puts "shell_output: #{shell_output}"
  video_title = shell_output.match(/Title:\s*(\S.*)/)
  puts "video_title: #{video_title}"

  if (video_title.nil?)
    puts "video_title is nil. shell_output: #{shell_output}"
    return "video"
  end

  # trim
  video_title = video_title[1].strip
  return [video_title, shell_output]
end

def get_video_path(video_id, title)
  # 下载视频到本地
  output = `youtubedr download -d ./tmp -o #{title}.m4a -q 139 #{video_id}`

  # 获取下载的视频文件路径
  audio_path = File.expand_path("./tmp/#{title}.m4a")

  audio_path
end

def search(bot)
  channel = Yt::Channel.new id: ENV["YOUTUBE_CHANNEL_ID"]

  # 获取当初的时间戳
  now = Time.now.to_i

  # 数组顺序反转一下
  channel.videos.where(order: "date", eventType: "completed", part: "id,snippet").first(20).reverse.each do |video|
    puts video.title

    # 如果视频时间戳在当前的一个小时之内
    # 下载该视频的音频文件到本地，然后发送到telegram
    if now - video.published_at.to_i < 3600
      video_title = video.title

      # if !video_title.include?("")
      #   next
      # end

      title = transform_video_title(video_title)

      audio_duration = get_video_duration(video.id, "")

      audio_path = get_video_path(video.id, title)

      # 把 2024-02-05 17:21:41 UTC 时间转换成东京时区时间
      published_at_japan_timezone = video.published_at.getlocal("+09:00").strftime("%Y-%m-%d %H:%M:%S")

      # 多行字符，并且使用 video_title 变量
      caption = <<~HEREDOC
        #{video_title}

        视频发布时间（东京时区）：#{published_at_japan_timezone}
        YouTube链接：https://www.youtube.com/watch?v=#{video.id}
      HEREDOC

      # bot.api.send_audio(chat_id: ENV["TELEGRAM_CHANNEL_ID"], duration: audio_duration, title: video_title, performer: "王剑", caption: caption, thumbnail: video.thumbnail_url(:medium), audio: Faraday::UploadIO.new(audio_path, "audio/mpeg"))
    end
  end
end

def search_by_url(bot, video_url, chat_id)
  res = get_video_title(video_url)
  title = res[0]
  output = res[1]
  video_title = transform_video_title(title)
  audio_duration = get_video_duration(video_url, output)

  audio_path = get_video_path(video_url, video_title)

  # 告诉发消息的用户，检测文件是否存在
  if !File.exist?(audio_path)
    bot.api.send_message(chat_id: chat_id, text: "下载失败，本地文件不存在 #{video_url}")
    return
  end

  # 多行字符，并且使用 video_title 变量
  caption = <<~HEREDOC
    #{video_title}

    YouTube链接：#{video_url}
  HEREDOC

  bot.api.send_audio(chat_id: ENV["TELEGRAM_CHANNEL_ID"], duration: audio_duration, title: video_title, performer: "王剑", caption: caption, audio: Faraday::UploadIO.new(audio_path, "audio/mpeg"))
end
