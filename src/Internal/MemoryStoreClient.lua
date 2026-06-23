--!strict
--[[
    Thin wrapper around MemoryStoreService SortedMap operations. Every
    MemoryStore access made by Canopus passes through this module so that
    error handling and logging stay in one place.
]]

local MemoryStoreService = game:GetService("MemoryStoreService")

local Constants = require(script.Parent.Parent.Shared.Constants)

local MemoryStoreClient = {}

local mapCache: { [string]: MemoryStoreSortedMap } = {}

local function getMap(storeName: string): MemoryStoreSortedMap
    local existing = mapCache[storeName]
    if existing ~= nil then
        return existing
    end

    local map = MemoryStoreService:GetSortedMap(storeName)
    mapCache[storeName] = map
    return map
end

MemoryStoreClient.getMap = getMap

function MemoryStoreClient.update(
    storeName: string,
    key: string,
    transform: (existing: any) -> any,
    ttl: number
): (boolean, any)
    local map = getMap(storeName)
    local success, result = pcall(function()
        return map:UpdateAsync(key, transform, ttl)
    end)

    if not success then
        return false, result
    end

    return true, result
end

function MemoryStoreClient.read(storeName: string, key: string): (boolean, any)
    local map = getMap(storeName)
    local success, result = pcall(function()
        return map:GetAsync(key)
    end)

    if not success then
        return false, result
    end

    return true, result
end

return MemoryStoreClient
