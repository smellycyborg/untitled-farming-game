local HttpRbxApiService = game:GetService("HttpRbxApiService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Classes = ReplicatedStorage:WaitForChild("Classes")
local Config = ReplicatedStorage:WaitForChild("Config")
local Emotes = ReplicatedStorage:WaitForChild("Emotes")

local TypedRemote = require(Packages:WaitForChild("typed-remote"))
local Signal = require(Packages:WaitForChild("signal"))
local AnimationClass = require(Classes:WaitForChild("AnimationClass"))
local EmoteIds = require(Config:WaitForChild("EmoteIds"))

local NOT_URL = false

local Animation = {}

local AnimationsPerCharacter = {}



function Animation.LoadCharacter(character: Model, uniqueKey: string)
    if not character:IsA("Model") then
        return
    end

    for _, animation: Animation in Emotes:GetChildren() do
        if animation:IsA("Animation") then
            local id = animation.AnimationId
            if not AnimationsPerCharacter[uniqueKey] then
                AnimationsPerCharacter[uniqueKey] = {}
            end

            AnimationsPerCharacter[uniqueKey][animation.Name] = AnimationClass.new(id, NOT_URL, 0, 1, 1)
        end
    end

    for animationName, animationTrack in AnimationsPerCharacter[uniqueKey] do
        task.spawn(function()
            animationTrack:setTrack(character, Enum.AnimationPriority.Action)
        end)
    end
end


Animation.PlayAnimation = Signal.new()
Animation.PlayAnimation:Connect(function(animationName: string, uniqueKey: number)
    for _, anim in AnimationsPerCharacter[uniqueKey] do
        anim:stop()
    end
    
    local animation = AnimationsPerCharacter[uniqueKey][animationName]
    animation:play(true)
end)

return Animation