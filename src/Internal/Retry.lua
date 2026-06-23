--!strict
--[[
    Pure exponential backoff with jitter. No side effects, fully unit testable.
]]

local Retry = {}

function Retry.nextWait(
    attemptNumber: number,
    baseInterval: number,
    maxCap: number,
    jitterRange: number
): number
    local exponential = baseInterval * (2 ^ (attemptNumber - 1))
    local capped = math.min(exponential, maxCap)

    local jitterFactor = 1 + (math.random() * 2 - 1) * jitterRange
    local jittered = capped * jitterFactor

    return math.max(jittered, 0)
end

return Retry
