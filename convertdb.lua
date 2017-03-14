--
-- Created by IntelliJ IDEA.
-- User: zhe.jiang
-- Date: 2017/3/10
-- Time: 13:56
-- To change this template use File | Settings | File Templates.
--
require "world"
require "lsqlite3"
require "tprint"
--local iconv = require "luaiconv"
--local codec = iconv.new("utf-8", "gb2312")

local gb2312 = {}
gb2312.len = function(s)
  if not s or type(s) ~= "string" then error("string required", 2) end
  return string.len(s) / 2
end

gb2312.code = function(s, ci)
  local first = ci * 2 - 1
  return string.byte(s, first, first) * 256 + string.byte(s, first + 1, first + 1)
end

-- make sure the new db does not exists
local newdb = sqlite3.open("data/pkuxkx-gb2312.db")
local ddl = [[
create table if not exists rooms (
  id integer primary key AUTOINCREMENT,
  name text,
  code text,
  description text,
  exits text,
  zone text,
  mapinfo text
);
create table if not exists paths (
  startid integer,
  endid integer,
  path text,
  endcode text,
  weight integer default 1,
  enabled integer default 1
);
create index if not exists idx_paths on paths (startid, endid);

create table if not exists pinyin2chr (
  pinyin text primary key,
  chr text
);
create table if not exists chr2pinyin (
  chr text primary key,
  chrcode integer,
  pinyin text
);
create index if not exists idx_chr2pinyin on chr2pinyin (chrcode);
]]

newdb:exec(ddl)

local olddb = sqlite3.open("data/pkuxkx.db")

newdb:exec("begin")

local stmt = newdb:prepare("insert into rooms (id, name, code, description, exits, zone, mapinfo) values (?,?,?,?,?,?,?)")
for row in olddb:rows("select * from rooms") do
--  for i = 1,#row do
--    if type(row[i]) == "string" then
--      row[i] = codec:iconv(row[i])
--    end
--  end
  stmt:bind_values(unpack(row))
  stmt:step()
  stmt:reset()
end
stmt:finalize()

stmt = newdb:prepare("insert into paths (startid, endid, path, endcode, weight) values (?,?,?,?,?)")
for row in olddb:rows("select startid, endid, path, endcode, weight from paths") do
--  for i = 1,#row do
--    if type(row[i]) == "string" then
--      row[i] = codec:iconv(row[i])
--    end
--  end
  stmt:bind_values(unpack(row))
  stmt:step()
  stmt:reset()
end
stmt:finalize()

stmt = newdb:prepare("insert into chr2pinyin (chr, chrcode, pinyin) values (?,?,?)")
for line in io.lines("data/char2pinyin.csv") do
  local ss = utils.split(line, ":")
--  stmt:bind_values(ss[1], utils.utf8decode(ss[1])[1], ss[2])
  stmt:bind_values(ss[1], gb2312.code(ss[1], 1), ss[2])
  stmt:step()
  stmt:reset()
end
stmt:finalize()

stmt = newdb:prepare("insert into pinyin2chr (pinyin, chr) values (?,?)")
for line in io.lines("data/pinyin2char.csv") do
  local ss = utils.split(line, ":")
  stmt:bind_values(ss[1], ss[2])
  stmt:step()
  stmt:reset()
end
stmt:finalize()

newdb:exec("commit")

olddb:close()
newdb:close()