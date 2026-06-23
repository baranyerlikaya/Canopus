--!strict

local Result = {}
Result.__index = Result

export type Result<T, E> = {
    isOk: (self: Result<T, E>) -> boolean,
    isErr: (self: Result<T, E>) -> boolean,
    unwrap: (self: Result<T, E>) -> T,
    unwrapErr: (self: Result<T, E>) -> E,
    match: <R>(self: Result<T, E>, ok: (T) -> R, err: (E) -> R) -> R,
}

type ResultImpl<T, E> = {
    _ok: boolean,
    _value: T?,
    _error: E?,
}

function Result.Ok<T, E>(value: T): Result<T, E>
    local self: ResultImpl<T, E> = {
        _ok = true,
        _value = value,
        _error = nil,
    }
    return (setmetatable(self, Result) :: any) :: Result<T, E>
end

function Result.Err<T, E>(errorValue: E): Result<T, E>
    local self: ResultImpl<T, E> = {
        _ok = false,
        _value = nil,
        _error = errorValue,
    }
    return (setmetatable(self, Result) :: any) :: Result<T, E>
end

function Result.isOk<T, E>(self: ResultImpl<T, E>): boolean
    return self._ok
end

function Result.isErr<T, E>(self: ResultImpl<T, E>): boolean
    return not self._ok
end

function Result.unwrap<T, E>(self: ResultImpl<T, E>): T
    if not self._ok then
        error("Called unwrap on an Err value: " .. tostring(self._error), 2)
    end
    return self._value :: T
end

function Result.unwrapErr<T, E>(self: ResultImpl<T, E>): E
    if self._ok then
        error("Called unwrapErr on an Ok value", 2)
    end
    return self._error :: E
end

function Result.match<T, E, R>(self: ResultImpl<T, E>, ok: (T) -> R, err: (E) -> R): R
    if self._ok then
        return ok(self._value :: T)
    else
        return err(self._error :: E)
    end
end

table.freeze(Result)

return Result
