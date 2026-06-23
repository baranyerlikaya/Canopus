--!strict

local Constants = require(script.Parent.Parent.Shared.Constants)
local Config = require(script.Parent.Parent.Shared.Config)
local Types = require(script.Parent.Parent.Shared.Types)
local Signal = require(script.Parent.Parent.Shared.Signal)
local LockEntry = require(script.Parent.LockEntry)
local MemoryStoreClient = require(script.Parent.MemoryStoreClient)
local Errors = require(script.Parent.Parent.Errors)

type Handle = Types.Handle

local Renewer = {}


local onLockLost: Signal.SignalInstance = Signal.new()
Renewer.onLockLost = onLockLost

function Renewer.renewOnce(handle: Handle): boolean
    local config = Config.get()
    local storeName = config.storeName
    local state = handle[Handle.Private]
    local lockName = state.lockName
    local jobId = state.jobId
    local leaseDuration = state.leaseDuration
    local now = workspace:GetServerTimeNow()

    local resultMonad = MemoryStoreClient.update(
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
                LockEntry.bumpVersion(LockEntry.refresh(entry, now, leaseDuration))
            )
        end,
        leaseDuration + Constants.TTL_SAFETY_MARGIN
    )

    return resultMonad:match(
        function(result: any)
            if result == nil then
                return false
            end
            local entry = LockEntry.decode(result)
            if entry ~= nil then
                state.version = entry.version
                return true
            end
            return false
        end,
        function(_err: string)
            return false
        end
    )
end

function Renewer.start(handle: Handle): ()
    local state = handle[Handle.Private]
    if not state.active then
        return
    end

    local config = Config.get()
    local interval = config.renewalInterval

    local thread = task.spawn(function()
        while state.active do
            task.wait(interval)
            if not state.active then
                break
            end

            local success = Renewer.renewOnce(handle)
            if not success and state.active then
                state.active = false
                Renewer.onLockLost:Fire(state.lockName, Errors.ERR_LOCK_LOST)
                break
            end
        end
    end)

    state.renewerThread = thread
end

function Renewer.stop(handle: Handle): ()
    local state = handle[Handle.Private]
    local thread = state.renewerThread
    if thread ~= nil then
        state.renewerThread = nil
        if coroutine.status(thread) ~= "dead" then
            task.cancel(thread)
        end
    end
end

return Renewer
