local ReplicatedStorage = game:GetService("ReplicatedStorage")




local Packages = ReplicatedStorage:WaitForChild("Packages")
local Sounds = ReplicatedStorage:WaitForChild("Sounds")
local Songs = ReplicatedStorage:WaitForChild("Music")




local TypedRemote = require(Packages:WaitForChild("typed-remote"))

local PlaySound = TypedRemote.event("PlaySound", ReplicatedStorage) :: TypedRemote.Event<string>




PlaySound.OnClientEvent:Connect(function(soundName)
    local sound = Sounds:FindFirstChild(soundName)
    if sound then
        sound:Play()
    end
end)
