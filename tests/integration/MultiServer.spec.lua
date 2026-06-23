--!strict
--[[
    Simulates contention between multiple Roblox servers inside a single
    Studio session. `game.JobId` is constant within one Studio process, so
    instead of relying on Studio's multi-server local test feature, these
    tests drive Internal.Acquirer directly with distinct fake ownerIds.
    This exercises the real atomic UpdateAsync/LockEntry logic against a
    real MemoryStore -- only the JobId origin is faked. Requires Studio
    Access to API Services. Not run in CI.
]]
return function()
    local Acquirer =
        require(game:GetService("ReplicatedStorage").Packages.Canopus.Internal.Acquirer)

    -- MemoryStoreService is eventually consistent: a read/acquire immediately
    -- after a release can briefly still observe the old entry. Poll instead
    -- of asserting once.
    local function waitUntilHandle(getHandle: () -> any, attempts: number?, interval: number?): any
        for _ = 1, attempts or 10 do
            local handle = getHandle()
            if handle ~= nil then
                return handle
            end
            task.wait(interval or 0.2)
        end
        return getHandle()
    end

    describe("Multi-server contention (simulated)", function()
        it("only lets one of two contending servers win the lock", function()
            local lockName = "test-multiserver-" .. tostring(math.random(1, 1e9))

            local handleA: any = Acquirer.tryAcquire(lockName, "server-A")
            local handleB: any = Acquirer.tryAcquire(lockName, "server-B")

            expect(handleA).to.be.ok()
            expect(handleB).to.equal(nil)

            handleA:release()
        end)

        it("lets the second server take over once the first releases", function()
            local lockName = "test-multiserver-takeover-" .. tostring(math.random(1, 1e9))

            local handleA: any = Acquirer.tryAcquire(lockName, "server-A")
            expect(handleA).to.be.ok()

            local blockedB: any = Acquirer.tryAcquire(lockName, "server-B")
            expect(blockedB).to.equal(nil)

            handleA:release()

            local handleB: any = waitUntilHandle(function()
                return Acquirer.tryAcquire(lockName, "server-B")
            end)
            expect(handleB).to.be.ok()
            expect(Acquirer.getOwner(lockName)).to.equal("server-B")

            handleB:release()
        end)

        it("lets the second server take over once the first server's lease expires", function()
            local lockName = "test-multiserver-expiry-" .. tostring(math.random(1, 1e9))

            local handleA: any, errA = Acquirer.acquire(lockName, { leaseDuration = 2 }, "server-A")
            expect(handleA).to.be.ok()
            expect(errA).to.equal(nil)

            -- Stop server-A's renewer so the lease is left to expire naturally,
            -- without releasing the entry (simulates a crashed server).
            handleA._active = false

            task.wait(8)

            local handleB: any = Acquirer.tryAcquire(lockName, "server-B")
            expect(handleB).to.be.ok()
            expect(Acquirer.getOwner(lockName)).to.equal("server-B")

            handleB:release()
        end)

        it("does not let a contended server bump the version of the winning entry", function()
            local lockName = "test-multiserver-version-" .. tostring(math.random(1, 1e9))

            local handleA: any = Acquirer.tryAcquire(lockName, "server-A")
            expect(handleA).to.be.ok()
            local versionAfterA = handleA:getVersion()

            local handleB: any = Acquirer.tryAcquire(lockName, "server-B")
            expect(handleB).to.equal(nil)

            expect(Acquirer.getOwner(lockName)).to.equal("server-A")

            -- server-A re-acquiring (refresh) is the only thing allowed to bump
            -- the version while server-A still owns the lock.
            local refreshed: any = Acquirer.tryAcquire(lockName, "server-A")
            expect(refreshed).to.be.ok()
            expect(refreshed:getVersion() > versionAfterA).to.equal(true)

            refreshed:release()
        end)
    end)
end
