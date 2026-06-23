--!strict
--[[
    Lock handle object returned to callers on successful lock acquisition.
    Release/renew are delegated to callbacks registered by Acquirer/Renewer
    so this module has no dependency on them (avoids a require cycle).
]]

local Types = require(script.Parent.Parent.Shared.Types)

type Handle = Types.Handle

local Handle = {}
Handle.__index = Handle

local releaseCallback: ((Handle) -> boolean)? = nil
local renewCallback: ((Handle) -> boolean)? = nil

function Handle._setCallbacks(onRelease: (Handle) -> boolean, onRenew: (Handle) -> boolean): ()
    releaseCallback = onRelease
    renewCallback = onRenew
end

function Handle.new(lockName: string, jobId: string, version: number, leaseDuration: number): Handle
    local self: Handle = setmetatable({
        _lockName = lockName,
        _jobId = jobId,
        _version = version,
        _leaseDuration = leaseDuration,
        _active = true,
        _renewerThread = nil,
    }, Handle) :: any

    return self
end

function Handle.isActive(self: Handle): boolean
    return self._active
end

function Handle.renew(self: Handle): boolean
    if not self._active or renewCallback == nil then
        return false
    end
    return renewCallback(self)
end

function Handle.release(self: Handle): boolean
    if not self._active or releaseCallback == nil then
        return false
    end
    return releaseCallback(self)
end

function Handle.getName(self: Handle): string
    return self._lockName
end

function Handle.getVersion(self: Handle): number
    return self._version
end

return Handle
