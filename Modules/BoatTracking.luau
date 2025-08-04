local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local BoatPlaceTracker = {}

BoatPlaceTracker._connections = {}
BoatPlaceTracker._listeners = {}
BoatPlaceTracker.lastPlaces = {}

function BoatPlaceTracker.StartTracking(finishDistance: number)
    BoatPlaceTracker.StopTracking()

    local lastUpdate = 0
    BoatPlaceTracker._connections["Heartbeat"] = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - lastUpdate < 0.2 then 
            return 
        end
        lastUpdate = now

        local BoatParts = workspace:FindFirstChild("BoatParts")
        if not BoatParts then 
            return 
        end
        if typeof(finishDistance) ~= "number" or finishDistance <= 0 then 
            return 
        end

        local distances = {}
        for _, boatPart in ipairs(BoatParts:GetChildren()) do
            local userId = tonumber(boatPart.Name)
            if not userId then continue end

            local plr = Players:GetPlayerByUserId(userId)
            if not plr then continue end

            local distance = math.abs(boatPart.Position.Z) / finishDistance
            table.insert(distances, { userId = userId, distance = distance })
        end

        table.sort(distances, function(a, b)
            return a.distance > b.distance
        end)

        local newPlaces = {}
        for i, entry in ipairs(distances) do
            newPlaces[entry.userId] = i
        end

        -- Compare to avoid unnecessary updates
        local changed = false
        for k, v in pairs(newPlaces) do
            if BoatPlaceTracker.lastPlaces[k] ~= v then
                changed = true
                break
            end
        end
        if not changed then
            for k in pairs(BoatPlaceTracker.lastPlaces) do
                if newPlaces[k] == nil then
                    changed = true
                    break
                end
            end
        end

        if changed then
            BoatPlaceTracker.lastPlaces = newPlaces
            for _, listener in ipairs(BoatPlaceTracker._listeners) do
                listener(newPlaces)
            end
        end
    end)
end

function BoatPlaceTracker.OnUpdate(callback: (places: { [number]: number }) -> ())
    table.insert(BoatPlaceTracker._listeners, callback)
end

function BoatPlaceTracker.StopTracking()
    for _, conn in pairs(BoatPlaceTracker._connections) do
        conn:Disconnect()
    end
    BoatPlaceTracker._connections = {}
    BoatPlaceTracker._listeners = {}
    BoatPlaceTracker.lastPlaces = {}
end

return BoatPlaceTracker
