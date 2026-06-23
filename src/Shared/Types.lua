--!strict
--[[
    Shared type definitions used across the Canopus package.
]]

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
    _lockName: string,
    _jobId: string,
    _version: number,
    _leaseDuration: number,
    _active: boolean,
    _renewerThread: thread?,
    isActive: (self: Handle) -> boolean,
    renew: (self: Handle) -> boolean,
    release: (self: Handle) -> boolean,
    getName: (self: Handle) -> string,
    getVersion: (self: Handle) -> number,
}

return {}
