-- HitStreakTracker.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UpdateHitStreak = ReplicatedStorage:WaitForChild("UpdateHitStreak")

local HitStreakTracker = {}

local updateInterval = 0.15
local lastUpdate = 0
local connection
local callback

function HitStreakTracker.Start(onUpdate)
    if connection then connection:Disconnect() end

    callback = onUpdate

    connection = UpdateHitStreak.OnClientEvent:Connect(function(updatedHitstreak)
        local now = os.clock()
        if now - lastUpdate >= updateInterval then
            lastUpdate = now

            if callback then
                callback(updatedHitstreak)
            end
        end
    end)
end

function HitStreakTracker.Stop()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

return HitStreakTracker
