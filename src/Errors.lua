--!strict
--[[
    Typed error constants used throughout Canopus. These are returned as the
    error string from public API calls rather than thrown, except where a
    misconfiguration must fail loudly (ERR_INVALID_CONFIG).
]]

local Errors = {
    ERR_TIMEOUT = "ERR_TIMEOUT",
    ERR_MEMORY_STORE_UNAVAILABLE = "ERR_MEMORY_STORE_UNAVAILABLE",
    ERR_INVALID_CONFIG = "ERR_INVALID_CONFIG",
    ERR_LOCK_LOST = "ERR_LOCK_LOST",
    ERR_CONTENDED = "ERR_CONTENDED",
    ERR_NOT_OWNER = "ERR_NOT_OWNER",
}

return Errors
