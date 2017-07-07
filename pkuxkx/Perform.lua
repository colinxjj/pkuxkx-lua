--
-- Perform.lua
-- User: zhe.jiang
-- Date: 2017/7/7
-- Desc:
-- Change:
-- 2017/7/7 - created

local define_Perform = function()
  local prototype = {}
  prototype.__index = prototype

  -- 创建技能
  function prototype:new(args)
    local obj = {}
    obj.name = assert(args.name, "name cannot be nil")
    obj.energy = assert(args.energy, "energy cannot be nil")
    -- 目标
    local target = args.target
    if type(target) == "string" then
      obj.target = function() return target end
    elseif type(target) == "function" then
      obj.target = target
    end
    -- 前置动作
    local preAction = args.preAction
    if type(preAction) == "string" then
      obj.preAction = function() SendNoEcho(preAction) end
    elseif type(preAction) == "function" then
      obj.preAction = preAction
    end
    -- 后置动作
    local postAction = args.postAction
    if type(postAction) == "string" then
      obj.postAction = function() SendNoEcho(postAction) end
    elseif type(postAction) == "function" then
      obj.postAction = postAction
    end
    setmetatable(obj, self or prototype)
    return obj
  end

  -- 施放技能
  function prototype:perform(combat)
    if self.preAction then
      self.preAction(combat)
    end
    if self.target then
      SendNoEcho("perform " .. self.name .. " " .. self.target())
    else
      SendNoEcho("perform " .. self.name)
    end
    if self.postAction then
      self.postAction(combat)
    end
  end

  -- 预定义perform
  prototype.jianzhang = prototype:new {
    name = "huashan-jianfa.jianzhang",
    energy = 12,
    preAction = "wield my sword 2"
  }
  prototype.sanqingfeng = prototype:new {
    name = "yunushijiu-jian.sanqingfeng",
    energy = 12,
    preAction = "wield my sword 2"
  }
  prototype.wuji = prototype:new {
    name = "hunyuan-zhang.wuji",
    energy = 12,
    preAction = function(combat)
      SendNoEcho("remove shield")
      SendNoEcho("jiali max")
    end,
    postAction = function(combat)
      SendNoEcho("jiali 0")
      SendNoEcho("wear shield")
    end
  }
  prototype.kuangfeng = prototype:new {
    name = "kuangfeng-kuaijian.kuangfeng",
    energy = 12,
    preAction = "wield my sword 2"
  }
  prototype.poqi = prototype:new {
    name = "dugu-jiujian.poqi",
    energy = 4,
    preAction = "wield my sword 2"
  }
  prototype.po = prototype:new {
    name = "dugu-jiujian.po",
    energy = 4,
    preAction = "wield my sword 2"
  }

  return prototype
end
return define_Perform()



