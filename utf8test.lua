
local str = "慕容复在你的耳边悄声说道：大英雄手上如传花蝴蝶，并不停歇，印向盖世豪杰必救处之"

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

