--
-- Job.lua
-- User: zhe.jiang
-- Date: 2017/4/5
-- Desc:
-- 任务数据类型，配合任务调度模块使用，
-- 实现任务执行引擎后可通过设置job.start和job.stop方法
--
-- Change:
-- 2017/4/5 - created

local pattern = {
  [[

│[01][门]门忠任务                未接受任务。                                                  │
│[02][门]门派任务                未接受任务。                                                  │
│[03][新]送信                    未接受任务。                                                  │
│[04][新]唱戏任务                未接受任务。                                                  │
│[05][新]灵柩护卫                未接受任务。                                                  │
│[06][主]慕容任务(0)             现在即可接到下个任务。                                        │
│[07][主]韩员外复仇(0)           现在即可接到下个任务。                                        │
│[08][主]都统制府刺杀(0)         现在即可接到下个任务。                                        │
│[09][主]运镖任务(0)             现在即可接到下个新手镖局的任务。                              │
│[10][主]胡一刀任务(0)           现在即可接到下个任务。                                        │
│[11][主]萧峰任务(0)             现在即可接到下个任务。                                        │
│[12][主]韩世忠任务(0)           现在即可接到下个任务。                                        │
│[13][主]公孙止任务(0)           现在即可接到下个任务。                                        │
│[14][主]万安塔任务(0) ↑        现在即可接到下个任务。                                        │
│[15][主]破阵任务(0)             现在即可接到下个任务。                                        │
│[16][主]天珠任务(0)             现在即可接到下个任务。                                        │
│[17][主]偷学任务(0)             现在即可接到下个任务。                                        │
│[18][主]华山送信任务(0)         现在即可接到下个任务。                                        │
│[19][主]投名状任务(0)           现在即可接到下个任务。                                        │
│[20][主]萧半和任务(0)           未接受任务。                                                  │
│[21][主]鄱阳湖寻宝(0)           现在即可接到下个任务。                                        │
│[22][特]锻造任务                未接受任务。                                                  │
│[23][特]满不懂任务              未接受任务。                                                  │
│[24][特]铜雀台任务              现在即可接到下个任务。                                        │
│[25][特]百晓生任务              现在即可接到下个任务。                                        │
│[26][特]公孙绿萼任务            现在即可接到下个任务。                                        │

  ]]
}

local define_Job = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    local obj = {}
    obj.id = assert(args.id, "id of job cannot be nil")
    obj.name = assert(args.name, "name of job cannot be nil")
    obj.code = assert(args.code, "code of job cannot be nil")
    obj.times = args.times or 0
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    assert(obj.id, "id of job cannot be nil")
    assert(obj.name, "name of job cannot be nil")
    assert(obj.code, "code of job cannot be nil")
    obj.times = obj.times or 0
    setmetatable(obj, self or prototype)
    return obj
  end

  -- define all the jobs
  prototype.menzhong = prototype:decorate {
    id = 1,
    name = "门忠任务",
    code = "menzhong"
  }
  prototype.murong = prototype:decorate {
    id = 6,
    name = "慕容任务",
    code = "murong"
  }
  prototype.hanyuanwai = prototype:decorate {
    id = 7,
    name = "韩元外复仇",
    code = "hanyuanwai"
  }
  prototype.cisha = prototype:decorate {
    id = 8,
    name = "都统制府刺杀",
    code = "cisha"
  }
  prototype.yunbiao = prototype:decorate {
    id = 9,
    name = "运镖任务",
    code = "yunbiao"
  }
  prototype.huyidao = prototype:decorate {
    id = 10,
    name = "胡一刀任务",
    code = "huyidao"
  }
  prototype.xiaofeng = prototype:decorate {
    id = 11,
    name = "萧峰任务",
    code = "xiaofeng"
  }
  prototype.hanshizhong = prototype:decorate {
    id = 12,
    name = "韩世忠任务",
    code = "hanshizhong"
  }
  prototype.gongsunzhi = prototype:decorate {
    id = 13,
    name = "公孙止任务",
    code = "gongsunzhi"
  }
  prototype.wananta = prototype:decorate {
    id = 14,
    name = "万安塔任务",
    code = "wananta"
  }
  prototype.pozhen = prototype:decorate {
    id = 15,
    name = "破阵任务",
    code = "pozhen"
  }
  prototype.tianzhu = prototype:decorate {
    id = 16,
    name = "天珠任务",
    code = "tianzhu",
  }
  prototype.touxue = prototype:decorate {
    id = 17,
    name = "偷学任务",
    code = "touxue"
  }
  prototype.songxin = prototype:decorate {
    id = 18,
    name = "华山送信任务",
    code = "songxin"
  }
  prototype.toumingzhuang = prototype:decorate {
    id = 19,
    name = "投名状任务",
    code = "toumingzhuang"
  }
  prototype.poyanghu = prototype:decorate {
    id = 20,
    name = "鄱阳湖寻宝",
    code = "poyanghu"
  }

  return prototype
end
return define_Job()

