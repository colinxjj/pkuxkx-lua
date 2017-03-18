--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/3/17
-- Time: 19:59
-- To change this template use File | Settings | File Templates.
--
require "wait"
local helper = require "pkuxkx.helper"
local FSM = require "pkuxkx.FSM"
local travel = require "pkuxkx.travel"

local p1 = "一招一式有板有眼，你可以回去和宁中则复命了。"

local p2 = [[
> 你向宁中则打听有关『job』的消息。
宁中则看着你，道：好久没有见过向右转(turnright) 龙图(longtu) 本田(dddtt) 夜轻舞(yeqingwu) 这些人了，你在江湖中，如果遇到这些前辈中的一个，代我向他问个好(wenhao)吧，并把礼品带给他。
任务完成后直接在宁中则面前输入finish，如果无法完成，请输入fail。
宁中则给了你一包礼物。

本色(ywx)告诉你：【大高手(Grobot)】目前在【扬州的客店】,快去摁死它吧!

完成任务后，你被奖励了：

你对着渡娘深深一揖：鄙派掌门向渡娘问好。

你向宁中则打听有关『job』的消息。
王亮涛决定开始跟随你一起行动。
宁中则对你说道：最近华山来了些新弟子，你带去练功房指点(zhidian)一下吧。

王亮涛趁你不注意，一溜烟不知道跑到哪里去了。

王亮涛道：好吧，好吧，我回去还不行吗？

王亮涛道：休息一会行不行啊？

王亮涛一招一式有板有眼，你可以回去和宁中则复命了。

完成任务后，你被奖励了：

]]



local define_teach = function()
  local prototype = FSM.inheritedMeta()
  local States = {
    stop = "stop",    -- 停止状态
    ask = "ask",    -- 询问任务
    teaching = "teaching",    -- 教导中
    searching = "searching",    -- 搜索中
    begging = "begging",    -- 当老师好可怜
    wait_ask = "wait_ask",    -- 等待询问任务
    submit = "submit",    -- 提交任务
    wenhao = "wenhao",    -- 问好...
  }
  local Events = {
    STOP = "stop",    -- 停止信号
    START = "start",    -- 开始信号
    NO_JOB_AVAILABLE = "no_job_available",    -- 目前没有任务（完成的太快）
    NEW_TEACH = "new_teach",    -- 得到一个新的教导任务
    NEW_WENHAO = "new_wenhao",    -- 得到一个新的问好任务
    PREV_JOB_NOT_FINISH = "prev_job_not_finish",    -- 之前的任务没有完成
    START_TEACH = "start_teach",    -- 开始教导
    START_WENHAO = "start_wenhao",    -- 开始问好
    TEACH_DONE = "teach_done",    -- 教导结束
    SUBMIT_DONE = "submit_done",    -- 提交成功
    STUDENT_ESCAPED = "student_escaped",    -- 学生溜走了
    STUDENT_FOUND = "student_found",    -- 找到学生了
    STUDENT_NOT_FOUND = "student_not_found",    -- 没找到学生
    STUDENT_PERSUADED = "studuent_persuaded",    -- 学生同意继续学习
    CONTINUE_TEACH = "continue_teach",    -- 继续教学
    PAUSE_WAIT = "pause_wait",    -- 停止等待
    GO_BACK_TEACH = "go_back_teach",    -- 回去教
    CONTINUE_BEG = "continue_beg",    -- 继续求
  }
  local REGEXP = {
    NEW_JOB_TEACH = "^[ >]*宁中则对你说道：最近华山来了些新弟子，你带去练功房指点\\(zhidian\\)一下吧。$",
    NEW_JOB_WENHAO = "^[ >]*宁中则看着你，道：好久没有见过(.*?) 这些人了，你在江湖中，如果遇到这些前辈中的一个，代我向他问个好\\(wenhao\\)吧，并把礼品带给他。\\s*$",
    STUDENT_FOLLOWED = "^[ >]*(.*)决定开始跟随你一起行动。$",
    PREV_JOB_NOT_FINISH = "^[ >]*岳灵珊说道：「你上次任务还没有完成呢！」$",
    NEXT_JOB_WAIT = "^[ >]*岳灵珊说道：「等你忙完再来找我吧。」$",
    NEXT_JOB_TOO_FAST = "^[ >]*岳灵珊说道：「等你忙完再来找我吧。」$",
    -- EXP_TOO_HIGH = "^[ >]*岳灵珊说道：「你的功夫不错了，找我娘看看有什么任务交给你。」$",
    ASK_START = "^[ >]*设定环境变量：huashan_teach = \"ask_start\"$",
    ASK_DONE = "^[ >]*设定环境变量：huashan_teach = \"ask_done\"$",
    -- PATROLLING="^[ >]*你在(.+?)巡弋，尚未发现敌踪。$",    -- used in wait.regexp
    STUDENT_ESCAPED = "^[ >]*(.+)趁你不注意，一溜烟不知道跑到哪里去了。$",
    STUDENT_IMPROVED = "^[ >]*(.+)一招一式有板有眼，你可以回去和宁中则复命了。$",
    STUDENT_PERSUADED = "^[ >]*(.+)道：好吧，好吧，我回去还不行吗？$",
    -- STUDENT_DESC = "^[ >]*华山.*弟子(.*)refined$",
    TEACH_START = "^[ >]*设定环境变量：huashan_teach = \"teach_start\"$",
    TEACH_DONE = "^[ >]*设定环境变量：huashan_teach = \"teach_done\"$",
    BEG_START = "^[ >]*设定环境变量：huashan_teach = \"beg_start\"$",
    BEG_DONE = "^[ >]*设定环境变量：huashan_teach = \"beg_done\"$",
    SUBMIT_START = "^[ >]*设定环境变量：huashan_patrol = \"submit_start\"$",
    SUBMIT_DONE = "^[ >]*设定环境变量：huashan_patrol = \"submit_done\"$",
    SUBMIT_SUCCESS = "^[ >]*完成任务后，你被奖励了：$",
    NOT_BUSY = "^[ >]*你现在不忙。$",
    DZ_FINISH = "^[ >]*你将运转于任督二脉间的内息收回丹田，深深吸了口气，站了起来。$",
    DZ_NEILI_ADDED = "^[ >]*你的内力增加了！！$"
  }
  local teacherId = "scala"
  local teacherName = "斯卡拉"

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
    self.studentId = teacherId .. "'s student"
    self:resetOnStop()
  end

  function prototype:initStates()
    self:addState {
      state = States.stop,
      enter = function()
        self:resetOnStop()
        self:disableAllTriggers()
      end,
      exit = function() end
    }
    self:addState {
      state = States.ask,
      enter = function()
        self.studentName = nil
        self.wenhaoList = nil
        self.jobType = nil
        helper.enableTriggerGroups("huashan_teach_ask_start")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_teach_ask_start", "huashan_teach_ask_done")
      end
    }
    self:addState {
      state = States.teaching,
      enter = function()
        self.studentEscaped = false
        self.studentImproved = false
        helper.enableTriggerGroups("huashan_teach_teaching_start")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_teach_teaching_start", "huashan_teach_teaching_done")
      end
    }
    self:addState {
      state = States.wenhao,
      enter = function()

      end,
      exit = function()

      end
    }
    self:addState {
      state = States.searching,
      enter = function()
        self.studentCaught = false
      end,
      exit = function()
        self.studentCaught = false
      end
    }
    self:addState {
      state = States.begging,
      enter = function()
        self.studentPersuaded = false
        helper.enableTriggerGroups("huashan_teach_beg_start")
      end,
      exit = function()
        self.studentPersuaded = false
        helper.disableTriggerGroups("huashan_teach_beg_start", "huashan_teach_beg_done")
      end
    }
    self:addState {
      state = States.wait_ask,
      enter = function()
        helper.enableTriggerGroups("huashan_teach_wait_ask")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_teach_wait_ask")
      end
    }
    self:addState {
      state = States.submit,
      enter = function()
        self.submitted = false
        helper.enableTriggerGroups("huashan_teach_submit_start")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_teach_submit_start", "huashan_teach_submit_done")
      end
    }
  end

  function prototype:initTransitions()
    -- transition from state<stop>
    self:addTransition {
      oldState = States.stop,
      newState = States.ask,
      event = Events.START,
      action = function()
        travel:walkto(66, function()
          self:doAsk()
        end)
      end
    }
    -- transition from state<ask>
    self:addTransition {
      oldState = States.ask,
      newState = States.teaching,
      event = Events.NEW_TEACH,
      action = function()
        travel:walkto(2918, function()
          self:doTeach()
        end)
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.wenhao,
      event = Events.NEW_WENHAO,
      action = function()
        self:doWenhao()
      end
    }
    self:addTransition {
      oldState = States.ask,
      newState = States.wait_ask,
      event = Events.NO_JOB_AVAILABLE,
      action = function()
        travel:walto(2921, function()
          self:doWaitAsk()
        end)
      end
    }
    self:addTransitionToStop(States.ask)
    -- transition from state<wait_ask>
    self:addTransition {
      oldState = States.wait_ask,
      newState = States.ask,
      event = Events.PAUSE_WAIT,
      action = function()
        travel:walkto(66, function()
          self:doAsk()
        end)
      end
    }
    -- transition from state<teaching>
    self:addTransition {
      oldState = States.teaching,
      newState = States.teaching,
      event = Events.CONTINUE_TEACH,
      action = function()
        -- 每次教导间隔2秒
        wait.time(2)
        self:doTeach()
      end
    }
    self:addTransition {
      oldState = States.teaching,
      newState = States.searching,
      event = Events.STUDENT_ESCAPED,
      action = function()
        travel:traverse {
          rooms = travel:getNearbyRooms(8),
          check = function()
            return self:catchStudent()
          end,
          action = function()
            if self.studentCaught then
              return self:fire(Events.STUDENT_FOUND)
            else
              return self:fire(Events.STUDENT_NOT_FOUND)
            end
          end
        }
      end
    }
    self:addTransition {
      oldState = States.teaching,
      newState = States.submit,
      event = Events.TEACH_DONE,
      action = function()
        travel:walkto(66, function()
          self:doSubmit()
        end)
      end
    }
    self:addTransitionToStop(States.teaching)
    -- transition from state<searching>
    self:addTransition {
      oldState = States.searching,
      newState = States.begging,
      event = Events.STUDENT_FOUND,
      action = function()
        self:doBeg()
      end
    }
    self:addTransition {
      oldState = States.searching,
      newState = States.stop,
      event = Events.STUDENT_NOT_FOUND,
      action = function()
        print("找不到学生了！任务失败")
      end
    }
    self:addTransitionToStop(States.searching)
    -- transition from state<begging>
    self:addTransition {
      oldState = States.begging,
      newState = States.teaching,
      event = Events.STUDENT_PERSUADED,
      action = function()
        travel:walkto(2918, function()
          self:doTeach()
        end)
      end
    }
    self:addTransition {
      oldState = States.begging,
      newState = States.begging,
      event = Events.CONTINUE_BEG,
      action = function()
        time.wait(1)
        self:doBeg()
      end
    }
    self:addTransitionToStop(States.begging)
    -- transition from state<submit>
    self:addTransition {
      oldState = States.submit,
      newState = States.ask,
      event = Events.SUBMIT_DONE,
      action = function()
        wait.time(3)
        self:doAsk()
      end
    }
    self:addTransitionToStop(States.submit)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "huashan_teach_ask_start", "huashan_teach_ask_done",
      "huashan_teach_wait_ask",
      "huashan_teach_teaching_start", "huashan_teach_teaching_done",
      "huashan_teach_beg_start", "huashan_teach_beg_done",
      "huashan_teach_submit_start", "huashan_teach_submit_done",
      "huashan_teach_wenhao_start", "huashan_teach_wenhao_done")
    -- 开始询问
    helper.addTrigger {
      group = "huashan_teach_ask_start",
      regexp = REGEXP.ASK_START,
      response = function()
        helper.enableTriggerGroups("huashan_teach_ask_done")
      end
    }
    -- 获取student名称
    helper.addTrigger {
      group = "huashan_teach_ask_done",
      regexp = REGEXP.STUDENT_FOLLOWED,
      response = function(name, line, wildcards)
        local name = wildcards[1]
        self.studentName = name
      end
    }
    -- 获取任务类型
    helper.addTrigger {
      group = "huashan_teach_ask_done",
      regexp = REGEXP.NEW_JOB_TEACH,
      response = function()
        self.jobType = "teach"
      end
    }
    -- 解析问好任务
    helper.addTrigger {
      group = "huashan_teach_ask_done",
      regexp = REGEXP.NEW_JOB_WENHAO,
      response = function(name, line, wildcards)
        local patterns = utils.split(wildcards[1], " ")
        local players = {}
        for _, pattern in ipairs(patterns) do
          local str = utils.split(pattern, "(")
          local name = str[1]
          local id = string.gsub(str[2], ")", "")
          table.insert(players, {name=name, id=id})
        end
        self.wenhaoList = players
        self.jobType = "wenhao"
      end
    }
    -- 发送新任务
    helper.addTrigger {
      group = "huashan_teach_ask_done",
      regexp = REGEXP.ASK_DONE,
      response = function()
        if self.jobType == "teach" then
          self:fire(Events.NEW_TEACH)
        else
          self:fire(Events.NEW_WENHAO)
        end
      end
    }
    -- 开始教
    helper.addTrigger {
      group = "huashan_teach_teaching_start",
      regexp = REGEXP.TEACH_START,
      response = function()
        helper.enableTriggerGroups("huashan_teach_teaching_done")
      end
    }
    -- 判断继续教，搜，回复
    helper.addTrigger {
      group = "huashan_teach_teaching_done",
      regexp = REGEXP.TEACH_DONE,
      response = function()
        if self.studentEscaped then
          self:fire(Events.STUDENT_ESCAPED)
        elseif self.studentImproved then
          self:fire(Events.STUDENT_IMPROVED)
        else
          self:fire(Events.CONTINUE_TEACH)
        end
      end
    }
    -- 学生逃跑
    helper.addTrigger {
      group = "huashan_teach_teaching_done",
      regexp = REGEXP.STUDENT_ESCAPED,
      response = function(name, line, wildcards)
        local name = wildcards[1]
        if name == self.studentName then
          self.studentEscaped = true
        end
      end
    }
    -- 学生进步，可以复命
    helper.addTrigger {
      group = "huashan_teach_teaching_done",
      regexp = REGEXP.STUDENT_IMPROVED,
      response = function(name, line, wildcards)
        local name = wildcards[1]
        if name == self.studentName then
          self.studentImproved = true
        end
      end
    }
    -- 等待询问
    helper.addTrigger {
      group = "huashan_teach_wait_ask",
      regexp = REGEXP.DZ_FINISH,
      response = function()
        SendNoEcho("dz max")
      end
    }
    -- 停止等待
    helper.addTrigger {
      group = "huashan_teach_wait_ask",
      regexp = REGEXP.DZ_NEILI_ADDED,
      response = function()
        self:fire(Events.PAUSE_WAIT)
      end
    }
    -- 开始求
    helper.addTrigger {
      group = "huashan_teach_beg_start",
      regexp = REGEXP.BEG_START,
      response = function()
        helper.enableTriggerGroups("huashan_teach_beg_done")
      end
    }
    -- 判断继续求还是回去教
    helper.addTrigger {
      group = "huashan_teach_beg_done",
      regexp = REGEXP.BEG_DONE,
      response = function()
        if self.studentPersuaded then
          self:fire(Events.STUDENT_PERSUADED)
        else
          self:fire(Events.CONTINUE_BEG)
        end
      end
    }
    -- 成功劝服
    helper.addTrigger {
      group = "huashan_teach_beg_done",
      regexp = REGEXP.STUDENT_PERSUADED,
      response = function()
        local name = wildcards[1]
        if name == self.studentName then
          self.studentPersuaded = true
        end
      end
    }
    -- 开始提交
    helper.addTrigger {
      group = "huashan_teach_submit_start",
      regexp = REGEXP.SUBMIT_START,
      response = function()
        helper.enableTriggerGroups("huashan_teach_submit_done")
      end
    }
    -- 结束提交
    helper.addTrigger {
      group = "huashan_teach_submit_done",
      regexp = REGEXP.SUBMIT_DONE,
      response = function()
        if self.submitted then
          self:fire(Events.SUBMIT_DONE)
        else
          print("失败。任务无法提交")
          self:fire(Events.STOP)
        end
      end
    }
    -- 成功提交
    helper.addTrigger {
      group = "huashan_teach_submit_done",
      regexp = REGEXP.SUBMIT_SUCCESS,
      response = function()
        self.submitted = true
      end
    }
  end

  function prototype:initAliases() end

  function prototype:addTransitionToStop(fromState)
    self:addTransition {
      oldState = fromState,
      newState = States.stop,
      event = Events.STOP,
      action = function()
        print("停止教导任务 - 当前状态", self.currState)
      end
    }
  end

  function prototype:doAsk()
    SendNoEcho("set huashan_teach ask_start")
    SendNoEcho("ask ning about job")
    SendNoEcho("set huashan_teach ask_done")
  end

  function prototype:doTeach()
    SendNoEcho("set huashan_teach teach_start")
    SendNoEcho("zhidian " .. self.studentId)
    SendNoEcho("set huashan_teach teach_done")
  end

  function prototype:doWenhao()

  end

  function prototype:doWaitAsk()
    SendNoEcho("dz max")
  end

  function prototype:doSubmit()
    SendNoEcho("set huashan_teach submit_start")
    SendNoEcho("ask ning about finish")
    SendNoEcho("set huashan_teach submit_done")
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups(
      "huashan_teach_ask_start", "huashan_teach_ask_done",
      "huashan_teach_teaching_start", "huashan_teach_teaching_done",
      "huashan_teach_beg_start", "huashan_teach_beg_done",
      "huashan_teach_submit_start", "huashan_teach_submit_done",
      "huashan_teach_wenhao_start", "huashan_teach_wenhao_done",
      "huashan_teach_wait_ask")
  end

  function prototype:resetOnStop()
    self.studentCaught = false
    self.studentImproved = false
    self.studentEscaped = false
    self.studentPersuaded = false
    self.submitted = false
    self.studentName = nil
    self.wenhaoList = nil
    self.jobType = nil
  end

  return prototype
end
return define_teach().FSM()


