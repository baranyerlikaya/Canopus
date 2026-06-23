--!strict
return function()
    local Handle = require(game:GetService("ReplicatedStorage").Packages.Canopus.Internal.Handle)

    describe("Handle", function()
        it("starts active after creation", function()
            Handle._setCallbacks(function()
                return true
            end, function()
                return true
            end)

            local handle = Handle.new("test-lock", "job-1", 1, 30)
            expect(handle:isActive()).to.equal(true)
            expect(handle:getName()).to.equal("test-lock")
            expect(handle:getVersion()).to.equal(1)
        end)

        it("becomes inactive after release", function()
            Handle._setCallbacks(function(h)
                (h :: any)._active = false
                return true
            end, function()
                return true
            end)

            local handle = Handle.new("test-lock", "job-1", 1, 30)
            local released = handle:release()

            expect(released).to.equal(true)
            expect(handle:isActive()).to.equal(false)
        end)

        it("does not invoke the release callback twice", function()
            local callCount = 0
            Handle._setCallbacks(function(h)
                callCount += 1
                (h :: any)._active = false
                return true
            end, function()
                return true
            end)

            local handle = Handle.new("test-lock", "job-1", 1, 30)
            handle:release()
            handle:release()

            expect(callCount).to.equal(1)
        end)

        it("does not invoke the renew callback once inactive", function()
            local renewCalled = false
            Handle._setCallbacks(function(h)
                (h :: any)._active = false
                return true
            end, function()
                renewCalled = true
                return true
            end)

            local handle = Handle.new("test-lock", "job-1", 1, 30)
            handle:release()
            handle:renew()

            expect(renewCalled).to.equal(false)
        end)
    end)
end
