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
    print("当前路人信息如下：")
    print("姓名：", self.name)
    print("性别：", self.gender)
    print("年龄：", self.age)
    print("身高：", self.height)
    print("体重：", self.weight)
    print("衣服材质：", self.clothType)
    print("衣服颜色：", self.clothColor)
    print("鞋子材质：", self.shoeType)
    print("鞋子颜色：", self.shoeColor)
    if self.identifyFeature then
      print("证词内容：", next(self.identifyFeature))
    else
      print("证词内容：", "无")
    end
  end

  return prototype
end
return define_NanjueStranger()


