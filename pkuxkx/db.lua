--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:25
-- To change this template use File | Settings | File Templates.
--

--------------------------------------------------------------
-- db.lua
-- handle db operations
--------------------------------------------------------------
local define_db = function()

  local prototype = {}
  prototype.__index = prototype

  -- Deprecated, use file db
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

  -- Deprecated, use file db
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

  -- Deprecated, use file db
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

  function prototype.open(filename)
    assert(filename, "filename cannot be empty")
    local obj = {}
    obj.db = sqlite3.open(filename)
    setmetatable(obj, prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self.stmts = {}
  end

  function prototype:close()
    if not self.db then error("db already closed") end
    for name, stmt in pairs(self.stmts) do
      stmt:finalize()
      self.stmts[name] = nil
    end
    self.db.close()
    self.db = nil
  end

  function prototype:prepare(args)
    assert(args, "args in prepare cannot be nil")
    for name, sql in pairs(args) do
      if self.stmts[name] then error("SQL " .. name .. " is already prepared", 2) end
      self.stmts[name] = self.db:prepare(sql)
    end
  end

  function prototype:fetchRowAs(args)
    assert(args.stmt, "stmt cannot be nil")
    local stmt = assert(self.stmts[args.stmt], "stmt is not prepared")
    local constructor = assert(args.constructor, "constructor cannot be nil")
    local params = args.params
    -- always reset the statement
    stmt:reset()
    if params then
      if type(params) == "table" then
        assert(stmt:bind_values(unpack(params)) == sqlite3.OK, "failed to bind values")
      else
        assert(stmt:bind_values(params) == sqlite3.OK, "failed to bind values")
      end
    end
    --assert(stmt:step() == sqlite3.ROW, "Row not found")
    if stmt:step() ~= sqlite3.ROW then
      return nil
    end
    return constructor(nil, stmt:get_named_values())
  end

  function prototype:fetchRowsAs(args)
    assert(args.stmt, "stmt cannot be nil")
    local stmt = assert(self.stmts[args.stmt], "stmt is not prepared")
    local constructor = assert(args.constructor, "constructor cannot be nil")
    local key = args.key
    if key and type(key) ~= "function" then
      error("key must be a function to generate dict", 2)
    end
    local params = args.params
    -- always reset the statement
    stmt:reset()
    if params then
      if type(params) == "table" then
        assert(stmt:bind_values(unpack(params)) == sqlite3.OK, "failed to bind values")
      else
        assert(stmt:bind_values(params) == sqlite3.OK, "failed to bind values")
      end
    end
    local results = {}
    while true do
      local result = stmt:step()
      if result == sqlite3.DONE then
        break
      end
      assert(result == sqlite3.ROW, "Row not found")
      local row = stmt:get_named_values()
      local obj = constructor(nil, row)
      if key then
        results[key(obj)] = obj
      else
        table.insert(results, obj)
      end
    end
    return results
  end

  function prototype:executeUpdate(args)
    assert(args.stmt, "stmt cannot be nil")
    local stmt = assert(self.stmts[args.stmt], "stmt is not prepared")
    local params = assert(args.params, "params in update cannot be nil")
    assert(type(args.params) == "table", "params in update must be name table")
    --always reset the statement
    stmt:reset()
    assert(stmt:bind_names(params) == sqlite3.OK, "failed to bind params with nametable")
    assert(stmt:step() == sqlite3.DONE)
  end

  return prototype
end
-- easy to switch to memory db
-- local db = define_db().open_memory_copied("xxx.db")
return define_db()  -- .open("data/pkuxkx-gb2312.db")
