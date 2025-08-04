
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Signal = require(Packages:WaitForChild("signal"))

return {
    PlayAnimation = Signal.new(),
}