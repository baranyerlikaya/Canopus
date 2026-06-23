--!strict
return function()
    local LockEntry =
        require(game:GetService("ReplicatedStorage").Packages.Canopus.Internal.LockEntry)

    describe("LockEntry", function()
        it("round-trips through encode and decode", function()
            local entry = LockEntry.new("job-1", 100, 1, 50)
            local encoded = LockEntry.encode(entry)
            local decoded = LockEntry.decode(encoded)

            expect(decoded).to.be.ok()
            expect((decoded :: any).owner).to.equal("job-1")
            expect((decoded :: any).expiry).to.equal(100)
            expect((decoded :: any).version).to.equal(1)
            expect((decoded :: any).acquired).to.equal(50)
        end)

        it("returns nil for invalid input", function()
            expect(LockEntry.decode("not valid json")).to.equal(nil)
            expect(LockEntry.decode(nil)).to.equal(nil)
            expect(LockEntry.decode("42")).to.equal(nil)
        end)

        it("identifies expired entries correctly", function()
            local entry = LockEntry.new("job-1", 100, 1, 50)
            expect(LockEntry.isExpired(entry, 50)).to.equal(false)
            expect(LockEntry.isExpired(entry, 150)).to.equal(true)
        end)

        it("identifies ownership correctly", function()
            local entry = LockEntry.new("job-1", 100, 1, 50)
            expect(LockEntry.isOwnedBy(entry, "job-1")).to.equal(true)
            expect(LockEntry.isOwnedBy(entry, "job-2")).to.equal(false)
        end)

        it("bumps version without mutating the original entry", function()
            local entry = LockEntry.new("job-1", 100, 1, 50)
            local bumped = LockEntry.bumpVersion(entry)
            expect(bumped.version).to.equal(2)
            expect(entry.version).to.equal(1)
        end)

        it("refreshes expiry while preserving version and owner", function()
            local entry = LockEntry.new("job-1", 100, 3, 50)
            local refreshed = LockEntry.refresh(entry, 200, 30)
            expect(refreshed.expiry).to.equal(230)
            expect(refreshed.version).to.equal(3)
            expect(refreshed.owner).to.equal("job-1")
        end)
    end)
end
