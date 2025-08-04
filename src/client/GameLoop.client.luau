local HttpRbxApiService = game:GetService("HttpRbxApiService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Classes: Folder = ReplicatedStorage:WaitForChild("Classes")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Arrows: Folder = ReplicatedStorage:WaitForChild("Arrows") :: Folder
local Auras: Folder = ReplicatedStorage:WaitForChild("Auras") :: Folder
local Songs = ReplicatedStorage:WaitForChild("Music")
local MusicBeatTimes = ReplicatedStorage:WaitForChild("MusicBeatTimes")

local SetWeldAura = require(ReplicatedStorage.Modules.SetWeldAura)
local Keybind = require(Classes:WaitForChild("Keybind"))
local TypedRemote = require(Packages:WaitForChild("typed-remote"))
local React = require(Packages:WaitForChild("react"))
local ReactRoblox = require(Packages:WaitForChild("react-roblox"))
local ReactSpring = require(Packages:WaitForChild("react-spring"))

local CrabRaveBeats: ModuleScript = require(MusicBeatTimes:WaitForChild("CrabRaveBeats")) :: ModuleScript

local ArrowConfigurations: Folder = ReplicatedStorage:WaitForChild("ArrowConfigurations")
local ArrowSpeedConfig: Configuration = ReplicatedStorage:WaitForChild("ArrowSpeedConfig")

local SetAuraForCharacter = TypedRemote.event("SetAuraForCharacter", ReplicatedStorage)
local PlaySong = TypedRemote.event("PlaySong", ReplicatedStorage) :: TypedRemote.Event<string>
local RegisterHit = TypedRemote.event("RegisterHit", ReplicatedStorage)




local NUMBER_OF_HIGHLIGHTS: number = 23
local DEFAULT_SPEED: number = 6
local STARTING_X: number = -0.5
local DEFAULT_COLOR_TWEEN_TIME: number = 0.25
local FONT_ID: number = 12187368625

local ARROW_IMAGE_ID = "rbxassetid://132568505991185"
local BLUE_CIRCLE_ID = "rbxassetid://106347331049878"
local GREEN_CIRCLE_ID = "rbxassetid://116177294350301"
local ORANGE_CIRCLE_ID = "rbxassetid://74742031666735"
local PINK_CIRCLE_ID = "rbxassetid://133451482602747"





local ArrowModelsClient: Folder = Instance.new("Folder", Workspace) :: Folder
ArrowModelsClient.Name = "ArrowModelsClient"
local Highlights: Folder = Instance.new("Folder", ReplicatedStorage)
Highlights.Name = "Highlights"
local WorkspaceHighlights: Folder = Instance.new("Folder", Workspace)
WorkspaceHighlights.Name = "WorkspaceHighlights"




local PressedArrow = TypedRemote.func("PressedArrow", ReplicatedStorage)




local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerModule = require(playerScripts:WaitForChild("PlayerModule") :: ModuleScript)
local controls = playerModule:GetControls()
controls:Disable()

local timeStampPerArrow: {[string]: number} = {}
local actions: {[string]: any} = {}
local xOffsets: {[string]: number} = {}
local successHits = {}
local failedHits = {}
local ArrowsForPlayer = {}
local currentXPerArrow = {}

local arrowStyle: string = "Default"

local arrowSpeed: number = DEFAULT_SPEED :: number
local speedMultiplier = 0.2
local timeElapsed = 0
local timeElapsedForSong = 0
local beatCount = 1
local startX = -0.5
local endX = 1.5
local distance = endX - startX

local baseSpeed = 1


local turnedOffJump: boolean = false
local Enabled: boolean = false

local song: Sound
local songBeatTimes


local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ArrowTypes = {
    "Right", "Left", "Down", "Up",
}
local GamepadArrows = {
    Right = "ButtonR2",
    Left = "ButtonL2",
    Up = "Y",
    Down = "A",
}

local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.fromRGB(255, 105, 105)
highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
highlight.OutlineTransparency = 1
highlight.FillTransparency = 1
highlight.Parent = player.Character or player.CharacterAdded:Wait()


local arrowGui = Instance.new("ScreenGui", playerGui)
arrowGui.Name = "ArrowGui"
arrowGui.ResetOnSpawn = false

local arrowHolder = Instance.new("Frame", arrowGui)
arrowHolder.Size = UDim2.fromScale(1, 1)
arrowHolder.BackgroundTransparency = 1

local circle = Instance.new("ImageLabel")
circle.Name = "Circle"
circle.Visible = false
circle.Image = "rbxassetid://114349349637556"
circle.BackgroundTransparency = 1
circle.ImageTransparency = 0.3
-- circle.ImageColor3 = Color3.fromRGB(255, 247, 221)
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.fromScale(0.625, 0.425)
circle.Size = UDim2.fromScale(0.075, 0.15)
circle.ScaleType = Enum.ScaleType.Fit
circle.ZIndex = -1
circle.Parent = arrowHolder

local successFrame = Instance.new("TextLabel")
successFrame.Name = "Circle"
successFrame.BackgroundTransparency = 1
successFrame.AnchorPoint = Vector2.new(0.5, 0.5)
successFrame.Position = UDim2.fromScale(0.5, 0.225)
successFrame.Size = UDim2.fromScale(0.15, 0.15)
successFrame.Text = "Ready?!"
successFrame.TextColor3 = Color3.fromRGB(255, 196, 0)
successFrame.TextStrokeTransparency = 0.3
successFrame.ZIndex = -1
successFrame.TextScaled = true
successFrame.Visible = false
successFrame.Parent = arrowHolder

local textSizeConstraint = Instance.new("UITextSizeConstraint")
textSizeConstraint.MaxTextSize = 23
textSizeConstraint.Parent = successFrame

local uiScale = Instance.new("UIScale")
uiScale.Parent = successFrame

local ScreenGui: ScreenGui = Instance.new("ScreenGui", playerGui) :: ScreenGui
ScreenGui.Name = "ArrowBut"
ScreenGui.ResetOnSpawn = false

local Font = Font.fromId(FONT_ID, Enum.FontWeight.Bold, Enum.FontStyle.Italic)

successFrame.FontFace = Font



local tweenPerElement = {}
local function tweenElement(
    instance: Instance, 
    property: string, 
    target: any,
    start: any,

    duration: number, 
    easingStyle: Enum.EasingStyle?, 
    easingDirection: Enum.EasingDirection?,

    reverse: boolean?

)

	local tweenInfo = TweenInfo.new(
		duration,
		easingStyle or Enum.EasingStyle.Quad,
		easingDirection or Enum.EasingDirection.Out,
        0,
        reverse
	)

	local goal = {}
	goal[property] = target

    if tweenPerElement[instance] then
        tweenPerElement[instance].tween:Cancel()
        if tweenPerElement[instance].completedTask then
            tweenPerElement[instance].completedTask:Disconnect()
        end
        instance[property] = start
    end

	tweenPerElement[instance] = {tween = TweenService:Create(instance, tweenInfo, goal) }
    tweenPerElement[instance].completedTask = tweenPerElement[instance].tween.Completed:Connect(function(a0: Enum.PlaybackState)  
        tweenPerElement[instance] = nil
    end)
	tweenPerElement[instance].tween:Play()

	return tweenPerElement[instance]
end




local function onSpeedChanged()
    speedMultiplier = ArrowSpeedConfig:GetAttribute("Speed") :: number
end

local function createArrow()
    local arrowClone = Instance.new("ImageLabel")

    local colors = {Color3.fromRGB(78, 75, 255), Color3.fromRGB(255, 75, 240)}
    local randomColor = colors[math.random(1, #colors)]
    local images = {"rbxassetid://75713384389852", "rbxassetid://76692481584561"}
    local imagesWithStroke = {"rbxassetid://113065829849723", "rbxassetid://110682150648923"}
    local randomImage = imagesWithStroke[math.random(1, #imagesWithStroke)]

    local auras = {"Mild", "Medium", "Strong", "Max"}
    local auraPower = auras[math.random(1, #auras)]

    local uniqueKey = HttpService:GenerateGUID()

    local imageId = PINK_CIRCLE_ID
    if auraPower == "Medium" then
        imageId = ORANGE_CIRCLE_ID
    elseif auraPower == "Strong" then
        imageId = BLUE_CIRCLE_ID
    elseif auraPower == "Max" then
        imageId = GREEN_CIRCLE_ID
    end

    arrowClone.Name = uniqueKey
    arrowClone.Image = imageId
    arrowClone.BackgroundTransparency = 1
    arrowClone.AnchorPoint = Vector2.new(0.5, 0.5)
    arrowClone.Position = UDim2.fromScale(-0.5, -1)
    arrowClone.Size = UDim2.fromScale(0.1, 0.1)
    arrowClone.ScaleType = Enum.ScaleType.Fit

    local uiScale = Instance.new("UIScale")
    uiScale.Name = "UIScale"
    uiScale.Parent = arrowClone

    table.insert(ArrowsForPlayer, uniqueKey)

    arrowClone.Parent = arrowHolder

    xOffsets[uniqueKey] = STARTING_X
end

local function onPreRender(step: number)
    local character = player.Character
    if not character then
        return
    end

    if not turnedOffJump then
        turnedOffJump = true

        local humanoid = character:WaitForChild("Humanoid")

        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	    humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end

    if not song then 
        return
    end

    timeElapsedForSong += step

    if songBeatTimes and beatCount > #songBeatTimes then
        return
    elseif not songBeatTimes then
        return warn("Song beat times is nil.")
    end

    if timeElapsedForSong >= songBeatTimes[beatCount] then
        beatCount += 1
        createArrow()
    end

    for _, imageLabel in arrowHolder:GetChildren() do
        local key = imageLabel.Name
        if key == "Circle" then
            continue
        end
        if successFrame.Visible == false then
            successFrame.Visible = true
        end
        if circle.Visible == false then
            circle.Visible = true
        end
        local arrowDirection: string = imageLabel:GetAttribute("ArrowDirection") :: string

        if xOffsets[key] == nil then
            xOffsets[key] = 0 
        end

        local stepSize = (baseSpeed * speedMultiplier) / distance

        local progress = xOffsets[key]
        progress = math.clamp(progress + stepSize * step, 0, 1)
        xOffsets[key] = progress

        local currentX = startX + (distance * progress)
        if successHits[key] and currentX >= 0.625 then
            currentX = 0.625
        elseif not successHits[key] and not failedHits[key] then
            if currentX >= 0.68 then
                failedHits[key] = true
                table.remove(ArrowsForPlayer, 1)

                tweenElement(highlight, "FillTransparency", 0.6, 1, DEFAULT_COLOR_TWEEN_TIME * 1.3, Enum.EasingStyle.Linear, 
                    Enum.EasingDirection.InOut, true)

                tweenElement(Workspace.CurrentCamera, "FieldOfView", 65, 70, DEFAULT_COLOR_TWEEN_TIME * 1.3, Enum.EasingStyle.Linear, 
                    Enum.EasingDirection.InOut, true)

                RegisterHit:FireServer(currentX)
            end
        end

        currentXPerArrow[key] = currentX
        
        imageLabel.Position = UDim2.fromScale(currentX, 0.425)

        if arrowDirection == "Right" then
            imageLabel.Rotation = 0
        elseif arrowDirection == "Left" then
            imageLabel.Rotation = 180
        elseif arrowDirection == "Up" then
            imageLabel.Rotation = -90
        elseif arrowDirection == "Down" then
            imageLabel.Rotation = 90
        end
    end
end

local function onInputChanged()
    local inputType = UserInputService.PreferredInput
    if inputType == Enum.UserInputType.Touch then
        arrowStyle = "Mobile"

        if RunService:IsStudio() then
            print("Player is on **mobile** 📱")
        end
    elseif inputType == Enum.UserInputType.Keyboard then
        arrowStyle = "Default"

        if RunService:IsStudio() then
            print("Player is on **PC** ⌨️")
        end
    elseif inputType == Enum.UserInputType.Gamepad1 then
        arrowStyle = "Gamepad"

        if RunService:IsStudio() then
            print("Player is on **console/controller** 🎮")
        end
    else
        arrowStyle = "Default"

        if RunService:IsStudio() then
            print("Unknown input type:", inputType.Name)
        end
    end
end

local function onPressed()
    tweenElement(
        circle, 
        "Size", 
        UDim2.fromScale(0.19, 0.19),
        UDim2.fromScale(0.15, 0.15),
        DEFAULT_COLOR_TWEEN_TIME / 2, 
        Enum.EasingStyle.Linear, 
        Enum.EasingDirection.InOut,
        true
    )

    local firstArrowData = ArrowsForPlayer[1]
    if typeof(firstArrowData) ~= "string" then
            warn("Invalid firstArrowData")
        return
    end

    local key = firstArrowData
    local currentX = currentXPerArrow[key]
    if currentX >= 0.575 and currentX <= 0.675 and not successHits[key] then
        successHits[key] = true

        table.remove(ArrowsForPlayer, 1)

        local imageLabel = arrowHolder:FindFirstChild(key)
        tweenElement(
            imageLabel:FindFirstChild("UIScale"), 
            "Scale", 
            0.2,
            0,
            DEFAULT_COLOR_TWEEN_TIME / 1.3, 
            Enum.EasingStyle.Linear, 
            Enum.EasingDirection.InOut,
            true
        )

        task.delay(DEFAULT_COLOR_TWEEN_TIME, function()
            imageLabel:Destroy()
        end)
        RegisterHit:FireServer(currentX)
    elseif table.find(ArrowsForPlayer, key) and not failedHits[key] then
        if currentX <= 0.574 and currentX >= 0.56 
        or currentX >= 0.676 and currentX <= 0.7 then
            failedHits[key] = true

            table.remove(ArrowsForPlayer, 1)
            tweenElement(highlight, "FillTransparency", 0.6, 1, DEFAULT_COLOR_TWEEN_TIME * 1.3, Enum.EasingStyle.Linear, 
                Enum.EasingDirection.InOut, true)

            tweenElement(Workspace.CurrentCamera, "FieldOfView", 65, 70, DEFAULT_COLOR_TWEEN_TIME * 1.3, Enum.EasingStyle.Linear, 
                Enum.EasingDirection.InOut, true)

            RegisterHit:FireServer(currentX)
        end
    end
end




local function arrowsComponent(props)
    local arrows = {}
    for _, arrowType in ArrowTypes do
        local rotation = 0
        local layoutOrder = 0
        if arrowType == "Right" then
            layoutOrder = 4
            rotation = 0
        elseif arrowType == "Left" then
            rotation = 180
            layoutOrder = 1
        elseif arrowType == "Up" then
            rotation = -90
            layoutOrder = 2
        elseif arrowType == "Down" then
            rotation = 90
            layoutOrder = 3
        end
        arrows[#arrows+1] = React.createElement("Frame", {
            LayoutOrder = layoutOrder,
            BackgroundTransparency = 0.3,
            BackgroundColor3 = Color3.fromRGB(),
        }, {
            UICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(1, 0),
            }),

            ImageLabel = React.createElement("ImageLabel", {
                Size = UDim2.fromScale(0.6, 0.6),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Image = ARROW_IMAGE_ID,
                Rotation = rotation,
                BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
            }),

            ImageButton = React.createElement("ImageButton", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,

                [React.Event.Activated] = function()
                    onPressed()
                end
            })
        })
    end

    return React.createElement("Frame", {
        Visible = false,

        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    }, {
        Holder = React.createElement("Frame", {
            Size = UDim2.fromScale(0.6, 0.15),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.8),
            AnchorPoint = Vector2.new(0.5, 0),
        }, {
            UIGridLayout = React.createElement("UIGridLayout", {
                CellSize = UDim2.fromScale(0.15, 0.9),
                CellPadding = UDim2.fromScale(0.04, 0.02),
                SortOrder = Enum.SortOrder.LayoutOrder, 
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
            })
        }, arrows)
    })
end

local root = ReactRoblox.createLegacyRoot(ScreenGui)


local function updateRoot(enabled: boolean)
    root:render(React.createElement(arrowsComponent, {
        enabled = enabled,
    }))
end
updateRoot(Enabled)


task.spawn(function()
    while true do
        local success, err = pcall(function()
            game:GetService("StarterGui"):SetCore("ResetButtonCallback", false)
        end)

        if success then
            break
        end

        RunService.PreSimulation:Wait()
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
    onPressed()
end)

UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
    local function isMobile()
        return UserInputService.PreferredInput == Enum.PreferredInput.Touch
    end
    Enabled = isMobile()
    updateRoot(Enabled)
end)

PlaySong.OnClientEvent:Connect(function(songName)
    local distance = 0.5 + 0.625
    local timeNeeded = distance / (baseSpeed * speedMultiplier) + (2.017 / 1.5)
    
        songBeatTimes = CrabRaveBeats
    
    warn("Should be playing song.", songName)
    song = Songs:FindFirstChild(songName)
    if song then
        task.delay(timeNeeded, function()
            song:Play()
        end)
    end
end)

SetAuraForCharacter.OnClientEvent:Connect(function(character: any, shouldActivate: boolean)
    local aura
    local auraType = character:GetAttribute("AuraType")
    if typeof(auraType) == "string" then
        aura = Auras:FindFirstChild(character:GetAttribute("AuraType"))
    else
        aura = Auras:FindFirstChild("Air")
    end
    
    if aura and shouldActivate then
        SetWeldAura(character, aura:Clone())
    elseif not shouldActivate then
        for _, part in character:GetChildren() do
            if string.find(part.Name, "aura") then
                part:Destroy()
            end
        end
    end
end)

ArrowSpeedConfig:GetAttributeChangedSignal("Speed"):Connect(onSpeedChanged)
RunService.PreRender:Connect(onPreRender)
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(onInputChanged)