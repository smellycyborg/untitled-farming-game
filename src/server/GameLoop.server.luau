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

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Classes = ReplicatedStorage:WaitForChild("Classes")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Songs = ReplicatedStorage:WaitForChild("Music")
local Boats = ReplicatedStorage:WaitForChild("Boats")
local Characters = ReplicatedStorage:WaitForChild("Characters")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local MusicBeatTimes = ReplicatedStorage:WaitForChild("MusicBeatTimes")

local Countdown = require(Classes:WaitForChild("Countdown"))
local Signals = require(Classes:WaitForChild("Signals"))
local Points = require(Classes:WaitForChild("Points"))
local AnimationModule = require(Modules:WaitForChild("Animation"))
local TypedRemote = require(Packages:WaitForChild("typed-remote"))

local CrabRaveBeats: ModuleScript = require(MusicBeatTimes.CrabRaveBeats) :: ModuleScript




local STEP_COUNT: number = 1/60
local TIMEOUT: number = 20
local START_CAMERA_TIME: number = 4
local TIME_UNTIL_RACE_START: number = 6
local ONE_SECOND: number = 1
local DEFAULT_BOAT_SPEED: number = 3
local MAX_BOAT_SPEED: number = 23
local DEFAULT_ARROW_SPEED: number = 6
local MAX_ARROW_SPEED: number = 18
local DEFAULT_SPEED_MULTIPLIER: number = 0.2
local MAX_SPEED_MULTIPLIER: number = 0.32
local TIME_TO_CHANGE_SPEED: number = 4
local BOAT_DISTANCE: number = 15
local DEFAULT_POINTS_ADD: number = 10
local DEFAULT_FINISH_DISTANCE: number = 1000
local DEFAULT_SONG_LENGTH: number = 150
local INTERMISSION_TIME: number = 23
local GAME_ID: number = 108535731334958




local SetCamera = TypedRemote.event("SetCamera", ReplicatedStorage) :: TypedRemote.Event<string>
local UpdateCountdown = TypedRemote.event("UpdateCountdown", ReplicatedStorage) :: TypedRemote.Event<number>
local PlaySound = TypedRemote.event("PlaySound", ReplicatedStorage) :: TypedRemote.Event<string>
local PlaySong = TypedRemote.event("PlaySong", ReplicatedStorage)  :: TypedRemote.Event<string>
local PressedArrow = TypedRemote.func("PressedArrow", ReplicatedStorage)
local UpdateHitStreak =TypedRemote.event("UpdateHitStreak", ReplicatedStorage) :: TypedRemote.Event<number>
local UpdateFinishDistance = TypedRemote.event("UpdateFinishDistance", ReplicatedStorage) :: TypedRemote.Event<number>
local UpdatesPointsPerUserId = TypedRemote.event("UpdatesPointsPerUserId", ReplicatedStorage) :: TypedRemote.Event<{[number]: number}>
local UpdateMatchStarted = TypedRemote.event("UpdateMatchStarted", ReplicatedStorage) :: TypedRemote.Event<boolean>
local UpdateMatchFinished = TypedRemote.event("UpdateMatchFinished", ReplicatedStorage) :: TypedRemote.Event<boolean>
local TeleportPlayer = TypedRemote.event("TeleportPlayer", ReplicatedStorage) :: TypedRemote.Event<Player>
local UpdatePlaceFinishedPerPlayer = TypedRemote.event("UpdatePlaceFinishedPerPlayer", ReplicatedStorage) :: TypedRemote.Event<{[number]: number}>
local PlayAnimation = TypedRemote.event("PlayAnimation", ReplicatedStorage) :: TypedRemote.Event<string>
local UpdateCutsceneFinished = TypedRemote.event("UpdateCutsceneFinished", ReplicatedStorage)
local SetAuraForCharacter = TypedRemote.event("SetAuraForCharacter", ReplicatedStorage)
local RegisterHit = TypedRemote.event("RegisterHit", ReplicatedStorage)




local LoadingTaskPerPlayer: {[Player]: thread} = {}
local TimeStampPerPlayer: {[Player]: number} = {}
local ArrowsPerPlayer: {[Player]: {[number]:  {[string]: string | number }}} = {}
local ArrowsToDestroy: {[string]: number} = {}
local BoatSpeedPerPlayer: {[Player]: number} = {}
local HitStreakperPlayer: {[Player]: number} = {}
local EquippedPerPlayer: {} = {}

local playersLoaded: {[Player]: boolean} = {}
local playersFinished: {[Player]: {[string]: number}} = {}

local RowerAnimations = {}

local hasTeleported = false
local playedSong = false
local readyToStart: boolean = false

local mapName: string = ""
local songName: string = nil

local beatCount = 1
local timeElapsedForMatch = 0
local playerCount: number = 0
local timeElapsed: number = 0
local timeElapsedForSpeed: number = 0
local timeToAddArrows: number = 3
local currentArrowSpeed: number = DEFAULT_ARROW_SPEED
local speedMultiplier: number = DEFAULT_SPEED_MULTIPLIER
local finishDistance: number = DEFAULT_FINISH_DISTANCE
local songLength: number = DEFAULT_SONG_LENGTH

local ArrowTypes = {
    "Right", "Left", "Down", "Up",
}

local map: Folder, centerRowPart: BasePart, centerRowPosition: Vector3
local matchTimeStamp: number, connection: RBXScriptConnection, matchFinished: boolean

local ArrowConfigurations: Folder = Instance.new("Folder", ReplicatedStorage)
ArrowConfigurations.Name = "ArrowConfigurations"
local BoatParts: Folder = Instance.new("Folder", Workspace)
BoatParts.Name = "BoatParts"

local ArrowSpeedConfig: Configuration = Instance.new("Configuration")
ArrowSpeedConfig.Name = "ArrowSpeedConfig"
ArrowSpeedConfig:SetAttribute("Speed", currentArrowSpeed)
ArrowSpeedConfig.Parent = ReplicatedStorage

local matchStartedConfig = Instance.new("Configuration")
matchStartedConfig.Name = "MatchStartConfig"
matchStartedConfig.Parent = ReplicatedStorage




local function teleportPlayersWithData(players: {Player})
	local teleportOptions = Instance.new("TeleportOptions")

	local placePerPlayer = {}
	for _, player in players do
		placePerPlayer[player.UserId] = playersFinished[player] and playersFinished[player].placeNumber or 0

        local pointsById = Points.GetPointsByUserIds()
        local points = Points.GetPoints(player)
        local place = playersFinished[player] and playersFinished[player].placeNumber or 0

        -- Debug print to verify data integrity before teleport
        print("Teleporting with data:")
        print("✅ pointsPerUserId:", pointsById)
        print("✅ placePerPlayer:", placePerPlayer)

        -- for userId, points in pointsById do
        --     warn(userId, points)
        -- end

        teleportOptions:SetTeleportData({
            placeId = game.PlaceId,
            points = points,
            placePerPlayer = place,
        })

        local success, result = pcall(function()
            return TeleportService:TeleportAsync(GAME_ID, players, teleportOptions)
        end)

        if success then
            print("✅ Teleport succeeded")
        else
            warn("❌ Teleport failed:", result)
        end
	end
end


local function createPartRow(numParts: number, distance: number, centerPosition: Vector3): {BasePart}
    numParts = math.min(numParts, 4)
    distance = math.max(distance, 1)
    
    local totalWidth = (numParts - 1) * distance
    
    local startPosition = centerPosition - Vector3.new(totalWidth/2, 0, 0)
    
    local parts = {}
    for i = 1, numParts do
        local part = Instance.new("Part")
        part.Anchored = true
        part.Color = Color3.fromRGB(95, 255, 21)
        part.CanCollide = false
        part.Size = Vector3.new(2, 1, 1)
        part.Position = startPosition + Vector3.new((i-1) * distance, 0, 0)
        part.Parent = BoatParts
        table.insert(parts, part)
    end
    
    return parts
end

local function weldCharacterToPart(character: Model, movingPart: BasePart)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then 
        hrp = character:WaitForChild("HumanoidRootPart") 
    end

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = movingPart
	weld.Parent = hrp
end

local function convertAndSortPoints(PointsPerUserId: {[number]: number}): {[number]: { points: number, placeNumber: number }}
	local sortable = {}

	for userId, points in pairs(PointsPerUserId) do
		table.insert(sortable, { userId = userId, points = points })
	end

	table.sort(sortable, function(a, b)
		return a.points > b.points
	end)

	local result = {}
	for place, data in ipairs(sortable) do
		result[data.userId] = {
			points = data.points,
			placeNumber = place
		}
	end

	return result
end





-- Register player joining and leaving the match
local function playerAdded(player: Player)
    BoatSpeedPerPlayer[player] = DEFAULT_BOAT_SPEED

    HitStreakperPlayer[player] = 0

    local joinData = not RunService:IsStudio() 
    and player:GetJoinData().TeleportData 
    or {
        playerCount = 1,
        songName = "CrabRave",
        playersData = {
            [player.UserId] = {
                equipped = { 
                    Boat = "Common", 
                    Emote = "Blazer" 
                },
            }
        }
    }

    songName = joinData.songName

    if typeof(joinData.playersData[player.UserId]) == "table" and joinData.playersData[player.UserId].equipped then
        EquippedPerPlayer[player] = joinData.playersData[player.UserId].equipped
    else
        EquippedPerPlayer[player] = { Boat = "Common", Emote = "Blazer" }
    end

    for p, v in EquippedPerPlayer[player] do
        warn(p, v)
    end

    if playerCount <= 0 then
        playerCount = joinData.playerCount
    end

    local function characterAdded(character: Model)
        LoadingTaskPerPlayer[player] = task.spawn(function()
            local rootPart = character:WaitForChild("HumanoidRootPart")

            local boatPart = BoatParts:FindFirstChild(tostring(player.UserId))
            if not boatPart then
                boatPart = BoatParts:WaitForChild(tostring(player.UserId))
            end

            rootPart.CFrame = CFrame.new(Workspace:WaitForChild(tostring(player.UserId)):WaitForChild("CharacterPlacement").Position)
            weldCharacterToPart(character, boatPart)
        end) :: thread
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

    if RunService:IsStudio() then
        print(`{player} Joined.`)
    end
end

local function playerRemoving(player: Player)
    if playersLoaded[player] then
        playersLoaded[player] = nil
    end

    if BoatSpeedPerPlayer[player] then
        BoatSpeedPerPlayer[player] = nil
    end

    if LoadingTaskPerPlayer[player] then
        task.cancel(LoadingTaskPerPlayer[player])
        LoadingTaskPerPlayer[player] = nil
    end

    for _, part in BoatParts:GetChildren() do
        if part.Name == tostring(player.UserId) then
            part:Destroy()
            break
        end
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
    warn(songName)
until playerCount >= 1 and songName ~= nil

-- set the length of the match by song length
songName = "CrabRave"
local song = Songs:FindFirstChild(songName)
local songBeatTimes

if songName == "CrabRave" then
    songBeatTimes = CrabRaveBeats
end
local songBeatsCount = 0
for _, _ in songBeatTimes do
    songBeatsCount += 1
end
if not song then

end
if song ~= nil and song:IsA("Sound") then
    if song.IsLoaded then
        print("Sound is already loaded, TimeLength:", song.TimeLength)
    else
        song.Loaded:Wait()
        print("Sound just loaded, TimeLength:", song.TimeLength)
    end
    songLength = song.TimeLength
    if songLength <= 0 then
        songLength = DEFAULT_SONG_LENGTH
    end
end
finishDistance = songLength * (MAX_BOAT_SPEED)



-- Create boat parts for map
-- if RunService:IsStudio() then
--     centerRowPosition = Vector3.new(0, 5, 0)

--     print("Player Count Recieved.")
-- else
    -- map = ReplicatedStorage:FindFirstChild(mapName) :: Folder
    centerRowPart = Workspace:WaitForChild("Map"):WaitForChild("CenterRowPart") :: BasePart
    centerRowPosition = centerRowPart.Position :: Vector3
-- end
createPartRow(playerCount, BOAT_DISTANCE, centerRowPosition)




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

if RunService:IsStudio() then
    print("All players have loaded in.")
end

-- Set boat owner per player user id
for _, player in Players:GetPlayers() do
    for _, part in BoatParts:GetChildren() do
        if part:GetAttribute("OwnerId") then
            continue
        else
            part:SetAttribute("OwnerId", player.UserId)
            part.Name = tostring(player.UserId)

            local equipped = EquippedPerPlayer[player]
            if typeof(equipped) == "table" then
                if typeof(equipped.Boat) == "string" then
                    local boatClone = Boats:FindFirstChild(equipped.Boat) and Boats:FindFirstChild(equipped.Boat):Clone()
                    boatClone.Name = tostring(player.UserId)
                    local function WeldParts(part, base)
                        local weld = Instance.new("WeldConstraint")
                        weld.Part0 = part
                        weld.Part1 = base
                        weld.Parent = part
                    end

                    boatClone:FindFirstChild("Anchor").Anchored = false 
                    WeldParts(part, boatClone:FindFirstChild("Anchor"))

                    if boatClone:GetAttribute("TierTwo") then
                        rotationOffset = CFrame.fromEulerAnglesXYZ(math.rad(90), math.rad(0), math.rad(-90))
                        
                        boatClone:PivotTo(part.CFrame * rotationOffset)
                    end

                    for _, part in boatClone:GetChildren() do
                        if part:IsA("BasePart") then
                            if part.Name == "CharacterPlacement" or part.Name == "Anchor" or part.Name == "RowerPart" then
                                part.Transparency = 1
                            end
                            if part.Name == "RowerPart" then
                                local rowerClone = Characters:FindFirstChild("Rower"):Clone()
                                local rootPart = rowerClone:FindFirstChild("HumanoidRootPart")
                                WeldParts(part, rootPart)

                                rotationOffset = CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(90), math.rad(0))

                                rowerClone:PivotTo(part.CFrame * rotationOffset)
                                rowerClone.Parent = workspace

                                local emotes = {"RightRower", "LeftRower"}
                                local randomEmote = emotes[math.random(1, 2)]

                                local uniqueKey = HttpService:GenerateGUID()
                                AnimationModule.LoadCharacter(rowerClone, uniqueKey)
                                AnimationModule.PlayAnimation:Fire(randomEmote, uniqueKey)
                            end
                        end
                    end
                    boatClone.Parent = workspace
                    break
                end
            end
        end
    end
end

local function getXFromElapsed(timeElapsed: number, speedMultiplier: number): number
    local startX = -0.5
    local endX = 1.5
    local distance = endX - startX

    local baseSpeed = 1
    local travelTime = distance / (baseSpeed * speedMultiplier)

    local progress = math.clamp(timeElapsed / travelTime, 0, 1)
    local currentX = startX + (distance * progress)

    return currentX
end


local function getCurrentPos(timeStamp: number)
    local startingPos = -30
    local goalPos = 30
    local totalDistance = math.abs(goalPos - startingPos)
    local totalTime = totalDistance / currentArrowSpeed

    local timeSoFar = os.clock() - timeStamp
    local t = timeSoFar / totalTime

    return startingPos + (goalPos - startingPos) * t
end

local PlayersHaveAura = {}
local function onPressedArrow(player: Player, currentX)
    -- local arrowData = ArrowsPerPlayer[player]
    -- if typeof(arrowData) ~= "table" or #arrowData <= 0 then
    --         warn("Invalid arrowData")
    --     return
    -- end

    -- local firstArrowData = arrowData[1]
    -- if typeof(firstArrowData) ~= "table" then
    --         warn("Invalid firstArrowData")
    --     return
    -- end

    local success: boolean = nil

    -- local uniqueKey: string = firstArrowData.key
    -- local timeStamp: number = firstArrowData.timeStamp

    -- if not HitStreakperPlayer[player] then
    --     HitStreakperPlayer[player] = 0
    -- end

    -- local currentPos = getXFromElapsed(os.clock() - timeStamp, speedMultiplier)

    local soundName = if not success then "Fail" else "Success"
    if currentX <= 0.675 and currentX >= 0.575 then
        success = true

        HitStreakperPlayer[player] += 1

        Points.Add(player, DEFAULT_POINTS_ADD)

        PlayAnimation:FireClient(player, EquippedPerPlayer[player] and EquippedPerPlayer[player].Emote or "Blazer")
        PlaySound:FireClient(player, soundName)
    else
        success = false

        HitStreakperPlayer[player] = 0

        local failStrings = {"RightFail", "LeftFail"}
        local randomFail = failStrings[math.random(1, 2)]

        PlayAnimation:FireClient(player, randomFail)
        PlaySound:FireClient(player, soundName)
    end

    -- if not success then
    --     HitStreakperPlayer[player] = 0
    -- end

    -- if not success and currentPos > 0.71
    -- or not success and currentPos < 0.59 then
    --     success = false

        
    -- elseif success == true then
    --     -- table.remove(ArrowsPerPlayer[player], 1)
    -- end

    UpdateHitStreak:FireClient(player, HitStreakperPlayer[player])

    if HitStreakperPlayer[player] >= 10 and player.Character and not PlayersHaveAura[player] then
        PlayersHaveAura[player] = true
        SetAuraForCharacter:FireAllClients(player.Character, true)
    elseif PlayersHaveAura[player] and HitStreakperPlayer[player] <= 0 then
        PlayersHaveAura[player] = nil
        SetAuraForCharacter:FireAllClients(player.Character, false)
    end


    print(`{player} Pressed {success}`)

    -- return success, uniqueKey
end

local matchCountdown
local function countdownTask(secondsLeft)
    local countdownTimeLeft: number = secondsLeft :: number
    UpdateCountdown:FireAllClients(countdownTimeLeft)
    PlaySound:FireAllClients("CountdownPing")

    -- print("MatchCountdown:  Countdown Time Left -> ", countdownTimeLeft)
end

local matchStarted
local function onCountdownEnded()
    UpdateCountdown:FireAllClients(0)
    matchStarted = true
    PlaySound:FireAllClients("StartMatch")
    if not songName then
        songName = "Balance"
    end
    matchStartedConfig:SetAttribute("Started", true)
end

-- Start match
if readyToStart then
    if RunService:IsStudio() then
        print("Match starting..")
    end

    SetCamera:FireAllClients("START")

    repeat
        RunService.PostSimulation:Wait()

        timeElapsed += STEP_COUNT
    until timeElapsed >= START_CAMERA_TIME
    timeElapsed = 0

    matchTimeStamp = os.clock()
    matchCountdown = Countdown.new(TIME_UNTIL_RACE_START)

    -- matchCountdown:adTadsk(ONE_SECOND, countdownTask)
    matchCountdown.tick:Connect(function(secondsLeft)
        countdownTask(secondsLeft)
    end)
    matchCountdown.finished:Connect(onCountdownEnded)
    matchCountdown:start()

    UpdateFinishDistance:FireAllClients(finishDistance)
    UpdateCountdown:FireAllClients(TIME_UNTIL_RACE_START)
    PlaySound:FireAllClients("CountdownPing")

    local function startPlayer(player: Player)
        ArrowsPerPlayer[player] = {}
        TimeStampPerPlayer[player] = os.clock()
    end

    for _, player: Player in Players:GetPlayers() do
        task.spawn(startPlayer, player)
    end
else

end

PressedArrow.OnServerInvoke = onPressedArrow

TeleportPlayer.OnServerEvent:Connect(function(player)
    teleportPlayersWithData({player})
end)

RegisterHit.OnServerEvent:Connect(function(player: Player, currentX: any)
    local success: boolean
    if currentX >= 0.575 and currentX <= 0.675 then
        success = true
    elseif currentX <= 0.574 and currentX >= 0.56 
    or currentX >= 0.676 and currentX <= 0.7 then
        success = false
    end

    local soundName = if not success then "Fail" else "Success"
    if success then
        HitStreakperPlayer[player] += 1

        Points.Add(player, DEFAULT_POINTS_ADD)

        PlayAnimation:FireClient(player, EquippedPerPlayer[player] and EquippedPerPlayer[player].Emote or "Blazer")
        PlaySound:FireClient(player, soundName)
    else
        HitStreakperPlayer[player] = 0

        local failStrings = {"RightFail", "LeftFail"}
        local randomFail = failStrings[math.random(1, 2)]

        PlayAnimation:FireClient(player, randomFail)
        PlaySound:FireClient(player, soundName)
    end

    UpdateHitStreak:FireClient(player, HitStreakperPlayer[player])

    if HitStreakperPlayer[player] >= 10 and player.Character and not PlayersHaveAura[player] then
        PlayersHaveAura[player] = true
        SetAuraForCharacter:FireAllClients(player.Character, true)
    elseif PlayersHaveAura[player] and HitStreakperPlayer[player] <= 0 then
        PlayersHaveAura[player] = nil
        SetAuraForCharacter:FireAllClients(player.Character, false)
    end
end)

RunService.PostSimulation:Connect(function(step)
    if not matchStarted then
        return
    end
    local function addArrowConfig(player: Player)
        local randomArrowType: number = ArrowTypes[math.random(1, #ArrowTypes)] :: number
        local uniqueKey: string = HttpService:GenerateGUID() :: string

        local arrowConfig: Configuration = Instance.new("Configuration") :: Configuration
        arrowConfig.Name = uniqueKey

        local auraPowers = {"Mild", "Medium", "Strong", "Max"}
        local randomAuraPower = auraPowers[math.random(1, #auraPowers)]

        arrowConfig:SetAttribute("OwnerId", player.UserId)
        arrowConfig:SetAttribute("ArrowType", randomArrowType)
        arrowConfig:SetAttribute("AuraPower", randomAuraPower)

        table.insert(ArrowsPerPlayer[player], {
            key = uniqueKey,
            timeStamp = os.clock(), 
            arrowType = randomArrowType,
        })
        ArrowsToDestroy[uniqueKey] = os.clock()

        arrowConfig.Parent = ArrowConfigurations
    end

    local function moveBoatPart(userId: number, part: BasePart, step: number)
        local function calculateBoatSpeed(hitStreak: number, minSpeed: number, maxSpeed: number): number
            if hitStreak <= 0 then
                return minSpeed
            end

            -- Define how quickly speed approaches maxSpeed.
            -- Example: speed approaches maxSpeed as hitStreak increases.
            -- Using a curve that slows down growth: e.g., speed = minSpeed + (maxSpeed - minSpeed) * (1 - exp(-k * hitStreak))

            local k = 0.2  -- tweak this constant to control how fast speed rises with hitStreak

            local speedRange = maxSpeed - minSpeed
            local speedIncrease = speedRange * (1 - math.exp(-k * hitStreak))

            local speed = minSpeed + speedIncrease

            -- Clamp just in case
            if speed > maxSpeed then
                speed = maxSpeed
            end

            return speed
        end

        local player = Players:GetPlayerByUserId(userId)

        local hitStreak = HitStreakperPlayer[player]
        BoatSpeedPerPlayer[player] = calculateBoatSpeed(hitStreak or 0, DEFAULT_BOAT_SPEED, MAX_BOAT_SPEED)

        local playerSpeed = BoatSpeedPerPlayer[player]

        local forwardDirection = Vector3.new(0, 0, -1)
        local newPosition = part.Position + (forwardDirection * step * playerSpeed)

        part.CFrame = CFrame.new(newPosition)
    end

    -- Multiplies arrow speed
    local function applyRandomMultiplier(value: number): number
        local multiplier = math.random() * 0.08 + 1.002
        return math.clamp(value * multiplier, DEFAULT_SPEED_MULTIPLIER, MAX_SPEED_MULTIPLIER)
    end

    local function getSpeedScaledRandom(speed: number): number
        local minSpeed, maxSpeed = 0.2, 1.1
        local clampedSpeed = math.clamp(speed, minSpeed, maxSpeed)
        
        local normalized = (clampedSpeed - minSpeed) / (maxSpeed - minSpeed)

        -- At speed 9 → interval range: 0.5s to 1s (random in this range)
        -- At speed 18 → interval range: 0.05s to 0.25s (random in this range)
        
        local minIntervalAtMinSpeed = 0.5
        local maxIntervalAtMinSpeed = 1.2
        
        local minIntervalAtMaxSpeed = 0.2
        local maxIntervalAtMaxSpeed = 0.3
        
        -- Interpolate min and max intervals linearly based on normalized speed
        local minInterval = minIntervalAtMinSpeed + (minIntervalAtMaxSpeed - minIntervalAtMinSpeed) * normalized
        local maxInterval = maxIntervalAtMinSpeed + (maxIntervalAtMaxSpeed - maxIntervalAtMinSpeed) * normalized
        
        return math.random() * (maxInterval - minInterval) + minInterval
    end

    timeElapsedForSpeed += step
    timeElapsed += step
    timeElapsedForMatch += step

    
    if timeElapsedForMatch >= songLength and not matchFinished then
        timeElapsed = 0

        matchFinished = true

        local placePerPlayer = {}
        for userId, data in playersFinished do
            placePerPlayer[userId] = data.placeNumber
        end

        UpdatePlaceFinishedPerPlayer:FireAllClients(placePerPlayer)
        UpdatesPointsPerUserId:FireAllClients(convertAndSortPoints(Points.GetPointsByUserIds()))
        UpdateMatchFinished:FireAllClients(true)
        SetCamera:FireAllClients("FINISH")
        

        return
    elseif matchFinished then
        if timeElapsed >= INTERMISSION_TIME and not hasTeleported then
            hasTeleported = true

            for _, player in Players:GetPlayers() do
                teleportPlayersWithData({player})
            end
        end
        return 
    end

    if timeElapsedForSpeed >= TIME_TO_CHANGE_SPEED then
        timeElapsedForSpeed = 0

        speedMultiplier = applyRandomMultiplier(speedMultiplier)
        ArrowSpeedConfig:SetAttribute("Speed", speedMultiplier)
    end
    
    if timeElapsedForMatch >= 0 and not playedSong then
        playedSong = true
        PlaySong:FireAllClients(songName)
    end

    -- if beatCount <= #songBeatTimes then
    --     if timeElapsedForMatch >= songBeatTimes[beatCount] then
    --         beatCount+=1

    --         timeToAddArrows = getSpeedScaledRandom(speedMultiplier)

    --         for _, player: Player in Players:GetChildren() do
    --             addArrowConfig(player)
    --         end
    --     end
    -- end


    -- Render Arrow As Fail
    -- for player, arrows in ArrowsPerPlayer do
    --     for index, arrowData in arrows do

    --         local currentPos = getXFromElapsed(os.clock() - arrowData.timeStamp, speedMultiplier)
    --         if currentPos >= 0.7 then
    --             table.remove(ArrowsPerPlayer[player], index)

    --             local uniqueKey = arrowData.key
    --             if typeof(uniqueKey) ~= "string" then
    --                 continue 
    --             end
    --             local arrowConfig = ArrowConfigurations:FindFirstChild(uniqueKey)
    --             if not arrowConfig then
    --                 continue
    --             end
                
    --             arrowConfig:SetAttribute("PressedState", "Fail")

    --             PlaySound:FireClient(player, "Fail")
    --             local failStrings = {"RightFail", "LeftFail"}
    --             local randomFail = failStrings[math.random(1, 2)]
    --             PlayAnimation:FireClient(player, randomFail)
                
    --             HitStreakperPlayer[player] = 0
    --             UpdateHitStreak:FireClient(player, HitStreakperPlayer[player])
    --         end
    --     end
    -- end

    -- -- Destroy Arrow Configs
    -- for uniqueKey, timeStamp in ArrowsToDestroy do
    --     local currentPos = getXFromElapsed(os.clock() - timeStamp, speedMultiplier)
    --     if currentPos >= 1.5 then
    --         local foundArrowConfig = ArrowConfigurations:FindFirstChild(uniqueKey)
    --         if foundArrowConfig then
    --             foundArrowConfig:Destroy()
    --         end
    --     end
    -- end

    -- Move Boat Parts
    for _, part in BoatParts:GetChildren() do
        local userId = tonumber(part.Name)
        local zValue = part.Position.Z

        if zValue >= finishDistance and not playersFinished[userId] then
            local place = 1
            for _, _ in playersFinished do
                place+=1
            end

            playersFinished[userId] = {
                timeFinsished = os.clock() - matchTimeStamp,
                place = place,
            }
        end

        moveBoatPart(userId, part, step)
    end
end)
