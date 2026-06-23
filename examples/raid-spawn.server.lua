--!strict
--[[
    Example: a weekly raid boss spawns exactly once across all servers.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Canopus = require(ReplicatedStorage.Packages.Canopus)

local function spawnRaidBoss(): ()
    -- ... actual raid boss spawn logic goes here ...
end

task.spawn(function()
    while true do
        task.wait(60) -- check every minute

        local week = math.floor(os.time() / 604800)
        local lockName = "raid-spawn:week-" .. week

        local handle = Canopus.tryAcquire(lockName)
        if handle ~= nil then
            print("This server is hosting this week's raid")
            spawnRaidBoss()
            -- Hold the lock for an hour so other servers know not to spawn.
            task.wait(3600)
            handle:release()
        end
    end
end)
