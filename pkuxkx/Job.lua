--
-- Job.lua
-- User: zhe.jiang
-- Date: 2017/4/5
-- Desc:
-- �����������ͣ�����������ģ��ʹ�ã�
-- ʵ������ִ��������ͨ������job.start��job.stop����
--
-- Change:
-- 2017/4/5 - created

local pattern = {
  [[

��[01][��]��������                δ��������                                                  ��
��[02][��]��������                δ��������                                                  ��
��[03][��]����                    δ��������                                                  ��
��[04][��]��Ϸ����                δ��������                                                  ��
��[05][��]���ѻ���                δ��������                                                  ��
��[06][��]Ľ������(0)             ���ڼ��ɽӵ��¸�����                                        ��
��[07][��]��Ա�⸴��(0)           ���ڼ��ɽӵ��¸�����                                        ��
��[08][��]��ͳ�Ƹ���ɱ(0)         ���ڼ��ɽӵ��¸�����                                        ��
��[09][��]��������(0)             ���ڼ��ɽӵ��¸������ھֵ�����                              ��
��[10][��]��һ������(0)           ���ڼ��ɽӵ��¸�����                                        ��
��[11][��]��������(0)             ���ڼ��ɽӵ��¸�����                                        ��
��[12][��]����������(0)           ���ڼ��ɽӵ��¸�����                                        ��
��[13][��]����ֹ����(0)           ���ڼ��ɽӵ��¸�����                                        ��
��[14][��]��������(0) ��        ���ڼ��ɽӵ��¸�����                                        ��
��[15][��]��������(0)             ���ڼ��ɽӵ��¸�����                                        ��
��[16][��]��������(0)             ���ڼ��ɽӵ��¸�����                                        ��
��[17][��]͵ѧ����(0)             ���ڼ��ɽӵ��¸�����                                        ��
��[18][��]��ɽ��������(0)         ���ڼ��ɽӵ��¸�����                                        ��
��[19][��]Ͷ��״����(0)           ���ڼ��ɽӵ��¸�����                                        ��
��[20][��]���������(0)           δ��������                                                  ��
��[21][��]۶����Ѱ��(0)           ���ڼ��ɽӵ��¸�����                                        ��
��[22][��]��������                δ��������                                                  ��
��[23][��]����������              δ��������                                                  ��
��[24][��]ͭȸ̨����              ���ڼ��ɽӵ��¸�����                                        ��
��[25][��]����������              ���ڼ��ɽӵ��¸�����                                        ��
��[26][��]������������            ���ڼ��ɽӵ��¸�����                                        ��

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
    name = "��������",
    code = "menzhong"
  }
  prototype.murong = prototype:decorate {
    id = 6,
    name = "Ľ������",
    code = "murong"
  }
  prototype.hanyuanwai = prototype:decorate {
    id = 7,
    name = "��Ԫ�⸴��",
    code = "hanyuanwai"
  }
  prototype.cisha = prototype:decorate {
    id = 8,
    name = "��ͳ�Ƹ���ɱ",
    code = "cisha"
  }
  prototype.yunbiao = prototype:decorate {
    id = 9,
    name = "��������",
    code = "yunbiao"
  }
  prototype.huyidao = prototype:decorate {
    id = 10,
    name = "��һ������",
    code = "huyidao"
  }
  prototype.xiaofeng = prototype:decorate {
    id = 11,
    name = "��������",
    code = "xiaofeng"
  }
  prototype.hanshizhong = prototype:decorate {
    id = 12,
    name = "����������",
    code = "hanshizhong"
  }
  prototype.gongsunzhi = prototype:decorate {
    id = 13,
    name = "����ֹ����",
    code = "gongsunzhi"
  }
  prototype.wananta = prototype:decorate {
    id = 14,
    name = "��������",
    code = "wananta"
  }
  prototype.pozhen = prototype:decorate {
    id = 15,
    name = "��������",
    code = "pozhen"
  }
  prototype.tianzhu = prototype:decorate {
    id = 16,
    name = "��������",
    code = "tianzhu",
  }
  prototype.touxue = prototype:decorate {
    id = 17,
    name = "͵ѧ����",
    code = "touxue"
  }
  prototype.songxin = prototype:decorate {
    id = 18,
    name = "��ɽ��������",
    code = "songxin"
  }
  prototype.toumingzhuang = prototype:decorate {
    id = 19,
    name = "Ͷ��״����",
    code = "toumingzhuang"
  }
  prototype.poyanghu = prototype:decorate {
    id = 20,
    name = "۶����Ѱ��",
    code = "poyanghu"
  }

  return prototype
end
return define_Job()

