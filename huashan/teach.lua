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
local status = require "pkuxkx.status"

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
你对崔久慕挥了挥手，崔久慕转身离去了。

完成任务后，你被奖励了：

在指点弟子练功中，你印证心中所学，经验增加了一点。

    斯卡拉教导的华山弟子 崔久慕(Scala's student)

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
    cancel = "cancel"    -- 取消任务
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
    WENHAO_DONE = "wenhao_done",    -- 问好成功
    WENHAO_FAIL = "wenhao_fail",    -- 问好失败
  }
  local REGEXP = {
    NEW_JOB_TEACH = "^[ >]*宁中则对你说道：最近华山来了些新弟子，你带去练功房指点\\(zhidian\\)一下吧。$",
    NEW_JOB_WENHAO = "^[ >]*宁中则看着你，道：好久没有见过(.*?) 这些人了，你在江湖中，如果遇到这些前辈中的一个，代我向他问个好\\(wenhao\\)吧，并把礼品带给他。\\s*$",
    STUDENT_FOLLOWED = "^[ >]*(.*)决定开始跟随你一起行动。$",
    PREV_JOB_NOT_FINISH = "^[ >]*宁中则说道：「你上次任务还没有完成呢！」$",
    NEXT_JOB_WAIT = "^[ >]*岳灵珊说道：「等你忙完再来找我吧。」$",
    WORK_TOO_FAST = "^[ >]*宁中则说道：「你刚刚做过任务，先去休息一会吧。」$",
    EXP_TOO_HIGH = "^[ >]*宁中则说道：「你的功夫不错了，在我这学不到什么了，去找掌门吧。」$",
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
    SUBMIT_START = "^[ >]*设定环境变量：huashan_teach = \"submit_start\"$",
    SUBMIT_DONE = "^[ >]*设定环境变量：huashan_teach = \"submit_done\"$",
    SUBMIT_SUCCESS = "^[ >]*完成任务后，你被奖励了：$",
    CANCEL_START = "^[ >]*设定环境变量：huashan_teach = \"cancel_start\"$",
    CANCEL_DONE = "^[ >]*设定环境变量：huashan_teach = \"cancel_done\"$",
    DZ_FINISH = "^[ >]*你将运转于任督二脉间的内息收回丹田，深深吸了口气，站了起来。$",
    DZ_NEILI_ADDED = "^[ >]*你的内力增加了！！$",
    WENHAO_DESC = "^[ >]*你对着(.+)深深一揖：鄙派掌门向.*问好。$"
  }
  local teacherId = "luar"
  local teacherName = "撸啊"

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
        self.noJobAvailable = false
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
        helper.enableTriggerGroups("huashan_teach_wenhao")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_teach_wenhao")
      end
    }
    self:addState {
      state = States.searching,
      enter = function()
        self.studentCaught = false
        helper.enableTriggerGroups("huashan_teach_searching")
      end,
      exit = function()
        self.studentCaught = false
        helper.disableTriggerGroups("huashan_teach_searching")
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
    self:addState {
      state = States.cancel,
      enter = function()
        helper.enableTriggerGroups("huashan_teach_cancel_start")
      end,
      exit = function()
        helper.disableTriggerGroups("huashan_teach_cancel_start", "huashan_teach_cancel_done")
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
        travel:stop()
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
        travel:walkto(2921, function()
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
    self:addTransitionToStop(States.wait_ask)
    -- transition from state<teaching>
    self:addTransition {
      oldState = States.teaching,
      newState = States.teaching,
      event = Events.CONTINUE_TEACH,
      action = function()
        helper.assureNotBusy()
        self:doTeach()
      end
    }
    self:addTransition {
      oldState = States.teaching,
      newState = States.searching,
      event = Events.STUDENT_ESCAPED,
      action = function()
        local check = function() return self.studentCaught end
        local action = function()
          if self.studentCaught then
            return self:fire(Events.STUDENT_FOUND)
          else
            return self:fire(Events.STUDENT_NOT_FOUND)
          end
        end
        self:debug("准备搜索")
        helper.assureNotBusy()
        travel:traverseZone("huashan", check, action)
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
        helper.assureNotBusy()
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
        helper.assureNotBusy()
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
        -- 此处，添加判断食物饮水
        status:hpbrief()
        if status.food < 100 or status.drink < 100 then
          return travel:walkto(3798, function()
            helper.assureNotBusy()
            SendNoEcho("do 2 eat")
            helper.assureNotBusy()
            SendNoEcho("do 2 drink")
            helper.assureNotBusy()
            wait.time(3)
            return travel:walkto(66, function()
              return self:doAsk()
            end)
          end)
        else
          -- 就在当前房间
          wait.time(3)
          return self:doAsk()
        end
      end
    }
    self:addTransitionToStop(States.submit)
    -- transition from state<wenhao>
    self:addTransition {
      oldState = States.wenhao,
      newState = States.submit,
      event = Events.WENHAO_DONE,
      action = function()
        travel:walkto(66, function()
          self:doSubmit()
        end)
      end
    }
    self:addTransition {
      oldState = States.wenhao,
      newState = States.cancel,
      event = Events.WENHAO_FAIL,
      action = function()
        travel:walkto(66, function()
          self:doCancel()
        end)
      end
    }
    self:addTransitionToStop(States.wenhao)
    -- transition from state<cancel>
    self:addTransition {
      oldState = States.cancel,
      newState = States.ask,
      event = Events.START,
      action = function()
        self:doAsk()
      end
    }
    self:addTransitionToStop(States.cancel)
  end

  function prototype:initTriggers()
    helper.removeTriggerGroups(
      "huashan_teach_ask_start", "huashan_teach_ask_done",
      "huashan_teach_wait_ask",
      "huashan_teach_teaching_start", "huashan_teach_teaching_done",
      "huashan_teach_beg_start", "huashan_teach_beg_done",
      "huashan_teach_searching",
      "huashan_teach_submit_start", "huashan_teach_submit_done",
      "huashan_teach_cancel_start", "huashan_teach_cancel_done",
      "huashan_teach_wenhao")
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
        self:debug("问好玩家有", wildcards[1])
        local patterns = utils.split(wildcards[1], " ")
        local players = {}
        for _, pattern in ipairs(patterns) do
          local str = utils.split(pattern, "(") -- the utils.split implementatin is not different
          local name = str[1]
          local id = string.gsub(str[2], "%)", "")
          table.insert(players, {name=name, id=id})
        end
        self.wenhaoList = players
        self.jobType = "wenhao"
      end
    }
    -- 做的太快没任务
    helper.addTrigger {
      group = "huashan_teach_ask_done",
      regexp = REGEXP.WORK_TOO_FAST,
      response = function()
        self.noJobAvailable = true
      end
    }
    -- 发送新任务
    helper.addTrigger {
      group = "huashan_teach_ask_done",
      regexp = REGEXP.ASK_DONE,
      response = function()
        if self.jobType == "teach" then
          self:fire(Events.NEW_TEACH)
        elseif self.jobType == "wenhao" then
          self:fire(Events.NEW_WENHAO)
        elseif self.noJobAvailable then
          self:fire(Events.NO_JOB_AVAILABLE)
        else
          print("没有获取到任务，出错")
          self:fire(Events.stop)
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
          self:fire(Events.TEACH_DONE)
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
      response = function(name, line, wildcards)
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
    -- 查找弟子
    helper.addTrigger {
      group = "huashan_teach_searching",
      regexp = "^[ >]*" .. teacherName .. "教导的华山弟子 (.*)\\(.*'s student\\)$",
      response = function(name, line, wildcards)
        local name = wildcards[1]
        if name == self.studentName then
          self:debug("找到我的弟子", name)
          self.studentCaught = true
        else
          self:debug("这不是我的弟子", self.studentName, name)
        end
      end
    }
    -- 取消任务开始
    helper.addTrigger {
      group = "huashan_teach_cancel_start",
      regexp = REGEXP.CANCEL_START,
      response = function()
        helper.enableTriggerGroups("huashan_teach_cancel_done")
      end
    }
    -- 取消任务结束
    helper.addTrigger {
      group = "huashan_teach_cancel_done",
      regexp = REGEXP.CANCEL_DONE,
      response = function()
        self:fire(Events.START)
      end
    }
    -- 问好
    helper.addTrigger {
      group = "huashan_teach_wenhao",
      regexp = REGEXP.WENHAO_DESC,
      response = function()

      end
    }
  end

  function prototype:initAliases()
    helper.removeAliasGroups("huashan_teach")

    helper.addAlias {
      group = "huashan_teach",
      regexp = "^teaching\\s*$",
      response = function()
        print("TEACHING华山新手教导任务，用法如下：")
        print("teaching start", "开始教导")
        print("teaching stop", "完成当前任务后，停止巡逻")
        print("teaching debug on/off", "开启/关闭巡逻调试模式")
      end
    }

    helper.addAlias {
      group = "huashan_teach",
      regexp = "^teaching\\s+start\\s*$",
      response = function()
        self:fire(Events.START)
      end
    }
    helper.addAlias {
      group = "huashan_teach",
      regexp = "^teaching\\s+stop\\s*$",
      response = function()
        self:fire(Events.STOP)
      end
    }
    helper.addAlias {
      group = "huashan_teach",
      regexp = "^teaching\\s+debug\\s+(on|off)\\s*$",
      response = function(name, line, wildcards)
        local cmd = wildcards[1]
        if cmd == "on" then
          self:debugOn()
        elseif cmd == "off" then
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
    print("请手动执行问好任务")
  end

  function prototype:doBeg()
    SendNoEcho("set huashan_teach beg_start")
    SendNoEcho("ask " .. self.studentId .. " about 指点")
    SendNoEcho("set huashan_teach beg_done")
  end

  function prototype:doWaitAsk()
    print("等待10秒后再询问")
    wait.time(10)
    return self:fire(Events.PAUSE_WAIT)
  end

  function prototype:doSubmit()
    SendNoEcho("set huashan_teach submit_start")
    SendNoEcho("ask ning about finish")
    SendNoEcho("set huashan_teach submit_done")
  end

  function prototype:doCancel()
    SendNoEcho("set huashan_teach cancel_start")
    SendNoEcho("ask ning about fail")
    SendNoEcho("set huashan_teach cancel_done")
  end

  function prototype:disableAllTriggers()
    helper.disableTriggerGroups(
      "huashan_teach_ask_start", "huashan_teach_ask_done",
      "huashan_teach_wait_ask",
      "huashan_teach_teaching_start", "huashan_teach_teaching_done",
      "huashan_teach_beg_start", "huashan_teach_beg_done",
      "huashan_teach_searching",
      "huashan_teach_submit_start", "huashan_teach_submit_done",
      "huashan_teach_wenhao")
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
    self.noJobAvailable = false
  end

  return prototype
end
return define_teach():FSM()


