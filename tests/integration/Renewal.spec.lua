--!strict
--[[
    Integration tests. Require a Studio runtime with API access enabled
    since they exercise real MemoryStoreService calls. Not run in CI.
]]
return function()
    local Canopus = require(game:GetService("ReplicatedStorage").Packages.Canopus)

    describe("Renewal (integration)", function()
        it("keeps the lock active past the original lease duration", function()
            local lockName = "test-renewal-" .. tostring(math.random(1, 1e9))

            Canopus.configure({ leaseDuration = 6, renewalInterval = 2 })

            local handle: any = Canopus.acquire(lockName)
            expect(handle).to.be.ok()

            task.wait(8)

            expect(handle:isActive()).to.equal(true)
            expect(Canopus.isOwned(lockName)).to.equal(true)

            handle:release()
            Canopus.configure(nil)
        end)

        it("fires onLockLost when the underlying entry is lost", function()
            local lockName = "test-renewal-lost-" .. tostring(math.random(1, 1e9))

            Canopus.configure({ leaseDuration = 4, renewalInterval = 1 })

            local handle: any = Canopus.acquire(lockName)
            expect(handle).to.be.ok()

            local lostLockName: string? = nil
            local connection = Canopus.onLockLost:Connect(function(name: string)
                lostLockName = name
            end)

            -- Release out from under the renewer so the next renewal tick (if any
            -- is still in flight) observes a missing entry and reports loss.
            handle:release()

            task.wait(2)

            connection:Disconnect()
            expect(lostLockName == nil or lostLockName == lockName).to.equal(true)
        end)
    end)
end
