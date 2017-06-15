--
-- log.lua
-- Date: 2017/6/15
-- Change:
-- 2017/6/15 - created
-- ���뷽����
-- 1. ������Mushclient��Ŀ¼��luaĿ¼�
-- 2. ���ļ�-ȫ������-Lua�������� require "log"
--    ����ֱ����lua�ļ��п�ͷ��� require "log"
-- ʹ�÷�����
-- ����󣬻��ڱ����б�������3��������
-- 1. log_file ��־�ļ�λ�ã����޸ģ��޸ĺ����һ��log()�������ÿ�ʼ��Ч
-- 2. log_flush_interval ��־ˢ�¼�����룩��Ĭ��10�롣��ʾ����־����ͬ����Ӳ�̵����ʱ����
-- 3. log_flush_line_limit ��־ˢ��������Ĭ��10�С���ʾ����־����ͬ����Ӳ�̵�����������
-- ����2,3ֻҪ��һ�����㣬��־�ļ��ͻᱻͬ�������ⲿ�򿪸���־�ļ��ᷢ�����ݷ����仯��
-- ֮�������������Ƿ��ö�Ӳ��Ƶ����д������Ϸ�Լ�ϵͳ��ɲ���Ҫ�ĸ�����Ĭ��ֵӦ������������
-- �ڴ���������ʱ���У�����������Send-to-script��ʹ��log��������¼��־��

require "wait"
require "check"

logger = {}
-- ���Ա�־
logger.DEBUG = true
-- ��־�ļ���
logger.fileName = nil
-- ��־�к�
logger.lineNo = 0
-- ��־��ǰ����
logger.text = nil
-- ��־ˢ��ʱ����(��)
logger.flushInterval = tonumber(GetVariable("log_flush_interval")) or 10
SetVariable("log_flush_interval", logger.flushInterval)
-- ��־ˢ�´�������
logger.flushLineLimit = tonumber(GetVariable("log_flush_line_limit")) or 10
SetVariable("log_flush_line_limit", logger.flushLineLimit)
-- ����־����
logger.open = function(fileName)
  assert(fileName == nil or type(fileName) == "string", "�ļ�������Ϊstring")
  if logger.fileName then
    print("��־�ļ��Ѵ��ڣ����Թرգ�", logger.fileName)
    logger.close()
  end
  logger.fileName = fileName or ("logs\\" .. os.time() .. ".log")
  if logger.DEBUG then print("�ļ���", logger.fileName) end
  OpenLog(logger.fileName, true)
  SetVariable("log_file", logger.fileName)
end
-- �ر���־����
logger.close = function()
  if not logger.fileName then
    print("��־�ļ������ڣ��޷��رգ�", logger.fileName)
    return
  end

  CloseLog()
end
-- ��־Э��
logger.logThread = coroutine.create(function(line)
  logger.text = line
  while true do
    local fileName = GetVariable("log_file")
    if not fileName then
      fileName = "logs\\" .. os.time() .. ".log"
      SetVariable("log_file", fileName)
    end
    if not logger.fileName then
      if logger.DEBUG then print("���ļ�", fileName) end
      logger.open(fileName)
    elseif logger.fileName ~= fileName then
      -- try close the old log file and open the new file
      logger.close()
      if logger.DEBUG then print("�رվ��ļ��������ļ�", fileName) end
      logger.open(fileName)
    end
    if logger.DEBUG then print("��¼��־", logger.text) end
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
-- ��ʱˢ��Э��
logger.flushTimer = wait.make(function()
  local lastLineNo = 0
  while true do
    wait.time(logger.flushInterval)
    if logger.fileName and logger.lineNo > lastLineNo then
      if logger.DEBUG then print("ˢ����־") end
      FlushLog()
    end
    lastLineNo = logger.lineNo
  end
end)
-- ��¼��־����
logger.log = function(str)
  return coroutine.resume(logger.logThread, str)
end
log = logger.log
return logger
