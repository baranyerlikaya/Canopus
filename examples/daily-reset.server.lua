--!strict
--[[
    Example: ensure a daily reward reset runs exactly once across all servers.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Canopus = require(ReplicatedStorage.Packages.Canopus)

local rewardsStore = DataStoreService:GetDataStore("DailyRewards")

task.spawn(function()
    while true do
        local now = os.time()
        local nextMidnight = now - (now % 86400) + 86400
        task.wait(nextMidnight - now)

        local dateKey = os.date("%Y-%m-%d", nextMidnight)
        local lockName = "daily-reset:" .. dateKey

        local success, err = Canopus.run(lockName, function()
            print("This server is running the daily reset for " .. dateKey)
            rewardsStore:SetAsync("LastResetDate", dateKey)
            -- ... actual reset logic goes here ...
        end)

        if not success then
            warn("Daily reset skipped or failed: " .. tostring(err))
        end
    end
end)
