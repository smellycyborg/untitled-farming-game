local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local TypedPromise = require(Packages:WaitForChild("typed-remote"))

local UpdatePoints = TypedPromise.event("UpdatePoints", ReplicatedStorage) :: TypedPromise.Event<number, number>

local Points = {}
local PointsPerPlayer: {[Player]: number} = {}




function Points.Add(player: Player, amount: number): (number?, number?)
    if not RunService:IsServer() then
        return
    end

    local prevPoints: number, updatedPoints: number

    if not PointsPerPlayer[player] then
        PointsPerPlayer[player] = 0
    end

    prevPoints = PointsPerPlayer[player]

    PointsPerPlayer[player] += amount

    updatedPoints = PointsPerPlayer[player]

    UpdatePoints:FireClient(player, prevPoints, updatedPoints)

    if RunService:IsStudio() then
        -- print(`Points: {amount} added for {player}`)
    end

    return prevPoints, updatedPoints
end

function Points.GetPointsByUserIds()
    local pointsPerUserId: {[number]: number} = {}
    for player: Player, points: number in PointsPerPlayer do
        pointsPerUserId[player.UserId] = points
    end
    return pointsPerUserId
end

function Points.GetPoints(player)
    return PointsPerPlayer[player] or 0
end



Points.ClientObserver = UpdatePoints




return Points