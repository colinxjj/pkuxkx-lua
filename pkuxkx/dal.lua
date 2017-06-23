--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:33
-- To change this template use File | Settings | File Templates.
--

--------------------------------------------------------------
-- dal.lua
-- data access layer based on db module
-- it also depends on the value classes
-- includes query rooms, paths, etc.
-- changelog:
-- 2017/05/24 - add query to search rooms without tagged as blockzone
--              especially for hubiao job
--------------------------------------------------------------

local Zone = require "pkuxkx.Zone"
local ZonePath = require "pkuxkx.ZonePath"
local Room = require "pkuxkx.Room"
local RoomPath = require "pkuxkx.RoomPath"
local gb2312 = require "pkuxkx.gb2312"

local define_dal = function()
  local prototype = {}
  prototype.__index = prototype
  local sql_to_prepare = {
    GET_ALL_ROOMS = "select * from rooms",
    GET_ALL_PATHS = "select * from paths",
    GET_ROOM_BY_ID = "select * from rooms where id = ?",
    GET_ROOMS_BY_NAME = "select * from rooms where name = ?",
    GET_ROOMS_LIKE_CODE = "select * from rooms where code like ?",
    GET_ROOMS_BY_ZONE = "select * from rooms where zone = ?",
    GET_PATHS_BY_STARTID = "select * from paths where startid = ?",
    -- current version ignores code, zone, mapinfo columns
    UPD_ROOM = [[update rooms
    set name = :name, description = :description, exits = :exits
    where id = :id]],
    GET_ALL_ZONES = "select * from zones",
    GET_ALL_ZONE_PATHS = [[select sz.id as startid, ez.id as endid, zc.weight as weight
    from zone_connectivity zc, zones sz, zones ez
    where zc.startcode = sz.code
    and zc.endcode = ez.code]],
    GET_ALL_AVAILABLE_ROOMS = "select * from rooms where name <> '' and zone <> ''",
    GET_ALL_AVAILABLE_PATHS = "select * from paths where enabled = 1"
  }

  local nameGetPinyinByCharCode = function(n)
    return  "SQL_GET_PINYIN_BY_CHR_" .. n
  end
  local SQL_GET_PINYIN_BY_CHR = "select * from chr2pinyin where chrcode in (__REPLACEMENT__)"
  local char2pinyinSqlGenerator = function(n)
    local queries = {}
    for i = 1, n do
      local name = nameGetPinyinByCharCode(i)
      local holders = string.rep("?,", i)
      local sql = string.gsub(SQL_GET_PINYIN_BY_CHR, "__REPLACEMENT__", string.sub(holders, 1, string.len(holders) - 1))
      queries[name] = sql
    end
    return queries
  end

  local NoChangeConstructor = function(self, obj) return obj end

  function prototype.open(db)
    local obj = {}
    obj.db = db
    obj.stmts = {}
    setmetatable(obj, prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self.db:prepare(sql_to_prepare)
    -- support at most 10-char word pinyin mapping query
    local pinyinStmts = char2pinyinSqlGenerator(10)
    self.db:prepare(pinyinStmts)
  end

  function prototype:dispose()
    if self.db then
      for name, stmt in self.stmts do
        stmt:finalize()
        self.stmts[name] = nil
      end
      self.db = nil
    end
  end

  -- return dict of rooms
  function prototype:getAllRooms()
    return self.db:fetchRowsAs {
      stmt = "GET_ALL_ROOMS",
      constructor = Room.decorate,
      key = function(room) return room.id end
    }
  end

  function prototype:getRoomsByZone(zone)
    return self.db:fetchRowsAs {
      stmt = "GET_ROOMS_BY_ZONE",
      constructor = Room.decorate,
      key = function(room) return room.id end
    }
  end

  function prototype:getAllAvailableRooms()
    return self.db:fetchRowsAs {
      stmt = "GET_ALL_AVAILABLE_ROOMS",
      constructor = Room.decorate,
      key = function(room) return room.id end
    }
  end

  function prototype:getAllAvailableRoomsExcludedBlockZones(excludedZones)
    assert(#excludedZones > 0, "excluded zones must be more than 1")
    local ss = {
      "select * from rooms where name <> '' ",
      "and zone in (select code from zones) ",
      "and coalesce(blockzone, '') not in ("}
    for i, _ in ipairs(excludedZones) do
      if i == 1 then
        table.insert(ss, "?")
      else
        table.insert(ss, ",?")
      end
    end
    table.insert(ss, ")")
    local sql = table.concat(ss, "")
    return self.db:fetchRowsAs {
      stmt = sql,
      constructor = Room.decorate,
      key = function(room) return room.id end,
      params = excludedZones,
      type = "unprepared",
    }
  end

  -- return array of paths
  function prototype:getAllPaths()
    return self.db:fetchRowsAs {
      stmt = "GET_ALL_PATHS",
      constructor = RoomPath.decorate
    }
  end

  function prototype:getPseudoPath(roomId)
    return RoomPath:decorate {
      startid = roomId,
      endid = roomId,
      path = "look",
      endcode = "",
      weight = 0
    }
  end

  function prototype:getAllAvailablePaths()
    return self.db:fetchRowsAs {
      stmt = "GET_ALL_AVAILABLE_PATHS",
      constructor = RoomPath.decorate
    }
  end

  -- return single room if found
  function prototype:getRoomById(id)
    return self.db:fetchRowAs {
      stmt = "GET_ROOM_BY_ID",
      constructor = Room.decorate,
      params = id
    }
  end

  -- return array of rooms if name matched
  function prototype:getRoomsByName(name)
    return self.db:fetchRowsAs {
      stmt = "GET_ROOMS_BY_NAME",
      constructor = Room.decorate,
      params = name
    }
  end

  function prototype:getRoomsLikeCode(code)
    return self.db:fetchRowsAs {
      stmt = "GET_ROOMS_LIKE_CODE",
      constructor = Room.decorate,
      params =  "%" .. code .. "%"
    }
  end

  -- return dict of paths(key = endid) by start id
  function prototype:getPathsByStartId(startid)
    return self.db:fetchRowsAs {
      stmt = "GET_PATHS_BY_STARTID",
      constructor = RoomPath.decorate,
      params = startid,
      key = function(path) return path.endid end
    }
  end

  -- generate pinyinList
  local pinyinPerm
  pinyinPerm = function(seq, dict, n)

    if n == 0 then
      coroutine.yield(dict) -- the order in elements are switched back and forth
    else
      local chr = seq[n]
      local pys = dict[chr]
      if not pys then
        error("cannot find pinyin of char:" .. chr, 2)
      end
      for i = 1, #pys do
        pys[1], pys[i] = pys[i], pys[1]
        pinyinPerm(seq, dict, n - 1)
        pys[1], pys[i] = pys[i], pys[1]
      end
    end
  end

  local pinyinIter = function(seq, dict)
    local n = #seq
    local co = coroutine.create(function() pinyinPerm(seq, dict, n) end)
    return function()
      local retCode, result = coroutine.resume(co)
      if not retCode then -- error
        --error(result)
        return nil
      end
      return result
    end
  end

  -- input must be a gb2312 encoded string (chinese words)
  function prototype:getPinyinListByWord(word)
    local nChars = gb2312.len(word)
    local seq = {}
    for i = 1, nChars do
      local code = gb2312.code(word, i)
      table.insert(seq, code)
    end
    local dict = self.db:fetchRowsAs {
      stmt = nameGetPinyinByCharCode(nChars),
      constructor = function(self, row)
        return {
          chrcode = row.chrcode,
          unpack(utils.split(row.pinyin, ","))
        }
      end,
      key = function(row) return row.chrcode end,
      params = seq
    }
    local results = {}
    for pyDict in pinyinIter(seq, dict) do
      -- generate result
      local result = {}
      for i = 1, #seq do
        -- always get the first element in pinyin list,
        -- because permuation already switch them inside.
        table.insert(result, pyDict[seq[i]][1])
      end
      table.insert(results, table.concat(result))
    end
    return results
  end

  function prototype:updateRoom(room)
    return self.db:executeUpdate {
      stmt = "UPD_ROOM",
      params = room
    }
  end

  -- return zone table
  function prototype:getAllZones()
    return self.db:fetchRowsAs {
      stmt = "GET_ALL_ZONES",
      constructor = Zone.decorate,
      key = function(zone) return zone.id end
    }
  end

  function prototype:getAllZonesExcludedZones(excludedZones)
    assert(#excludedZones > 0, "excluded zones must be more than 1")
    local ss = {
      "select * from zones where code not in ("}
    for i, _ in ipairs(excludedZones) do
      if i == 1 then
        table.insert(ss, "?")
      else
        table.insert(ss, ",?")
      end
    end
    table.insert(ss, ")")
    local sql = table.concat(ss, "")
    return self.db:fetchRowsAs {
      stmt = sql,
      constructor = Zone.decorate,
      key = function(zone) return zone.id end,
      params = excludedZones,
      type = "unprepared",
    }
  end

  -- return array of zone path
  function prototype:getAllZonePaths()
    return self.db:fetchRowsAs {
      stmt = "GET_ALL_ZONE_PATHS",
      constructor = ZonePath.decorate
    }
  end

  return prototype
end
return define_dal()  --.open(db)
