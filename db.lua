--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/2/25
-- Time: 17:32
-- Desc: To convert data encoded in gb2312 to utf-8 and refactor the structure
--       For development, need to download windows 32bit dll and put in working directory:
--       http://50.116.63.25/public/LuaSQLite3-Binaries/windows/x86/
--

require "lsqlite3"
--require "tprint"
--local iconv = require "luaiconv"
--local codec = iconv.new("utf-8", "gb2312")
--
---- copy data from existing database
--function getSourceData(dbname, sql)
--  local db = sqlite3.open(dbname, 6)
--  local results = {}
--  local stmt = db:prepare(sql)
--  while true do
--    local result = stmt:step()
--    if result == sqlite3.DONE then
--      break
--    end
--    assert(result == sqlite3.ROW, "Row not found")
--    local row = stmt:get_named_values()
--    for k, v in pairs(row) do
--      if type(v) == "string" then row[k] = codec:iconv(v) end
--    end
--    table.insert(results, row)
--  end
--  stmt:finalize()
--  db:close()
--
--  return results
--end
--
--function insertTargetData(dbname, sql, rows, prepareRow, ddl)
--  local db = sqlite3.open(dbname, 6)
--  if ddl then db:exec(ddl) end
--  local stmt = db:prepare(sql)
--  for idx, row in ipairs(rows) do
--    prepareRow(stmt, row)
--    local result = stmt:step()
--    if result ~= sqlite3.DONE then error(db:errmsg()) end
--    stmt:reset()
--  end
--  stmt:finalize()
--  db:close()
--end
--
--local sourceDB = "pkuxkx_p2palias_v2016.db"
--local targetDB = "pkuxkx.db"
--
--function migrateNodes()
--  local sourceSql = "select * from MUD_Node"
--  local targetSql = "insert into rooms (id, code, name, description, exits, zone) values (?,?,?,?,?,?)"
--  local prepareRow = function(stmt, row)
--    stmt:bind(1, row.nodeno)
--    stmt:bind(2, row.nodeid)
--    stmt:bind(3, row.nodename)
--    stmt:bind(4, row.description)
--    stmt:bind(5, row.exits)
--    stmt:bind(6, row.zone)
--  end
--  local ddl = [[
--    drop table if exists rooms;
--    create table rooms (
--      id integer primary key autoincrement,
--      code text,
--      name text,
--      description text,
--      exits text,
--      zone text
--    );
--  ]]
--  local nodes = getSourceData(sourceDB, sourceSql)
--  insertTargetData(targetDB, targetSql, nodes, prepareRow, ddl)
--end
--
--function migrateLinks()
--  local sourceSql = "select * from MUD_Links"
--  local targetSql = "insert into paths (startid, endid, path, endcode) values (?,?,?,?)"
--  local prepareRow = function(stmt, row)
--    stmt:bind(1, row.nodeno)
--    stmt:bind(2, row.linknodeno)
--    stmt:bind(3, row.path)
--    stmt:bind(4, row.linknodeid)
--  end
--  local ddl = [[
--    drop table if exists paths;
--    create table paths (
--      startid integer,
--      endid integer,
--      path text,
--      endcode text,
--      weight integer default 1
--    );
--  ]]
--  local links = getSourceData(sourceDB, sourceSql)
--  insertTargetData(targetDB, targetSql, links, prepareRow, ddl)
--end
--
--function createConnections()
--  local db = sqlite3.open(targetDB)
--  db:exec [[
--     create table if not exists connections (startzone text, endzone text, weight integer default 0);
--  ]]
--  db:close()
--end


memdb = {
  SQL_GET_ALL_ROOMS = "select * from rooms",
  SQL_GET_ALL_PATHS = "select * from paths",
  SQL_GET_ROOM_BY_ID = "select * from rooms where id = ?",
  SQL_GET_ROOMS_BY_NAME = "select * from rooms where name = ?",
  SQL_GET_PATHS_BY_STARTID = "select * from paths where startid = ?"
}

local getDataFromFile = function(filename, sql)
  local db = sqlite3.open(filename, 0)
  local results = {}
  local stmt = db:prepare(sql)
  while true do
    local result = stmt:step()
    if result == sqlite3.DONE then
      break
    end
    assert(result == sqlite3.ROW, "Row not found")
    local row = stmt:get_named_values()
    table.insert(results, row)
  end
  stmt:finalize()
  db:close()

  return results
end

local doLoad = function(db, sql, rows, bindRow)
  local stmt = db:prepare(sql)
  for idx, row in ipairs(rows) do
    bindRow(stmt, row)
    local result = stmt:step()
    if result ~= sqlite3.DONE then error(db:errmsg()) end
    stmt:reset()
  end
  stmt:finalize()
end

local loadDataInMem = function(filename, db)
  local rooms = getDataFromFile(filename, "select * from rooms")
  local roomsSql = "insert into rooms (id, code, name, description, exits, zone) values (?,?,?,?,?,?)"
  local bindRoom = function(stmt, row) stmt:bind_values(row.id, row.code, row.name, row.description, row.exits, row.zone) end
  doLoad(db, roomsSql, rooms, bindRoom)
  local paths = getDataFromFile(filename, "select * from paths")
  local pathsSql = "insert into paths (startid, endid, path, endcode, weight) values (?,?,?,?,?)"
  local bindPath = function(stmt, row) stmt:bind_values(row.startid, row.endid, row.path, row.endcode, row.weight) end
  doLoad(db, pathsSql, paths, bindPath)
end

function memdb:init(filename)
  self.db = sqlite3.open_memory()
  self.db:exec [[
    drop table if exists rooms;
    create table rooms (
      id integer primary key autoincrement,
      code text,
      name text,
      description text,
      exits text,
      zone text
    );
    drop table if exists paths;
    create table paths (
      startid integer,
      endid integer,
      path text,
      endcode text,
      weight integer default 1
    );
  ]]
  loadDataInMem(filename, self.db)
  self.db:exec [[
    create index if not exists idx_paths_startid_endid on paths (startid, endid);
  ]]
end

function memdb:close()
  if self.db then self.db.close() end
end

local fetchRowsFromStmt = function(stmt)
  local results = {}
  while true do
    local result = stmt:step()
    if result == sqlite3.DONE then
      break
    end
    assert(result == sqlite3.ROW, "Row not found")
    local row = stmt:get_named_values()
    table.insert(results, row)
  end
  return results
end

local fetchRows = function(db, sql, bind, ...)
  if not db then error("mem db already closed", 2) end
  local stmt = db:prepare(sql)
  if bind and arg then bind(stmt, ...) end
  local results = fetchRowsFromStmt(stmt)
  stmt:finalize()
  return results
end

function memdb:getAllRooms()
  if not self.db then error("mem db already closed") end
  return fetchRows(self.db, self.SQL_GET_ALL_ROOMS)
end

function memdb:getAllPaths()
  if not self.db then error("mem db already closed") end
  return fetchRows(self.db, self.SQL_GET_ALL_PATHS)
end

function memdb:getRoomById(id)
  if not self.db then error("mem db already closed") end
  local results = fetchRows(self.db, self.SQL_GET_ROOM_BY_ID, id)
  return results[1]
end

function memdb:getRoomsByName(name)
  if not self.db then error("mem db already closed") end
  return fetchRows(self.db, self.SQL_GET_ROOMS_BY_NAME, name)
end

return memdb