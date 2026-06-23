--!strict
--[[
    Magic numbers and the package-wide logger used across Canopus.
]]

local Constants = {}

Constants.DEFAULT_LEASE_DURATION = 30
Constants.DEFAULT_RENEWAL_INTERVAL = 10
Constants.DEFAULT_RETRY_INTERVAL = 0.5
Constants.DEFAULT_MAX_RETRIES = 0
Constants.DEFAULT_STORE_NAME = "CanopusLocks"

Constants.TTL_SAFETY_MARGIN = 5
Constants.RELEASE_TTL = 1 -- MemoryStoreSortedMap:UpdateAsync requires expiration > 0
Constants.MAX_BACKOFF_SECONDS = 5
Constants.JITTER_RANGE = 0.2

Constants.LOG_PREFIX = "[Canopus]"

function Constants.log(level: string, message: string): ()
    local formatted = Constants.LOG_PREFIX .. " " .. message
    if level == "warn" then
        warn(formatted)
    elseif level == "error" then
        error(formatted, 0)
    else
        print(formatted)
    end
end

return Constants
