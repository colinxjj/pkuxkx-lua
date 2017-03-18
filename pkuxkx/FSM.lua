--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/16
-- Time: 20:23
-- To change this template use File | Settings | File Templates.
--
-- finite state machine construct for most jobs
require "pkuxkx.predefines"

local define_FSM = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype.inheritedMeta()
    return inheritMeta(prototype)
  end

  -- every state machine implement should have constructor
  -- calling this method to get a draft to go on
  function prototype:new()
    local obj = {}
    obj.currState = nil
    obj.states = {}
    obj.transitions = {}
    obj.DEBUG = false
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:debug(...)
    if self.DEBUG then print(...) end
  end

  function prototype:debugOn()
    print("开启调试模式")
    self.DEBUG = true
  end

  function prototype:debugOff()
    print("关闭调试模式")
    self.DEBUG = false
  end

  function prototype:addState(args)
    local state = assert(args.state, "state cannot be nil")
    local enter = assert(args.enter, "enter function cannot be nil")
    local exit = assert(args.exit, "exit function cannot be nil")
    self.states[state] = {
      enter = enter,
      exit = exit
    }
    if not self.transitions[state] then
      self.transitions[state] = {}
    end
  end

  function prototype:addTransition(args)
    local oldState = assert(args.oldState, "oldState cannot be nil")
    local newState = assert(args.newState, "newState cannot be nil")
    local event = assert(args.event, "event cannot be nil")
    local action = assert(args.action, "action cannot be nil")
    if not self.states[oldState] then
      error("old state does not exist: " .. oldState, 2)
    end
    if not self.states[newState] then
      error("new state does not exist: " .. newState, 2)
    end
    -- by default, action run after new state is entered
    local transition = {
      newState = newState
    }
    if type(action) == "function" then
      transition.afterEnter = action
    elseif type(action) == "table" then
      transition.beforeExit = action.beforeExit
      transition.afterEnter = action.afterEnter
    end
    self.transitions[oldState][event] = transition
  end

  function prototype:setState(state) self.currState = state end

  function prototype:getState() return self.currState end

  function prototype:fire(event)
    self:debug("状态", self.currState, "事件", event)
    local transition = self.transitions[self.currState][event]
    --    tprint(transition)
    if not transition then
      print(string.format("当前状态[%s]不接受事件[%s]", self.currState or "nil", event or "nil"))
    else
      self:debug("当前状态", self.currState, "事件", event)
      -- using coroutine instead of function so that inside we can
      -- make use of wait functionalities
      local transitioner = coroutine.create(function()
        if transition.beforeExit then
          self:debug("执行退出前转换")
          transition.beforeExit()
        end

        self:debug("退出状态", self.currState)
        self.states[self.currState].exit()
        self.currState = transition.newState

        self:debug("进入状态", self.currState)
        self.states[self.currState].enter()

        if transition.afterEnter then
          self:debug("执行进入后转换")
          transition.afterEnter()
        end

        return coroutine.yield()
      end)
      local ok, ret = coroutine.resume(transitioner)
      if not ok then
        error(ret, 2)
      end
      return ret
    end
  end

  return prototype
end
return define_FSM()

