
local str = "Ľ�ݸ�����Ķ�������˵������Ӣ�������紫������������ͣЪ��ӡ��������ܱؾȴ�֮"

for i = 1, string.len(str),3 do
  print(string.sub(str, i, i+2))
end

