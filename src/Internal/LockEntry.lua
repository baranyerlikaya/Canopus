--!strict
--[[
    LockEntry struct construction, JSON encode/decode, and validation helpers.
]]

local HttpService = game:GetService("HttpService")

local Types = require(script.Parent.Parent.Shared.Types)

type LockEntry = Types.LockEntry

local LockEntry = {}

function LockEntry.new(owner: string, expiry: number, version: number, acquired: number): LockEntry
    return {
        owner = owner,
        expiry = expiry,
        version = version,
        acquired = acquired,
    }
end

function LockEntry.encode(entry: LockEntry): string
    return HttpService:JSONEncode(entry)
end

function LockEntry.decode(raw: any): LockEntry?
    if raw == nil then
        return nil
    end

    local decoded: any
    if typeof(raw) == "string" then
        local success, result = pcall(function()
            return HttpService:JSONDecode(raw)
        end)
        if not success then
            return nil
        end
        decoded = result
    elseif typeof(raw) == "table" then
        decoded = raw
    else
        return nil
    end

    if typeof(decoded) ~= "table" then
        return nil
    end
    if typeof(decoded.owner) ~= "string" then
        return nil
    end
    if typeof(decoded.expiry) ~= "number" then
        return nil
    end
    if typeof(decoded.version) ~= "number" then
        return nil
    end
    if typeof(decoded.acquired) ~= "number" then
        return nil
    end

    return {
        owner = decoded.owner,
        expiry = decoded.expiry,
        version = decoded.version,
        acquired = decoded.acquired,
    }
end

function LockEntry.isExpired(entry: LockEntry, now: number): boolean
    return entry.expiry < now
end

function LockEntry.isOwnedBy(entry: LockEntry, jobId: string): boolean
    return entry.owner == jobId
end

function LockEntry.bumpVersion(entry: LockEntry): LockEntry
    return {
        owner = entry.owner,
        expiry = entry.expiry,
        version = entry.version + 1,
        acquired = entry.acquired,
    }
end

function LockEntry.refresh(entry: LockEntry, now: number, leaseDuration: number): LockEntry
    return {
        owner = entry.owner,
        expiry = now + leaseDuration,
        version = entry.version,
        acquired = entry.acquired,
    }
end

--[[
    Marks an entry as already expired. Used to release a lock: returning nil
    from MemoryStoreSortedMap:UpdateAsync's transform does NOT delete the
    key (it aborts the write, same as DataStoreService:UpdateAsync), so a
    release has to write an expired entry instead of trying to delete one.
]]
function LockEntry.expire(entry: LockEntry): LockEntry
    return {
        owner = entry.owner,
        expiry = 0,
        version = entry.version + 1,
        acquired = entry.acquired,
    }
end

return LockEntry
