--!strict

local MemoryStoreService = game:GetService("MemoryStoreService")
local Result = require(script.Parent.Parent.Shared.Result)

type Result<T, E> = Result.Result<T, E>

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
): Result<any, string>
    local map = getMap(storeName)
    local success, result = pcall(function()
        return map:UpdateAsync(key, transform, ttl)
    end)

    if not success then
        return Result.Err(tostring(result))
    end

    return Result.Ok(result)
end

function MemoryStoreClient.read(storeName: string, key: string): Result<any, string>
    local map = getMap(storeName)
    local success, result = pcall(function()
        return map:GetAsync(key)
    end)

    if not success then
        return Result.Err(tostring(result))
    end

    return Result.Ok(result)
end

table.freeze(MemoryStoreClient)

return MemoryStoreClient
