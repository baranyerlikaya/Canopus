--!strict
--[[
    Example: safely lock both participants' inventories during a cross-server
    trade, regardless of which Roblox server instance each player is on.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Canopus = require(ReplicatedStorage.Packages.Canopus)

local function performAtomicSwap(userA: number, userB: number, items: { [string]: any }): boolean
    -- ... actual inventory swap logic goes here ...
    return true
end

local function executeTrade(userA: number, userB: number, items: { [string]: any }): (boolean, any)
    local lowId = math.min(userA, userB)
    local highId = math.max(userA, userB)
    local lockName = "trade:" .. lowId .. ":" .. highId

    local success, result = Canopus.run(lockName, function()
        -- Both players' inventories are now safely locked
        -- regardless of which server they are on.
        return performAtomicSwap(userA, userB, items)
    end)

    return success, result
end

return executeTrade
