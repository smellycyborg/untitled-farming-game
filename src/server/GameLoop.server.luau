--[[

    -  Make sure players are loaded in -> :CharacterAppearanceLoaded() -> :GetTeleportSetting()
    -  Camera Sequence cut scene
    -  Countdown until start (7 seconds)
    -  Players interact with keys to win 
    -  Players finish
    -  Camera Sequence cut scene finishing scene
    -  Match stats and rewards
    -  Leave button, teleport back to lobby after (? seconds)

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Classes = ReplicatedStorage:WaitForChild("Classes")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Countdown = require(Classes:WaitForChild("Countdown"))
local TypedRemote = require(Packages:WaitForChild("typed-remote"))

local STEP_COUNT = 1/60
local TIMEOUT = 20
local START_CAMERA_TIME = 10
local TIME_UNTIL_RACE_START = 7
local ONE_SECOND = 1

local SetCamera = TypedRemote.event("SetCamera", ReplicatedStorage)
local UpdateCountdown = TypedRemote.event("UpdateCountdown", ReplicatedStorage)

local LoadingTaskPerPlayer = {}
local TimeStampPerPlayer = {}
local ArrowsPerPlayer = {}

local playersLoaded = {}
local playersFinished = {}

local readyToStart = false

local playerCount = 0
local timeElapsed = 0



-- Register player joining and leaving the match
local function playerAdded(player: Player)
    local function characterAdded(character: Model)
        LoadingTaskPerPlayer[player] = task.spawn(function()
            local rootPart = character:WaitForChild("HumanoidRootPart")

            rootPart:PivotTo(CFrame.new(Vector3.zero)) -- TODO:  get the player's boat
        end)
    end

    local function characterAppearanceLoaded(character: Model)
        if not playersLoaded[player] or playersLoaded[player] ~= true then
            playersLoaded[player] = true
        end
    end

    if player.Character then
        characterAdded(player.Character)
    end
    player.CharacterAdded:Connect(characterAdded)
    player.CharacterAppearanceLoaded:Connect(characterAppearanceLoaded)

    if player:HasAppearanceLoaded() and not playersLoaded[player] then
		playersLoaded[player] = true
	end
end

local function playerRemoving(player: Player)
    if playersLoaded[player] then
        playersLoaded[player] = nil
    end

    if LoadingTaskPerPlayer[player] then
        task.cancel(LoadingTaskPerPlayer[player])
        LoadingTaskPerPlayer[player] = nil
    end

    playerCount = math.max(0, playerCount - 1)
    if playerCount <= 0 and readyToStart == false then
        for _, player: Player in Players:GetPlayers() do
            -- Todo teleport player back to the start place
        end
    end
end

for _, player: Player in Players:GetPlayers() do
    task.spawn(playerAdded, player)
end
Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)



-- Get player count for current match
repeat
    RunService.PostSimulation:Wait()
until TeleportService:GetTeleportSetting("PlayerCount") ~= nil
playerCount = TeleportService:GetTeleportSetting("PlayerCount")



-- Wait until all players are loaded in and match is ready to start
repeat
    RunService.PostSimulation:Wait()

    timeElapsed += STEP_COUNT

    local loadedCount = 0
    for player, hasLoaded in playersLoaded do
        if hasLoaded == true then
            loadedCount += 1
        end
    end
    if loadedCount >= playerCount then
        readyToStart = true
    end
until readyToStart == true or timeElapsed >= TIMEOUT
timeElapsed = 0



-- Start match
if readyToStart then
    SetCamera:FireAllClients("START")

    repeat
        RunService.PostSimulation:Wait()

        timeElapsed += STEP_COUNT
    until timeElapsed >= START_CAMERA_TIME

    local matchCountdown = Countdown.new(TIME_UNTIL_RACE_START)

    local function countdownTask()
        local countdownTimeLeft = matchCountdown:getSecondsLeft()
        UpdateCountdown:FireAllClients(countdownTimeLeft)

        if RunService:IsStudio() then
            print("MatchCountdown:  Countdown Time Left -> ", countdownTimeLeft)
        end
    end

    local function onCountdownEnded()
        local function onPostSimulation(step: number)
            
        end

        for _, player: Player in Players:GetPlayers() do
            local function startPlayer()
                ArrowsPerPlayer[player] = {}
                TimeStampPerPlayer[player] = os.time()
            end
            task.spawn(startPlayer)
        end

        RunService.PostSimulation:Connect(onPostSimulation)
    end
    
    matchCountdown:addTask(ONE_SECOND, countdownTask)
    matchCountdown.finished:Connect(onCountdownEnded)
    matchCountdown:start()

    UpdateCountdown:FireAllClients(TIME_UNTIL_RACE_START)
else

end
