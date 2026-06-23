--!strict
return function()
    local Retry = require(game:GetService("ReplicatedStorage").Packages.Canopus.Internal.Retry)

    describe("Retry", function()
        it("doubles the wait time on each attempt with no jitter", function()
            local first = Retry.nextWait(1, 1, 100, 0)
            local second = Retry.nextWait(2, 1, 100, 0)
            local third = Retry.nextWait(3, 1, 100, 0)

            expect(first).to.equal(1)
            expect(second).to.equal(2)
            expect(third).to.equal(4)
        end)

        it("never exceeds the configured cap", function()
            local result = Retry.nextWait(20, 1, 5, 0)
            expect(result).to.equal(5)
        end)

        it("applies jitter within the configured range", function()
            local result = Retry.nextWait(1, 10, 100, 0.2)
            expect(result >= 8 and result <= 12).to.equal(true)
        end)

        it("never returns a negative wait time", function()
            local result = Retry.nextWait(1, 1, 100, 1)
            expect(result >= 0).to.equal(true)
        end)
    end)
end
