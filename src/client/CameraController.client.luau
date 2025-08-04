local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TouchInputService = game:GetService("TouchInputService")
local UserInputService = game:GetService("UserInputService")

local Classes = ReplicatedStorage:WaitForChild("Classes")
local Packages = ReplicatedStorage:WaitForChild("Packages")




local CameraSequence = require(Classes:WaitForChild("CameraSequence"))
local TypedRemote = require(Packages:WaitForChild("typed-remote"))



local UpdateMatchFinished = TypedRemote.event("UpdateMatchFinished", ReplicatedStorage) :: TypedRemote.Event<boolean>



local NUMBER_OF_SEQUENCES: number = 2
local CAMERA_TWEEN_TIME: number = 2
local STEP: number = 1/60
local FINISH_CAMERA_TIME: number = 10

-- for camera
local HEIGHT = 5
local DISTANCE = 20
local MIN_PITCH = math.rad(-80)
local MAX_PITCH = math.rad(80)
local CAMERA_FINISH_SCENE_ID = 103314889986237

local CameraRig = ReplicatedStorage:WaitForChild("CameraRig")




local SetCamera = TypedRemote.event("SetCamera", ReplicatedStorage) :: TypedRemote.Event<string>
local UpdatePlaceFinishedPerPlayer = TypedRemote.event("UpdatePlaceFinishedPerPlayer", ReplicatedStorage) :: TypedRemote.Event<{[number]: number}>




local player: Player = Players.LocalPlayer

local PlaceFinsihedPerPlayer: {[number]: number} = {}

local matchFinished = false
local inSequence: boolean = false
local hasFinsihedStartSequence: boolean = false

-- for camera 
local dragging = false
local lastMousePosition: Vector2?
local yaw = 0
local pitch = 0

local camera: Camera
local character: Model
local connection: RBXScriptConnection

local StartSequence

local function waitForCharacter(): Model
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        return player.Character
    end

    player.CharacterAdded:Wait()
    local character: Model = player.Character :: Model
    character:WaitForChild("Humanoid")
    return character
end

local function waitForCamera(): Camera
    while not Workspace.CurrentCamera do
        RunService.PreSimulation:Wait()
    end
    return Workspace.CurrentCamera
end

character = waitForCharacter()
camera = waitForCamera()
if not camera then
    repeat
        RunService.PreRender:Wait()
        camera = waitForCamera()
    until camera
end

local CameraParts = workspace:WaitForChild("Map"):WaitForChild("CameraParts")
local StartCameraParts = CameraParts:WaitForChild("StartCameraParts")
local CameraPartsChildren = #StartCameraParts:GetChildren()

for i: number = 1, CameraPartsChildren do
    local partsFolder: Folder = StartCameraParts:WaitForChild(tostring(i)) :: Folder
    local startPart: BasePart = partsFolder:WaitForChild("Start") :: BasePart
    local endPart: BasePart = partsFolder:WaitForChild("End") :: BasePart

    if not StartSequence then
        local function onSequenceCompleted(index)
            print(`Camera Sequenced Played {index}`)
        end

        local function onSequenceFinished()
            inSequence = false
            hasFinsihedStartSequence = true
        end

        StartSequence = CameraSequence.new(CAMERA_TWEEN_TIME, startPart.CFrame, endPart.CFrame)
        StartSequence.sequenceCompleted:Connect(onSequenceCompleted)
        StartSequence.finished:Connect(onSequenceFinished)
    else
        local props: {[string]: any} = {
            tweenTime = CAMERA_TWEEN_TIME,
            startCFrame = startPart.CFrame,
            endCFrame = endPart.CFrame,
        } :: {[string]: any}
        
        StartSequence:addSequence(props)
    end
end


local function onSetCamera(sequenceType: string)
    inSequence = true

    if sequenceType == "START" then
        if StartSequence ~= nil then
            local timeElapsed = 0
            repeat
                RunService.PreSimulation:Wait()
                timeElapsed += 1/60
            until StartSequence:getLength() >= NUMBER_OF_SEQUENCES and Workspace.CurrentCamera or timeElapsed >= 10

            StartSequence:playAll()
        else
            hasFinsihedStartSequence = true
        end
    elseif sequenceType == "FINISH" then
        repeat
            RunService.PreSimulation:Wait()
        until next(PlaceFinsihedPerPlayer)

        warn(`Place Finished Per Player is now Available -> ({PlaceFinsihedPerPlayer})`)

        local timeElapsed = 0
        for userId, placeNumber in PlaceFinsihedPerPlayer do
            local plr = Players:GetPlayerByUserId(userId)
            if typeof(plr) ~= "Player" then
                continue
            end

            local human = plr:FindFirstChild("Humanoid")
            if not human then
                continue
            end

            if camera.CameraType ~= Enum.CameraType.Custom then
                camera.CameraType = Enum.CameraType.Custom
            end
            camera.CameraSubject = human

            repeat
                timeElapsed += STEP

                RunService.PreSimulation:Wait()
            until timeElapsed >= FINISH_CAMERA_TIME

            timeElapsed = 0
        end

        camera.CameraSubject = player.Character 
        and player.Character:FindFirstChild("Humanoid") 
        or workspace.CurrentCamera.CameraSubject
    end
end




SetCamera.OnClientEvent:Connect(onSetCamera)
UpdatePlaceFinishedPerPlayer.OnClientEvent:Connect(function(placeFinsihedPerPlayer)  
    PlaceFinsihedPerPlayer = placeFinsihedPerPlayer
end)




local function getSubjectPosition(): BasePart?
	local subject = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return subject
end

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		lastMousePosition = input.Position
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
		lastMousePosition = nil
	end
end)


UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		if lastMousePosition then
			local delta = input.Position - lastMousePosition
			yaw = yaw - delta.X * 0.002
			pitch = math.clamp(pitch - delta.Y * 0.002, MIN_PITCH, MAX_PITCH)
		end
		lastMousePosition = input.Position
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 and input.UserInputType ~= Enum.UserInputType.Touch then
		if input.KeyCode == Enum.KeyCode.Thumbstick2 then
			local delta = input.Position
			yaw = yaw - delta.X * 0.05
			pitch = math.clamp(pitch - delta.Y * 0.05, MIN_PITCH, MAX_PITCH)
		end
	end
end)


UpdateMatchFinished.OnClientEvent:Connect(function(a0: boolean)
    matchFinished = true
end)


RunService.RenderStepped:Connect(function()
    if not hasFinsihedStartSequence and not matchFinished then
        return
    end
    if camera.CameraType ~= Enum.CameraType.Scriptable then
        camera.CameraType = Enum.CameraType.Scriptable
    end
	local target: BasePart = getSubjectPosition() :: BasePart
	if not target then return end

	-- local rotation = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
	-- local offset = rotation:VectorToWorldSpace(Vector3.new(0, HEIGHT, DISTANCE))

	camera.CFrame = target.CFrame:ToWorldSpace(CFrame.new(-10, target.Position.Y - 5, -8) * CFrame.Angles(0, math.rad(-90), 0))
end)