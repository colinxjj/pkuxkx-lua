--
-- NanjueJob.lua
-- User: zhe.jiang
-- Date: 2017/4/5
-- Desc:
-- Change:
-- 2017/4/5 - created

local define_NanjueJob = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    local obj = {}
    obj.code = assert(args.code, "code of job cannot be nil")
    obj.name = assert(args.name, "name of job cannot be nil")
    obj.level = assert(args.level, "level of job cannot be nil")
    obj.status = assert(args.status, "status of job cannot be nil")
    obj.startTime = assert(args.startTime, "startTime of job cannot be nil")
    obj.endTime = assert(args.endTime, "endTime of job cannot be nil")
    obj.location = assert(args.location, "location of job cannot be nil")
    obj.requirements = assert(args.requirements, "requirements of job cannot be nil")
    obj.players = assert(args.players, "players of job cannot be nil")
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.code, "code of job cannot be nil")
    assert(obj.name, "name of job cannot be nil")
    assert(obj.level, "level of job cannot be nil")
    assert(obj.status, "status of job cannot be nil")
    assert(obj.startTime, "startTime of job cannot be nil")
    assert(obj.endTime, "endTime of job cannot be nil")
    assert(obj.location, "location of job cannot be nil")
    assert(obj.requirements, "requirements of job cannot be nil")
    assert(obj.players, "players of job cannot be nil")
    setmetatable(obj, self or prototype)
    return obj
  end

  return prototype
end
return define_NanjueJob()

