--!strict

local Types = require(script.Parent.Parent.Shared.Types)

type Handle = Types.Handle

local Handle = {}
Handle.__index = Handle

-- Opaque symbol for memory-safe privacy
local Private = newproxy(false)
Handle.Private = Private

export type HandleState = {
    lockName: string,
    jobId: string,
    version: number,
    leaseDuration: number,
    active: boolean,
    renewerThread: thread?,
}

local releaseCallback: ((Handle) -> boolean)? = nil
local renewCallback: ((Handle) -> boolean)? = nil

function Handle._setCallbacks(onRelease: (Handle) -> boolean, onRenew: (Handle) -> boolean): ()
    releaseCallback = onRelease
    renewCallback = onRenew
end

function Handle.new(lockName: string, jobId: string, version: number, leaseDuration: number): Handle
    local state: HandleState = {
        lockName = lockName,
        jobId = jobId,
        version = version,
        leaseDuration = leaseDuration,
        active = true,
        renewerThread = nil,
    }

    local self = setmetatable({
        [Private] = state,
    }, Handle) :: any

    return table.freeze(self) :: Handle
end

function Handle.isActive(self: any): boolean
    local state: HandleState = self[Private]
    return state.active
end

function Handle.renew(self: any): boolean
    local state: HandleState = self[Private]
    if not state.active or renewCallback == nil then
        return false
    end
    return renewCallback(self :: Handle)
end

function Handle.release(self: any): boolean
    local state: HandleState = self[Private]
    if not state.active or releaseCallback == nil then
        return false
    end
    return releaseCallback(self :: Handle)
end

function Handle.getName(self: any): string
    local state: HandleState = self[Private]
    return state.lockName
end

function Handle.getVersion(self: any): number
    local state: HandleState = self[Private]
    return state.version
end

return Handle
