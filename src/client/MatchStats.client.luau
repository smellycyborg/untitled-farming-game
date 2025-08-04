local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Components = ReplicatedStorage:WaitForChild("Components")

local TypedRemote = require(Packages:WaitForChild("typed-remote"))
local React = require(Packages:WaitForChild("react"))
local ReactRoblox = require(Packages:WaitForChild("react-roblox"))
local ReactSpring = require(Packages:WaitForChild("react-spring"))
local PlayerStatComponent = require(Components:WaitForChild("PlayerStatComponent"))



local UpdateFinishDistance = TypedRemote.event("UpdateFinishDistance", ReplicatedStorage) :: TypedRemote.Event<number>
local UpdatesPointsPerUserId = TypedRemote.event("UpdatesPointsPerUserId", ReplicatedStorage)
local UpdateMatchFinished = TypedRemote.event("UpdateMatchFinished", ReplicatedStorage) :: TypedRemote.Event<boolean>
local TeleportPlayer = TypedRemote.event("TeleportPlayer", ReplicatedStorage)




local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")




local FONT_ID: number = 12187368625
local DEFAULT_FINISH_DISTANCE: number = 1000




local PointsPerUserId: {[number]: {[string]: number}} = {}
local PlacePerPlayer: {[number]: number} = {}

local finishDistance: number = DEFAULT_FINISH_DISTANCE

local matchFinished: boolean = false




local ScreenGui: ScreenGui = Instance.new("ScreenGui", playerGui) :: ScreenGui
ScreenGui.Name = "Countdown"
ScreenGui.ResetOnSpawn = false

local Font = Font.fromId(FONT_ID, Enum.FontWeight.Bold, Enum.FontStyle.Italic)




local function getPlaceString(place: number): string
	local suffixes = {
		[1] = "st",
		[2] = "nd",
		[3] = "rd"
	}

	-- Handle special cases like 11th, 12th, 13th
	if place % 100 >= 11 and place % 100 <= 13 then
		return tostring(place) .. "th"
	end

	local suffix = suffixes[place % 10] or "th"
	return tostring(place) .. suffix
end

local function addCommasToNumber(n: number): string
	local str = tostring(math.floor(n))
	return str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function statsComponent(props: {[string]: any})
    local pointsPerUserId, setPointsPerUserId = React.useState({})
    local placePerPlayer, setPlacePerPlayer = React.useState({})
    local finishDistance, setFinishDistance = React.useState(1)
    local matchFinished, setMatchFinished = React.useState(false)

    local placeComponents = {}
    local pointsComponents = {}

    React.useEffect(function()
        local conn = UpdatesPointsPerUserId.OnClientEvent:Connect(function(data)
            setPointsPerUserId(data)
        end)
        return function()
            conn:Disconnect()
        end
    end, {})

    React.useEffect(function()
        local conn = UpdateFinishDistance.OnClientEvent:Connect(function(value)
            setFinishDistance(value)
        end)
        return function()
            conn:Disconnect()
        end
    end, {})

    React.useEffect(function()
        local conn = UpdateMatchFinished.OnClientEvent:Connect(function(state)
            setMatchFinished(state)
        end)
        return function()
            conn:Disconnect()
        end
    end, {})

    local lastPlaces = {}

    React.useEffect(function()
        local lastUpdate = 0

        local conn = RunService.Heartbeat:Connect(function()
            local now = os.clock()
            if now - lastUpdate < 0.2 then return end
            lastUpdate = now

            local BoatParts = workspace:FindFirstChild("BoatParts")
            if not BoatParts then return end
            if typeof(finishDistance) ~= "number" or finishDistance <= 0 then return end

            local distances = {}
            for _, boatPart in BoatParts:GetChildren() do
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

            -- Check if places actually changed
            local changed = false
            for k, v in pairs(newPlaces) do
                if lastPlaces[k] ~= v then
                    changed = true
                    break
                end
            end
            if not changed then
                for k in pairs(lastPlaces) do
                    if newPlaces[k] == nil then
                        changed = true
                        break
                    end
                end
            end

            if changed then
                lastPlaces = newPlaces

                -- Wait for next frame to safely update React state
                task.defer(function()
                    setPlacePerPlayer(newPlaces)
                end)
            end
        end)

        return function()
            if conn then
                conn:Disconnect()
                conn = nil
            end
        end
    end, { finishDistance })


    for userId, placeNumber in placePerPlayer do
        local plr = Players:GetPlayerByUserId(userId)
        if plr then
            table.insert(placeComponents, React.createElement(PlayerStatComponent, {
                displayName = plr.DisplayName,
                userId = userId,
                placeNumber = placeNumber,
                statText = getPlaceString(placeNumber),
            }))
        end
    end

    for userId, data in pointsPerUserId do
        if typeof(data) == "table" then
            local plr = Players:GetPlayerByUserId(userId)
            if plr then
                table.insert(pointsComponents, React.createElement(PlayerStatComponent, {
                    displayName = plr.DisplayName,
                    userId = userId,
                    placeNumber = data.placeNumber,
                    statText = addCommasToNumber(data.points),
                }))
            end
        end
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Active = false,
    }, {
        BottomLeftHolder = React.createElement("Frame", {
            Size = UDim2.fromScale(0.2, 0.3),
            Position = UDim2.fromScale(0, 0.6),
            BackgroundTransparency = 1,
        }, {
            PlacesBackground = React.createElement("Frame", {
                Visible = false,

                Size = UDim2.fromScale(0.9, 0.9),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.3,
            }, {
                UICorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0.05, 0),
                }),
                
                ListHolder = React.createElement("Frame", {
                    Size = UDim2.fromScale(0.9, 0.9),
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                }, {
                    UIListLayout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Vertical,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }),
                }, placeComponents)
            }),

            TeleportBackHolder = React.createElement("Frame", {
                Size = UDim2.fromScale(0.9, 0.9),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                BackgroundTransparency = 1,
            }, {
                UICorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0.05, 0),
                }),
                
                TeleportButton = React.createElement("TextButton", {
                    Visible = matchFinished,

                    Text = "<- Back>",
                    BackgroundColor3 = Color3.fromRGB(255, 108, 108),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(0.8, 0.5),
                    BackgroundTransparency = 0,
                    TextScaled = true,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    FontFace = Font,
                    [React.Event.Activated] = function()
                        if RunService:IsStudio() then
                            print("Clicking teleport back button.")
                        end

                        TeleportPlayer:FireServer()
                    end,
                }, {
                    UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
                        MaxTextSize = 30,
                    }),
                    UICorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0.2, 0),
                    }),
                    UIStroke = React.createElement("UIStroke", {
                        Thickness = 2,
                        Color = Color3.fromRGB(255, 255, 255),
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }),
                    OtherStroke = React.createElement("UIStroke", {
                        Thickness = 2,
                        Color = Color3.fromRGB(0, 0, 0),
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                    }),
                })
            })
        }),

        StatsHolder = React.createElement("Frame", {
            Visible = matchFinished,
            Active = false,
            Selectable = false,
            
            Size = UDim2.fromScale(0.5, 0.6),
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
        }, {
            Background = React.createElement("Frame", {
                Size = UDim2.fromScale(0.75, 0.9),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.3,
            }, {
                UIListLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
                UICorner = React.createElement("UICorner", {
                    CornerRadius = UDim.new(0.02, 0),
                }),
                UIStroke = React.createElement("UIStroke", {
                    Thickness = 2,
                    Color = Color3.fromRGB(255, 255, 255),
                }),

                TopBar = React.createElement("Frame", {
                    LayoutOrder = 1,
                    Size = UDim2.fromScale(0.9, 0.1),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                    BackgroundTransparency = 1
                }, {
                    UIListLayout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }),

                    PointsLabelHolder = React.createElement("Frame", {
                        LayoutOrder = 3,
                        Size = UDim2.fromScale(0.46, 0.92),
                        BackgroundTransparency = 1,
                    }, {
                        PointsLabel = React.createElement("TextLabel", {
                            Size = UDim2.fromScale(1, 1),
                            BackgroundTransparency = 1,

                            Text = "Points",
                            TextScaled = true,
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            FontFace = Font,
                        })
                    }),

                    FillerMiddle = React.createElement("Frame", {
                        LayoutOrder = 2,
                        Size = UDim2.fromScale(0.05, 1),
                        BackgroundTransparency = 1,
                    }),

                    PlacesLabelHolder = React.createElement("Frame", {
                        LayoutOrder = 1,
                        Size = UDim2.fromScale(0.46, 1),
                        BackgroundTransparency = 1,
                    }, {
                        PlacesLabel = React.createElement("TextLabel", {
                            Size = UDim2.fromScale(1, 0.92),
                            BackgroundTransparency = 1,

                            Text = "Places",
                            TextScaled = true,
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            FontFace = Font,
                        })
                    })
                }),

                ListFrameHolder = React.createElement("Frame", {
                    LayoutOrder = 2,
                    Size = UDim2.fromScale(0.9, 0.8),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                    BackgroundTransparency = 1
                }, {
                    UIListLayout = React.createElement("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }),

                    PointsHolder = React.createElement("Frame", {
                        LayoutOrder = 3,
                        Size = UDim2.fromScale(0.48, 0.93),
                        BackgroundTransparency = 1,
                    }, {
                        UIStroke = React.createElement("UIStroke", {
                            Thickness = 1,
                            Color = Color3.fromRGB(255, 255, 255),
                        }),
                        UICorner = React.createElement("UICorner", {
                            CornerRadius = UDim.new(0.02, 0),
                        }),
                        UIListLayout = React.createElement("UIListLayout", {
                            FillDirection = Enum.FillDirection.Vertical,
                            VerticalAlignment = Enum.VerticalAlignment.Top,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Padding = UDim.new(0.1, 0),
                        }),
                    }, pointsComponents),

                    FillerMiddle = React.createElement("Frame", {
                        LayoutOrder = 2,
                        Size = UDim2.fromScale(0.05, 0.92),
                        BackgroundTransparency = 1,
                    }),

                    PlacesHolder = React.createElement("Frame", {
                        LayoutOrder = 1,
                        Size = UDim2.fromScale(0.48, 0.93),
                        BackgroundTransparency = 1,
                    }, {
                        UIStroke = React.createElement("UIStroke", {
                            Thickness = 1,
                            Color = Color3.fromRGB(255, 255, 255),
                        }),
                        UICorner = React.createElement("UICorner", {
                            CornerRadius = UDim.new(0.02, 0),
                        }),
                        UIListLayout = React.createElement("UIListLayout", {
                            FillDirection = Enum.FillDirection.Vertical,
                            VerticalAlignment = Enum.VerticalAlignment.Top,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Padding = UDim.new(0.1, 0),
                        }),
                    }, placeComponents)
                })
            })
        }),
    })
end




local root = ReactRoblox.createRoot(ScreenGui)
-- root:render(React.createElement(statsComponent, {}))

root:render(
    React.createElement(React.StrictMode, nil, 
        React.createElement(statsComponent, {})
    )
)