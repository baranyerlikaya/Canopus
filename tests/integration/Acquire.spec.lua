--!strict
--[[
    Integration tests. Require a Studio runtime with API access enabled
    (Game Settings > Security > Enable Studio Access to API Services) since
    they exercise real MemoryStoreService calls. Not run in CI.
]]
return function()
    local Canopus = require(game:GetService("ReplicatedStorage").Packages.Canopus)

    -- MemoryStoreService is eventually consistent: a read immediately after a
    -- write can briefly observe the old value. Poll instead of asserting once.
    local function waitUntil(
        predicate: () -> boolean,
        attempts: number?,
        interval: number?
    ): boolean
        for _ = 1, attempts or 10 do
            if predicate() then
                return true
            end
            task.wait(interval or 0.2)
        end
        return predicate()
    end

    describe("Acquire (integration)", function()
        it("acquires an uncontended lock immediately", function()
            local lockName = "test-acquire-" .. tostring(math.random(1, 1e9))
            local handle: any = Canopus.tryAcquire(lockName)

            expect(handle).to.be.ok()
            expect(handle:isActive()).to.equal(true)

            handle:release()
        end)

        it("refreshes the lock on repeated acquisition from the same server", function()
            local lockName = "test-acquire-refresh-" .. tostring(math.random(1, 1e9))
            local first: any = Canopus.tryAcquire(lockName)
            expect(first).to.be.ok()

            local second: any = Canopus.tryAcquire(lockName)
            expect(second).to.be.ok()
            expect(second:getVersion() > first:getVersion()).to.equal(true)

            second:release()
        end)

        it("reports the holding server as the owner while the lock is active", function()
            local lockName = "test-acquire-owner-" .. tostring(math.random(1, 1e9))

            local handle: any = Canopus.tryAcquire(lockName)
            expect(handle).to.be.ok()

            expect(Canopus.getOwner(lockName)).to.equal(game.JobId)
            expect(Canopus.isOwned(lockName)).to.equal(true)

            handle:release()
        end)

        it("allows acquisition again after the lock is released", function()
            local lockName = "test-acquire-release-" .. tostring(math.random(1, 1e9))

            local handle: any = Canopus.tryAcquire(lockName)
            expect(handle).to.be.ok()
            handle:release()

            expect(waitUntil(function()
                return not Canopus.isOwned(lockName)
            end)).to.equal(true)

            -- tryAcquire makes a single attempt by design; use acquire here so
            -- a one-off transient MemoryStoreService error doesn't flake this
            -- assertion the way a single-shot call would.
            local second: any = Canopus.acquire(lockName, { timeout = 5 })
            expect(second).to.be.ok()
            second:release()
        end)
    end)
end
