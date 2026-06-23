--!strict

local Constants = require(script.Parent.Constants)
local Types = require(script.Parent.Types)
local Errors = require(script.Parent.Parent.Errors)

type Config = Types.Config
type ConfigOverrides = Types.ConfigOverrides

local Config = {}

local DEFAULT_CONFIG: Config = {
    leaseDuration = Constants.DEFAULT_LEASE_DURATION,
    renewalInterval = Constants.DEFAULT_RENEWAL_INTERVAL,
    retryInterval = Constants.DEFAULT_RETRY_INTERVAL,
    maxRetries = Constants.DEFAULT_MAX_RETRIES,
    storeName = Constants.DEFAULT_STORE_NAME,
}

local currentConfig: Config = table.clone(DEFAULT_CONFIG)

function Config.getDefault(): Config
    return table.clone(DEFAULT_CONFIG)
end

function Config.validate(config: Config): ()
    if config.leaseDuration <= 0 then
        error(Errors.ERR_INVALID_CONFIG .. ": leaseDuration must be greater than 0", 0)
    end
    if config.renewalInterval <= 0 then
        error(Errors.ERR_INVALID_CONFIG .. ": renewalInterval must be greater than 0", 0)
    end
    if config.renewalInterval >= config.leaseDuration / 2 then
        error(
            Errors.ERR_INVALID_CONFIG .. ": renewalInterval must be less than leaseDuration / 2",
            0
        )
    end
    if config.retryInterval <= 0 then
        error(Errors.ERR_INVALID_CONFIG .. ": retryInterval must be greater than 0", 0)
    end
    if config.maxRetries < 0 then
        error(Errors.ERR_INVALID_CONFIG .. ": maxRetries must be greater than or equal to 0", 0)
    end
    if config.storeName == "" then
        error(Errors.ERR_INVALID_CONFIG .. ": storeName must not be empty", 0)
    end
end

function Config.merge(overrides: ConfigOverrides?): Config
    local merged: Config = table.clone(DEFAULT_CONFIG)

    if overrides ~= nil then
        if overrides.leaseDuration ~= nil then
            merged.leaseDuration = overrides.leaseDuration
        end
        if overrides.renewalInterval ~= nil then
            merged.renewalInterval = overrides.renewalInterval
        end
        if overrides.retryInterval ~= nil then
            merged.retryInterval = overrides.retryInterval
        end
        if overrides.maxRetries ~= nil then
            merged.maxRetries = overrides.maxRetries
        end
        if overrides.storeName ~= nil then
            merged.storeName = overrides.storeName
        end
    end

    Config.validate(merged)
    return table.freeze(merged)
end

function Config.set(overrides: ConfigOverrides?): ()
    currentConfig = Config.merge(overrides)
end

function Config.get(): Config
    return currentConfig
end

return Config
