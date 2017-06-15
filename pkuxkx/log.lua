--
-- log.lua
-- Date: 2017/6/15
-- Change:
-- 2017/6/15 - created
-- 导入方法：
-- 1. 放置在Mushclient根目录的lua目录里，
-- 2. 在文件-全局属性-Lua里添加语句 require "log"
--    或者直接在lua文件中开头添加 require "log"
-- 使用方法：
-- 导入后，会在变量列表里生成3个变量：
-- 1. log_file 日志文件位置，可修改，修改后从下一个log()方法调用开始生效
-- 2. log_flush_interval 日志刷新间隔（秒），默认10秒。表示将日志内容同步到硬盘的最短时间间隔
-- 3. log_flush_line_limit 日志刷新行数，默认10行。表示将日志内容同步到硬盘的最少行数。
-- 其中2,3只要有一个满足，日志文件就会被同步（从外部打开该日志文件会发现内容发生变化）
-- 之所以做该设置是放置对硬盘频繁读写，对游戏以及系统造成不必要的负担。默认值应当已满足需求。
-- 在触发器，定时器中，可以在设置Send-to-script后，使用log方法来记录日志。

require "wait"
require "check"

logger = {}
-- 调试标志
logger.DEBUG = true
-- 日志文件名
logger.fileName = nil
-- 日志行号
logger.lineNo = 0
-- 日志当前内容
logger.text = nil
-- 日志刷新时间间隔(秒)
logger.flushInterval = tonumber(GetVariable("log_flush_interval")) or 10
SetVariable("log_flush_interval", logger.flushInterval)
-- 日志刷新磁盘行数
logger.flushLineLimit = tonumber(GetVariable("log_flush_line_limit")) or 10
SetVariable("log_flush_line_limit", logger.flushLineLimit)
-- 打开日志函数
logger.open = function(fileName)
  assert(fileName == nil or type(fileName) == "string", "文件名必须为string")
  if logger.fileName then
    print("日志文件已存在，尝试关闭：", logger.fileName)
    logger.close()
  end
  logger.fileName = fileName or ("logs\\" .. os.time() .. ".log")
  if logger.DEBUG then print("文件名", logger.fileName) end
  OpenLog(logger.fileName, true)
  SetVariable("log_file", logger.fileName)
end
-- 关闭日志函数
logger.close = function()
  if not logger.fileName then
    print("日志文件不存在，无法关闭：", logger.fileName)
    return
  end

  CloseLog()
end
-- 日志协程
logger.logThread = coroutine.create(function(line)
  logger.text = line
  while true do
    local fileName = GetVariable("log_file")
    if not fileName then
      fileName = "logs\\" .. os.time() .. ".log"
      SetVariable("log_file", fileName)
    end
    if not logger.fileName then
      if logger.DEBUG then print("打开文件", fileName) end
      logger.open(fileName)
    elseif logger.fileName ~= fileName then
      -- try close the old log file and open the new file
      logger.close()
      if logger.DEBUG then print("关闭旧文件并打开新文件", fileName) end
      logger.open(fileName)
    end
    if logger.DEBUG then print("记录日志", logger.text) end
    if logger.text then
      WriteLog(logger.text)
    end
    logger.lineNo = logger.lineNo + 1
    if logger.lineNo % logger.flushLineLimit == 0 then
      FlushLog()
    end
    logger.text = coroutine.yield()
  end
end)
-- 定时刷新协程
logger.flushTimer = wait.make(function()
  local lastLineNo = 0
  while true do
    wait.time(logger.flushInterval)
    if logger.fileName and logger.lineNo > lastLineNo then
      if logger.DEBUG then print("刷新日志") end
      FlushLog()
    end
    lastLineNo = logger.lineNo
  end
end)
-- 记录日志函数
logger.log = function(str)
  return coroutine.resume(logger.logThread, str)
end
log = logger.log
return logger
