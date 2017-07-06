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
-- important update, we use utf8 character set to store
-- all strings in sqlite3 db
-- that means the characters directly received from
-- MUSHClient must be converted from GBK to UTF8 before
-- sending to DB
--
-- to encapsulate the effort of converting forth and back
-- we do this in all DB operations and make sure the interface
-- of this method only require GBK encoded string, all conversions
-- are made automatically in the public methods
--------------------------------------------------------------
local codec = require "pkuxkx.codec"

local define_db = function()

  local prototype = {}
  prototype.__index = prototype

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
      -- print("prepare stmt ", name, sql)
      self.stmts[name] = self.db:prepare(sql)
    end
  end

  local decodeRow = function(row)
    for k, v in pairs(row) do
      if type(v) == "string" then
        row[k] = codec:gbk(v)
      end
    end
    return row
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
        for i, v in ipairs(params) do
          if type(v) == "string" then
            params[i] = codec:utf8(v)
          end
        end
        assert(stmt:bind_values(unpack(params)) == sqlite3.OK, "failed to bind values")
      else
        if type(params) == "string" then
          params = codec:utf8(params)
        end
        assert(stmt:bind_values(params) == sqlite3.OK, "failed to bind values")
      end
    end
    --assert(stmt:step() == sqlite3.ROW, "Row not found")
    if stmt:step() ~= sqlite3.ROW then
      return nil
    end
    return constructor(nil, decodeRow(stmt:get_named_values()))
  end

  function prototype:fetchRowsAs(args)
    assert(args.stmt, "stmt cannot be nil")
    local sqlType = args.type
    local stmt
    if sqlType == "unprepared" then
      stmt = self.db:prepare(args.stmt)
    else
      stmt = assert(self.stmts[args.stmt], "stmt is not prepared:" .. args.stmt)
      -- always reset the statement
      stmt:reset()
    end
    local constructor = assert(args.constructor, "constructor cannot be nil")
    local key = args.key
    if key and type(key) ~= "function" then
      error("key must be a function to generate dict", 2)
    end
    local params = args.params

    if params then
      if type(params) == "table" then
        for i, v in ipairs(params) do
          if type(v) == "string" then
            params[i] = codec:utf8(v)
          end
        end
        assert(stmt:bind_values(unpack(params)) == sqlite3.OK, "failed to bind values")
      else
        if type(params) == "string" then
          params = codec:utf8(params)
        end
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
      local row = decodeRow(stmt:get_named_values())
      local obj = constructor(nil, row)
      if key then
        results[key(obj)] = obj
      else
        table.insert(results, obj)
      end
    end
    if type == "unprepared" then
      stmt:finalize()
    end
    return results
  end

  function prototype:executeUpdate(args)
    assert(args.stmt, "stmt cannot be nil")

    local stmt = assert(self.stmts[args.stmt], "stmt is not prepared")
    local params = assert(args.params, "params in update cannot be nil")
    local ignoreError = args.ignoreError
    assert(type(args.params) == "table", "params in update must be name table")
    --always reset the statement

    if params.description then
      ColourNote("green", "", params.description)
      ColourNote("green", "", string.len(params.description))
    end

    stmt:reset()
    for k, v in pairs(params) do
      if type(v) == "string" then
        params[k] = codec:utf8(v)
      end
    end

    if params.description then
      ColourNote("yellow", "", params.description)
      ColourNote("green", "", string.len(params.description))
    end

    assert(stmt:bind_names(params) == sqlite3.OK, "failed to bind params with nametable")
    local result = stmt:step()
    if not ignoreError then
      assert(result == sqlite3.DONE)
    end
  end

  return prototype
end
-- easy to switch to memory db
-- local db = define_db().open_memory_copied("xxx.db")
return define_db()  -- .open("data/pkuxkx-gb2312.db")
