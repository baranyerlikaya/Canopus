--!strict
--[[
    TestEZ runner. Place under ServerScriptService (already wired via
    default.project.json as CanopusTests) and run in Studio to execute the
    unit suite. Integration specs additionally require MemoryStoreService
    access to be enabled for the place.
]]

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
    return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TestEZ = require(ReplicatedStorage.DevPackages.TestEZ)

local testsRoot = ServerScriptService:WaitForChild("CanopusTests")

local results = TestEZ.TestBootstrap:run({ testsRoot }, TestEZ.Reporters.TextReporter)

if results.failureCount > 0 then
    error("Canopus test suite failed: " .. results.failureCount .. " failure(s)", 0)
end
