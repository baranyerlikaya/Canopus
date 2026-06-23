--!strict

local Constants = require(script.Parent.Parent.Shared.Constants)
local Config = require(script.Parent.Parent.Shared.Config)
local Types = require(script.Parent.Parent.Shared.Types)
local LockEntry = require(script.Parent.LockEntry)
local MemoryStoreClient = require(script.Parent.MemoryStoreClient)
local Retry = require(script.Parent.Retry)
local Handle = require(script.Parent.Handle)
local Renewer = require(script.Parent.Renewer)
local Errors = require(script.Parent.Parent.Errors)

type Handle = Types.Handle
type AcquireOptions = Types.AcquireOptions

local Acquirer = {}

local function tryAcquireOnce(
    lockName: string,
    leaseDuration: number,
    ownerId: string
): (boolean, Types.LockEntry?, string?)
    local config = Config.get()
    local jobId = ownerId
    local now = workspace:GetServerTimeNow()
    local ttl = leaseDuration + Constants.TTL_SAFETY_MARGIN

    local resultMonad = MemoryStoreClient.update(
        config.storeName,
        lockName,
        function(existing: any): any
            if existing == nil then
                return LockEntry.encode(LockEntry.new(jobId, now + leaseDuration, 1, now))
            end

            local entry = LockEntry.decode(existing)

            if entry == nil then

                return LockEntry.encode(LockEntry.new(jobId, now + leaseDuration, 1, now))
            end

            if LockEntry.isExpired(entry, now) then
                return LockEntry.encode(
                    LockEntry.new(jobId, now + leaseDuration, entry.version + 1, now)
                )
            end

            if LockEntry.isOwnedBy(entry, jobId) then
                return LockEntry.encode(
                    LockEntry.bumpVersion(LockEntry.refresh(entry, now, leaseDuration))
                )
            end

            return existing
        end,
        ttl
    )

    return resultMonad:match(
        function(result: any)
            local decoded = LockEntry.decode(result)
            if decoded == nil then
                return false, nil, Errors.ERR_MEMORY_STORE_UNAVAILABLE
            end
            if LockEntry.isOwnedBy(decoded, jobId) then
                return true, decoded, nil
            end
            return false, nil, Errors.ERR_CONTENDED
        end,
        function(_err: string)
            return false, nil, Errors.ERR_MEMORY_STORE_UNAVAILABLE
        end
    )
end

function Acquirer.acquire(
    lockName: string,
    options: AcquireOptions?,
    ownerId: string?
): (Handle?, string?)
    local config = Config.get()
    local opts: AcquireOptions = options or {}
    local leaseDuration = opts.leaseDuration or config.leaseDuration
    local timeout = opts.timeout
    local owner = ownerId or game.JobId

    local attempt = 0
    local startTime = os.clock()

    while true do
        local acquired, entry = tryAcquireOnce(lockName, leaseDuration, owner)

        if acquired and entry ~= nil then
            local handle = Handle.new(lockName, owner, entry.version, leaseDuration)
            Renewer.start(handle)
            return handle, nil
        end

        attempt += 1

        if config.maxRetries > 0 and attempt > config.maxRetries then
            return nil, Errors.ERR_TIMEOUT
        end

        if timeout ~= nil and (os.clock() - startTime) >= timeout then
            return nil, Errors.ERR_TIMEOUT
        end

        local waitTime = Retry.nextWait(
            attempt,
            config.retryInterval,
            Constants.MAX_BACKOFF_SECONDS,
            Constants.JITTER_RANGE
        )
        task.wait(waitTime)
    end
end

function Acquirer.tryAcquire(lockName: string, ownerId: string?): Handle?
    local config = Config.get()
    local owner = ownerId or game.JobId
    local acquired, entry = tryAcquireOnce(lockName, config.leaseDuration, owner)

    if acquired and entry ~= nil then
        local handle = Handle.new(lockName, owner, entry.version, config.leaseDuration)
        Renewer.start(handle)
        return handle
    end

    return nil
end

function Acquirer.release(handle: any): boolean
    local state = handle[Handle.Private]
    if not state.active then
        return false
    end

    Renewer.stop(handle :: Handle)
    state.active = false

    local config = Config.get()
    local lockName = state.lockName
    local jobId = state.jobId

    local resultMonad = MemoryStoreClient.update(
        config.storeName,
        lockName,
        function(existing: any): any
            if existing == nil then
                return existing
            end

            local entry = LockEntry.decode(existing)
            if entry ~= nil and LockEntry.isOwnedBy(entry, jobId) then
                return LockEntry.encode(LockEntry.expire(entry))
            end

            return existing
        end,
        Constants.RELEASE_TTL
    )

    return resultMonad:isOk()
end

function Acquirer.getOwner(lockName: string): string?
    local config = Config.get()
    local resultMonad = MemoryStoreClient.read(config.storeName, lockName)
    if resultMonad:isErr() then
        return nil
    end
    local raw = resultMonad:unwrap()

    local entry = LockEntry.decode(raw)
    if entry == nil then
        return nil
    end

    local now = workspace:GetServerTimeNow()
    if LockEntry.isExpired(entry, now) then
        return nil
    end

    return entry.owner
end

function Acquirer.isOwned(lockName: string): boolean
    return Acquirer.getOwner(lockName) ~= nil
end

Handle._setCallbacks(Acquirer.release, Renewer.renewOnce)

return Acquirer
