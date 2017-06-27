--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/4/21
-- Time: 7:42
-- To change this template use File | Settings | File Templates.
--

local patterns = {[[
高亦说道：「不是冤家不聚头，纳命来吧！！」
>
ne
高亦往西南离开。

test
看起来高亦想杀死你！

                北大侠客行任务榜
─────────────────────────────────
        王重阳的先天罡气谱       (未完成)
        达摩老祖的菩提杖         (未完成)
        张三丰的太极剑           (未完成)
        段誉的香罗帕             (未完成)
        李莫愁的毒经             (未完成)
        令狐冲的佩剑             (未完成)
        岳灵珊的玉佩             (未完成)
        洪七公的布袋             (未完成)
        穷汉的破碗               (未完成)
        郭芙的头巾               (未完成)
        宁中则的淑女剑           (未完成)
        农夫的锄头               (未完成)
        多隆的官印               (未完成)
        浪回头的带血的丝巾       (未完成)
        向问天的包袱             (未完成)
        托钵僧的化缘钵           (未完成)
        张无忌的木剑             (未完成)
        欧阳克的白扇             (未完成)
        瑛姑的算筹               (未完成)
        东方不败的绣花针         (未完成)
        渔隐的鱼杆               (未完成)
        李秋水的天蚕衣           (未完成)
        鸠摩智的易筋经           (未完成)
        陆高轩的蝌蚪译文         (未完成)
        吴三桂的虎符             (未完成)
        郭靖的九阴真经           (未完成)
        岳不群的紫霞袍           (未完成)
        虚竹的掌门指环           (未完成)
        灭绝师太的念珠           (未完成)
        裘千仞的水缸             (未完成)
        田伯光的断龙刀           (未完成)
        丁春秋的神木鼎           (未完成)
        杨过的竹剑               (未完成)
        黄药师的玉石子           (未完成)
        傻姑的烧饼               (未完成)
        陈近南的花名册           (未完成)
        楚云飞的盟主令           (未完成)
─────────────────────────────────
上一轮争胜模式胜利的门派是：华山派
下一轮争胜模式开始的时间是：二十一点九分。

locate 吴三桂的虎符
吴三桂的虎符在一个有着north,south,east,west,enter的出口的地方。
这个地方的描述中含有这样的字眼：这里,兴县

get all from bing
你从官兵身上搜出一块虎符。
你从官兵身上除下一件军服。
你从官兵身上除下一柄钢刀。

l hu fu
虎符(Hu fu)

>
give hu fu to wu
你被奖励了三十八点经验和四点潜能！
吴三桂说道：不才已经查到偷走此宝的恶贼,老爷子若是能将其诛杀，不才感激不尽，武林中人也必定对阁下刮目相看。
吴三桂说道：前几天江湖出现此贼消息，我这里也有一份线报，你拿去看看吧。
你的客户端不支持MXP,请直接打开链接查看图片。
请注意，忽略验证码中的红色文字。
http://pkuxkx.net/antirobot/robot.php?filename=1498282409210119

左波说道：「不是冤家不聚头，纳命来吧！！」
丝绸之路
    「混沌降魔豹」左波(Zuo bo)


左波叹了口气，我认栽。
你被奖励了三百四十六点经验和一百二十四点潜能!
你获得了金钱奖励！
从左波身上掉了出来一颗水★炎晶


]]}

local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"
local status = require "pkuxkx.status"

local define_fsm = function()
  local prototype = FSM.inheritedMeta()

  local States = {
    stop = "stop"
  }
  local Events = {
    STOP = "stop",
    START = "start"
  }
  local REGEXP = {
    ALIAS_START = "^fsmalias\\s+start\\s*$",
    ALIAS_STOP = "^fsmalias\\s+stop\\s*$",
    ALIAS_DEBUG = "^fsmalias\\s+debug\\s+(on|off)\\s*$",
  }

  local TaskItems = {
    {
      itemId = "",
      itemName = "王重阳的先天罡气谱",
      npcId = "wang chongyang",
      npcName = "王重阳",
    },
    {
      itemId = "",
      itemName = "张三丰的太极剑",
      npcId = "zhang sanfeng",
      npcName = "张三丰",
    },
    {
      itemId = "",
      itemName = "段誉的香罗帕",
      npcId = "duan yu",
      npcName = "段誉"
    },
    {
      itemId = "",
      itemName = "李莫愁的毒经",
      npcId = "li mochou",
      npcName = "李莫愁"
    },
    {
      itemId = "",
      itemName = "令狐冲的佩剑",
      npcId = "linghu chong",
      npcName = "令狐冲"
    },
    {
      itemId = "",
      itemName = "岳灵珊的玉佩",
      npcId = "yue lingshan",
      npcName = "岳灵珊"
    },
    {
      itemId = "",
      itemName = "郭芙的头巾",
      npcId = "guo fu",
      npcName = "郭芙"
    },
    {
      itemId = "",
      itemName = "宁中则的淑女剑",
      npcId = "ning zhongze",
      npcName = "宁中则"
    },

  }


  function prototype:FSM()
    local obj = FSM:new()
    setmetatable(obj, self or prototype)
    obj:postConstruct()
    return obj
  end

  function prototype:postConstruct()
    self:initStates()
    self:initTransitions()
    self:initTriggers()
    self:initAliases()
    self:setState(States.stop)
  end

  function prototype:disableAllTriggers()

  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:disableAllTriggers()
      end,
      exit = function() end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransitionToStop(States.stop)

  end

  function prototype:initTriggers()

  end

  function prototype:initAliases()
    helper.removeAliasGroups("fsmalias")
    helper.addAlias {
      group = "fsmalias",
      regexp = REGEXP.ALIAS_START,
      response = function()
        return self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "fsmalias",
      regexp = REGEXP.ALIAS_STOP,
      response = function()
        return self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "fsmalias",
      regexp = REGEXP.ALIAS_DEBUG,
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self:debugOn()
        else
          self:debugOff()
        end
      end
    }
  end

  function prototype:addTransitionToStop(fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function()
        print("停止 - 当前状态", self.currState)
      end
    }
  end

  return prototype
end
return define_fsm():FSM()
