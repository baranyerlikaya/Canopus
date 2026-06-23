--!strict

local Shared = script.Shared
local Internal = script.Internal

local Config = require(Shared.Config)
local Types = require(Shared.Types)
local Errors = require(script.Errors)
local Acquirer = require(Internal.Acquirer)
local Renewer = require(Internal.Renewer)

export type Handle = Types.Handle
export type AcquireOptions = Types.AcquireOptions
export type ConfigOverrides = Types.ConfigOverrides

local Canopus = {}

Canopus.onLockLost = Renewer.onLockLost
Canopus.Errors = Errors

function Canopus.configure(overrides: ConfigOverrides?): ()
    Config.set(overrides)
end

function Canopus.run(lockName: string, callback: () -> any): (boolean, any)
    local handle, err = Acquirer.acquire(lockName, nil)

    if handle == nil then
        return false, err
    end

    local success, result = pcall(callback)

    handle:release()

    if not success then
        return false, result
    end

    return true, result
end

function Canopus.tryAcquire(lockName: string): Handle?
    return Acquirer.tryAcquire(lockName)
end

function Canopus.acquire(lockName: string, options: AcquireOptions?): (Handle?, string?)
    return Acquirer.acquire(lockName, options)
end

function Canopus.getOwner(lockName: string): string?
    return Acquirer.getOwner(lockName)
end

function Canopus.isOwned(lockName: string): boolean
    return Acquirer.isOwned(lockName)
end

return Canopus
