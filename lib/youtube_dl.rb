require "os"

# 根据当前服务器的操作系统，返回对应的youtube-dl可执行文件路径
# 目前只有
#   - macOS: bin/youtubedr
#   - Linux  bin/youtubedr_linux_amd64
def get_youtube_dl_file
  if OS.mac?
    "bin/youtubedr"
  else
    "bin/youtubedr_linux_amd64"
  end
end
