--!strict

local Signal = {}
Signal.__index = Signal

export type Connection = {
    Disconnect: (self: Connection) -> (),
}

export type SignalInstance = {
    Connect: (self: SignalInstance, fn: (...any) -> ()) -> Connection,
    Fire: (self: SignalInstance, ...any) -> (),
}

type Listener = (...any) -> ()

type SignalImpl = {
    _listeners: { Listener },
}

type ConnectionImpl = {
    _listeners: { Listener },
    _listener: Listener,
    _connected: boolean,
}

local ConnectionClass = {}
ConnectionClass.__index = ConnectionClass

function ConnectionClass.Disconnect(self: ConnectionImpl): ()
    if not self._connected then
        return
    end
    self._connected = false

    local listeners = self._listeners
    for index, listener in listeners do
        if listener == self._listener then
            table.remove(listeners, index)
            break
        end
    end
end

function Signal.new(): SignalInstance
    local self: SignalImpl = {
        _listeners = {},
    }
    return (setmetatable(self, Signal) :: any) :: SignalInstance
end

function Signal.Connect(self: SignalImpl, fn: Listener): Connection
    table.insert(self._listeners, fn)

    local connection: ConnectionImpl = {
        _listeners = self._listeners,
        _listener = fn,
        _connected = true,
    }
    return (setmetatable(connection, ConnectionClass) :: any) :: Connection
end

function Signal.Fire(self: SignalImpl, ...: any): ()
    local listenersCopy = table.clone(self._listeners)
    for _, listener in listenersCopy do
        listener(...)
    end
end

return Signal
