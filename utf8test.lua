
local str = "Ľ�ݸ�����Ķ�������˵������Ӣ�������紫������������ͣЪ��ӡ��������ܱؾȴ�֮"

for i = 1, string.len(str),3 do
  print(string.sub(str, i, i+2))
end


local paths = {
  "n", "s", "w", "e"
}

require "wait"
wait.make(function()
  for _, path in ipairs(paths) do
    Send(path)
    wait.time(3)
  end
end)

