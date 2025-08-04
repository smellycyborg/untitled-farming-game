local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Classes = ReplicatedStorage:WaitForChild("Classes")
local Emotes = ReplicatedStorage:WaitForChild("Emotes")

local AnimationClass = require(Classes:WaitForChild("AnimationClass"))
local TypedRemote = require(Packages:WaitForChild("typed-remote"))

local PlayAnimation = TypedRemote.event("PlayAnimation", ReplicatedStorage) :: TypedRemote.Event<string>

local NOT_URL = false

local player = Players.LocalPlayer

local animations = {} 

for _, animation: Animation in Emotes:GetChildren() do
    if animation:IsA("Animation") then
        local id = animation.AnimationId
        animations[animation.Name] = AnimationClass.new(id, NOT_URL, 0, 1, 1)
    end
end


local function playAnimation(animationName: string, looped: boolean)
    local animation = animations[animationName]

    animation:play(looped)
end

local function characterAdded(character)
    for animationName, animationTrack in animations do
        task.spawn(function()
            animationTrack:setTrack(player, Enum.AnimationPriority.Action)
        end)
    end
end

if player.Character then
    characterAdded(player.Character)
else
    player.CharacterAdded:Wait()
    characterAdded(player.Character)
end

PlayAnimation.OnClientEvent:Connect(function(animationName: string)
    if animations[animationName]:isPlaying() then
        return
    end

    local shouldLoop: boolean = if string.find(animationName, "Fail") then false else true :: boolean

    for _, animationClass in animations do
        animationClass:stop()
    end
    playAnimation(animationName, shouldLoop)
end)
