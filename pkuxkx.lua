--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2017/2/25
-- Time: 12:26
-- To change this template use File | Settings | File Templates.
--

require "constants"
require "socket.core"
local sleep = function(n)
    socket.select(nil, nil, n)
end

local travel = require "travel.init"
local tprint = require "utils/tprint"

local paths, startid = travel:search(1, 5)

wait = {}
local threads = {}

wait.trigger_resume = function(name)
    local thread = threads[name]
    if thread then
        threads[name] = nil
        coroutine.resume(thread)
--        if not ok then error(err) end
    end
end

world = {}
local _triggers = {}
local _tsize = 0
world.add_trigger = function(name, delay)
--    print(triggers, name, _triggers[name])
    if not _triggers[name] then
        _tsize = _tsize + 1
    end
    _triggers[name] = delay
--    print(_tsize)
end

world.dispatch = function()
    while true do
        if _tsize == 0 then break end
--        print("----")
--        tprint(_triggers)
        local copy = {}
        for name, delay in pairs(_triggers) do
            copy[name] = delay
        end
        for name, delay in pairs(copy) do
            if delay <= 0 then
                _triggers[name] = nil
                _tsize = _tsize - 1
                wait.trigger_resume(name)
--                if not ok then error("failed to resume thread") end
            else
                _triggers[name] = delay - 1
            end
        end
--        sleep(1)
    end
end

local step = function(paths, steps)
    local steps = steps or 5
    return coroutine.create(function()
        while (#paths > 0) do
            local segment = {}
            local i = 1
            local path = table.remove(paths)
            while path and i <= steps do
                i = i + 1
                table.insert(segment, path.path)
                path = table.remove(paths)
            end
            print(table.concat(segment, ";"))
            coroutine.yield()
        end
    end)
end

local id = 0
local uniqueId = function()
    id = id + 1
    return id
end

local continueWalk = function(step)
    return coroutine.create(function()
        local name
        while true do
            name = "walk_trg" .. uniqueId()
            local ok = coroutine.resume(step)
            if ok then
                -- continue to work
                threads[name] = assert(coroutine.running(), "walk must be in coroutine")
                world.add_trigger(name, 1)
                coroutine.yield()
            else
                break
            end
        end
    end)
end

local walker = continueWalk(step(paths, 5))
coroutine.resume(walker)

world.dispatch()


