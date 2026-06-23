# Canopus

Distributed lock manager for Roblox — make sure something happens **exactly once**, anywhere in your game's server fleet.

![status](https://img.shields.io/badge/status-v0.1.0-blue)
![language](https://img.shields.io/badge/language-Luau%20strict-2c2c2c)
![license](https://img.shields.io/badge/license-see%20LICENSE-lightgrey)

---

## Quick start

```luau
local Canopus = require(game.ReplicatedStorage.Packages.Canopus)

local success, result = Canopus.run("daily-reset", function()
    -- only one server in the world runs this at a time
    resetDailyRewards()
end)
```

That's it — Canopus handles acquisition, lease renewal, retries, and release for you.

---

## Why Canopus

A Roblox experience typically runs on dozens or hundreds of server instances simultaneously. None of them share memory, and none of them know about each other. Some work, however, must happen **once** across the whole fleet:

- **Daily reset** — if every server runs the reset, player data gets reset N times.
- **Cross-server trade** — both participants' inventories need to be locked, even if they're on different servers.
- **Limited drops** — only N copies of an item should ever be created.
- **Quest completion** — a player switching servers mid-quest shouldn't be able to complete it twice.
- **Raid/event spawn** — exactly one server should be the authority for a world event.

Canopus gives you a simple primitive for all of these: *"only one server does this, the rest wait or back off."*

---

## Installation

### Wally

```toml
[dependencies]
Canopus = "baranyerlikaya/canopus@0.1.0"
```

```bash
wally install
```

### Manual

Copy the contents of `src/` into a `Canopus` folder under `ReplicatedStorage.Packages` (or wherever your package location convention places shared modules).

### Roblox Creator Hub model

Releases are also published as a Roblox model on the Creator Hub. Insert it under `ReplicatedStorage` and rename the top-level instance to `Canopus`.

---

## Architecture in brief

- **Storage:** `MemoryStoreService` `SortedMap`, not `DataStoreService` — built-in TTL, atomic `UpdateAsync`, and sub-100ms round trips make it the right primitive for short-lived coordination.
- **One SortedMap, many keys:** every lock is an entry in a single map (`CanopusLocks` by default), keyed by lock name. No upper bound on the number of concurrently held locks.
- **Atomicity:** all state transitions go through `UpdateAsync`'s transform function, which Roblox serializes across servers — there is no client-side compare-and-swap to get wrong.
- **Authority is TTL, not stored time:** the `expiry` field inside a lock entry is informational only. The actual decision of "is this lock still held" is made by MemoryStoreService's own TTL expiry, sidestepping clock skew between servers entirely.
- **Lease + renewal:** holding a lock starts a background renewal loop that extends the TTL every `renewalInterval` seconds. If a server crashes, renewal stops, the TTL lapses, and the lock becomes available again automatically.
- **Retry:** failed acquisitions back off exponentially (with jitter), bounded by `maxRetries` and/or a timeout.

See [`tests/`](tests/) and [`src/Internal/`](src/Internal/) for the exact algorithms.

---

## Configuration

Call once at server start (optional — sensible defaults are used otherwise):

```luau
Canopus.configure({
    leaseDuration = 30,      -- seconds a lock is held before it must be renewed
    renewalInterval = 10,    -- seconds between renewal attempts (must be < leaseDuration / 2)
    retryInterval = 0.5,     -- base seconds between acquisition retries
    maxRetries = 0,          -- 0 = infinite retries
    storeName = "CanopusLocks",
})
```

| Option | Type | Default | Notes |
|---|---|---|---|
| `leaseDuration` | `number` | `30` | How long a lock is valid before renewal is required. |
| `renewalInterval` | `number` | `10` | Must be less than `leaseDuration / 2`. |
| `retryInterval` | `number` | `0.5` | Base wait between retries; doubles each attempt up to a 5s cap, with ±20% jitter. |
| `maxRetries` | `number` | `0` | `0` means retry indefinitely (subject to an explicit `timeout` if given). |
| `storeName` | `string` | `"CanopusLocks"` | Name of the underlying `MemoryStoreSortedMap`. |

---

## API reference

```luau
local Canopus = require(ReplicatedStorage.Packages.Canopus)
```

### `Canopus.configure(overrides: ConfigOverrides?): ()`
Sets global configuration. Throws on invalid config (e.g. `renewalInterval >= leaseDuration / 2`).

### `Canopus.run(lockName: string, callback: () -> any): (boolean, any)`
Acquires the lock, runs `callback`, releases on completion or error. Returns `true, <callback result>` on success, `false, <error>` otherwise. The most common entry point.

### `Canopus.tryAcquire(lockName: string): Handle?`
Non-blocking. Returns a `Handle` immediately if the lock is free, `nil` otherwise.

### `Canopus.acquire(lockName: string, options: AcquireOptions?): (Handle?, string?)`
Blocks (with exponential backoff) until the lock is acquired, `options.timeout` elapses, or `maxRetries` is exhausted. Returns `Handle, nil` on success or `nil, errorString` on failure.

```luau
type AcquireOptions = {
    timeout: number?,        -- max seconds to wait
    leaseDuration: number?,  -- override the configured lease for this call
}
```

### `Canopus.getOwner(lockName: string): string?`
Returns the `JobId` currently holding the lock, or `nil` if free/expired.

### `Canopus.isOwned(lockName: string): boolean`
Shorthand for `Canopus.getOwner(lockName) ~= nil`.

### `Canopus.onLockLost: Signal`
Fires `(lockName: string, reason: string)` when a held lock's renewal fails (e.g. lost to a network partition).

```luau
Canopus.onLockLost:Connect(function(lockName, reason)
    warn(`Lost lock {lockName}: {reason}`)
end)
```

### `Handle`

```luau
handle:isActive(): boolean   -- true if we still own the lock
handle:renew(): boolean      -- manual renewal (rarely needed; renewal is automatic)
handle:release(): boolean    -- release the lock
handle:getName(): string     -- lock name
handle:getVersion(): number  -- current entry version (monotonic, for future fencing use)
```

---

## Performance notes

| Metric | Target |
|---|---|
| Acquire latency, uncontested | < 100ms |
| Acquire latency, contested | bound by `retryInterval` backoff curve |
| Renewal cost | 1 `UpdateAsync` per `renewalInterval` per held lock |
| Memory overhead per held lock | ~200 bytes |
| Background threads per held lock | 1 (the renewal loop) |

---

## Limits & caveats

- `MemoryStoreService` has daily quota limits that scale with concurrent player count. Heavy lock churn (many short-lived locks acquired/released per second) consumes that budget — avoid using Canopus for anything that needs sub-second per-player locking at scale.
- Locks are **advisory**: nothing stops a server from mutating state it doesn't hold the lock for. Canopus only guarantees that competing `Canopus.run`/`Canopus.acquire` calls for the same `lockName` are serialized.
- No fairness guarantee in v1 — under contention, any waiting server may win the next acquisition; there is no FIFO queue (planned for v2).
- Studio testing requires **API Services** enabled (Game Settings → Security → "Enable Studio Access to API Services") since `MemoryStoreService` calls fail without it.

---

## Edge cases

| Scenario | Behavior |
|---|---|
| Holder crashes | TTL (`leaseDuration + 5s`) lapses, MemoryStore deletes the entry, next acquire succeeds. |
| Network partition | Renewal fails, `Handle` goes inactive, `onLockLost` fires. |
| Clock skew | Irrelevant — the decision authority is MemoryStore's own TTL, not the stored `expiry` field. |
| Concurrent acquire | `UpdateAsync` is atomic; exactly one caller wins, the rest see a no-op. |
| Release after lease expiry | Owner check fails, release becomes a no-op — no clobbering of the new holder. |
| Reentrant acquire (same server) | Existing entry is refreshed and a new `Handle` is returned. |
| `MemoryStoreService` unavailable | Acquisition fails with `ERR_MEMORY_STORE_UNAVAILABLE` rather than silently succeeding. |
| Corrupt stored entry | Treated as free and defensively overwritten. |

---

## Roadmap (v2+)

- `MessagingService`-based wake notifications (skip polling entirely on release)
- FIFO queue for acquisition fairness
- Fencing token enforcement at the storage layer
- Reentrant lock support with explicit nesting
- Metrics/observability hooks

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

See [LICENSE](LICENSE).

## Author

baranyerlikaya
