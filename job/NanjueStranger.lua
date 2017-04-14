--
-- NanjueStranger.lua
-- User: zhe.jiang
-- Date: 2017/4/10
-- Desc:
-- Change:
-- 2017/4/10 - created


local define_NanjueStranger = function()
  local prototype = {}
  prototype.__index = prototype

  function prototype:new(args)
    local obj = {}
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:decorate(obj)
    setmetatable(obj, self or prototype)
    return obj
  end

  function prototype:confirmed()
    assert(self.shoeType, "shoeType cannot be nil")
    assert(self.shoeColor, "shoeColor cannot be nil")
    assert(self.clothType, "clothType cannot be nil")
    assert(self.clothColor, "clothColor cannot be nil")
    assert(self.height, "height cannot be nil")
    assert(self.weight, "weight cannot be nil")
    assert(self.age, "age cannot be nil")
    assert(self.gender, "gender cannot be nil")
    assert(self.roomId, "roomId cannot be nil")
    assert(self.name, "name cannot be nil")
    assert(self.id, "id cannot be nil")
    assert(self.seq, "seq cannot be nil")
    -- self.identifyFeature
  end

  function prototype:show()
    print("��ǰ·����Ϣ���£�")
    print("������", self.name)
    print("�Ա�", self.gender)
    print("���䣺", self.age)
    print("��ߣ�", self.height)
    print("���أ�", self.weight)
    print("�·����ʣ�", self.clothType)
    print("�·���ɫ��", self.clothColor)
    print("Ь�Ӳ��ʣ�", self.shoeType)
    print("Ь����ɫ��", self.shoeColor)
    if self.identifyFeature then
      print("֤�����ݣ�", next(self.identifyFeature))
    else
      print("֤�����ݣ�", "��")
    end
  end

  return prototype
end
return define_NanjueStranger()


