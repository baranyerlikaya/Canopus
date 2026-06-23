--!strict

local Result = require(script.Parent.Result)

export type Result<T, E> = Result.Result<T, E>

export type LockName = string
export type JobId = string
export type LockEntry = {
    owner: string,
    expiry: number,
    version: number,
    acquired: number,
}

export type Config = {
    leaseDuration: number,
    renewalInterval: number,
    retryInterval: number,
    maxRetries: number,
    storeName: string,
}

export type ConfigOverrides = {
    leaseDuration: number?,
    renewalInterval: number?,
    retryInterval: number?,
    maxRetries: number?,
    storeName: string?,
}

export type AcquireOptions = {
    timeout: number?,
    leaseDuration: number?,
}

export type Handle = {
    isActive: (self: Handle) -> boolean,
    renew: (self: Handle) -> boolean,
    release: (self: Handle) -> boolean,
    getName: (self: Handle) -> string,
    getVersion: (self: Handle) -> number,
}

return table.freeze({})
