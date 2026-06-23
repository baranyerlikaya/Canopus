--!strict
--[[
    Background renewal for held locks. Owns the actual MemoryStore renewal
    transform; the periodic loop and a manual single-shot renew both call
    into the same renewOnce() so behavior never diverges between the two.
]]

local Constants = require(script.Parent.Parent.Shared.Constants)
local Config = require(script.Parent.Parent.Shared.Config)
local Types = require(script.Parent.Parent.Shared.Types)
local Signal = require(script.Parent.Parent.Shared.Signal)
local LockEntry = require(script.Parent.LockEntry)
local MemoryStoreClient = require(script.Parent.MemoryStoreClient)
local Errors = require(script.Parent.Parent.Errors)

type Handle = Types.Handle

local Renewer = {}

local activeThreads: { [Handle]: thread } = {}

local onLockLost: Signal.SignalInstance = Signal.new()
Renewer.onLockLost = onLockLost

function Renewer.renewOnce(handle: Handle): boolean
    local config = Config.get()
    local storeName = config.storeName
    local lockName = handle._lockName
    local jobId = handle._jobId
    local now = workspace:GetServerTimeNow()

    local success, result = MemoryStoreClient.update(
        storeName,
        lockName,
        function(existing: any): any
            if existing == nil then
                return nil
            end

            local entry = LockEntry.decode(existing)
            if entry == nil or not LockEntry.isOwnedBy(entry, jobId) then
                return existing
            end

            return LockEntry.encode(
                LockEntry.bumpVersion(LockEntry.refresh(entry, now, handle._leaseDuration))
            )
        end,
        handle._leaseDuration + Constants.TTL_SAFETY_MARGIN
    )

    if not success then
        return false
    end

    local decoded = LockEntry.decode(result)
    if decoded == nil or not LockEntry.isOwnedBy(decoded, jobId) then
        return false
    end

    handle._version = decoded.version
    return true
end

function Renewer.start(handle: Handle): ()
    local config = Config.get()

    local thread = task.spawn(function()
        while handle._active do
            task.wait(config.renewalInterval)
            if not handle._active then
                return
            end

            local renewed = Renewer.renewOnce(handle)
            if not renewed then
                handle._active = false
                activeThreads[handle] = nil
                onLockLost:Fire(handle._lockName, Errors.ERR_LOCK_LOST)
                return
            end
        end
    end)

    activeThreads[handle] = thread
    handle._renewerThread = thread
end

function Renewer.stop(handle: Handle): ()
    local thread = activeThreads[handle]
    if thread ~= nil then
        activeThreads[handle] = nil
        if coroutine.status(thread) ~= "dead" then
            task.cancel(thread)
        end
    end
end

return Renewer
