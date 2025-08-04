local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Classes = ReplicatedStorage:WaitForChild("Classes")
local Config = ReplicatedStorage:WaitForChild("Config")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Points = require(Classes:WaitForChild("Points"))
local GifImages = require(Classes:WaitForChild("GifImages"))
local OrangeElectricImages = require(Config:WaitForChild("OrangeElectricImages"))
local React = require(Packages:WaitForChild("react"))
local ReactRoblox = require(Packages:WaitForChild("react-roblox"))
local ReactSpring = require(Packages:WaitForChild("react-spring"))
local TypedRemote = require(Packages:WaitForChild("typed-remote"))




local UpdateHitStreak = TypedRemote.event("UpdateHitStreak", ReplicatedStorage) :: TypedRemote.Event<number>
local UpdateFinishDistance = TypedRemote.event("UpdateFinishDistance", ReplicatedStorage) :: TypedRemote.Event<number>




local FONT_ID: number = 12187368625
local DEFAULT_FINISH_DISTANCE: number = 1000
local START_Z: number = 0
local MAX_HITSTREAK: number = 23




local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")




local prevPoints: number = 0
local currentPoints: number = 0
local currentHitStreak: number = 0
local finishDistance: number = DEFAULT_FINISH_DISTANCE

local points = 0
local playerHeadshots = {}





local ScreenGui: ScreenGui = Instance.new("ScreenGui", playerGui) :: ScreenGui
ScreenGui.Name = "Points"
ScreenGui.ResetOnSpawn = false

local Font = Font.fromId(FONT_ID, Enum.FontWeight.Bold, Enum.FontStyle.Italic)




local function getPlayerHeadshot(UserID: number): string
	local success, result = pcall(function()
		return Players:GetUserThumbnailAsync(UserID, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)

	if success then
		return result --, warn(result)
	else
		return "rbxassetid://753015086" --, warn("unsuccesful getting player image.")
	end
end

local function statsComponent(props)
    local pointsState, setPointsState = React.useState({prev = 0, fake = 0})
    local hitStreak, setHistreak = React.useState({hits = 0, streak = 0})
    local points, setPoints = React.useState(0)
    local placePerPlayer, setPlacePerPlayer = React.useState({})

    local prevPoints, fakePoints = pointsState.prev, pointsState.fake

    local lastStreakUpdate = 0
    local lastUpdateTime = 0
    local updateInterval = 0.15

    local playerHeadshots = {}

    local streakBarX = math.clamp(hitStreak.streak / MAX_HITSTREAK, 0, 1)
    local placeString = "None"

    local styles, api = ReactSpring.useSpring(function()
        return {
            pointsSize = 1,
            streakSize = 1,
            config = { tension = 180, friction = 12 },
        }
    end)

    local playerProgress = React.useMemo(function()
        local map = {}
        for _, plr in Players:GetPlayers() do
            local binding, setBinding = React.createBinding(0)
            map[plr.UserId] = { value = binding, set = setBinding }
        end
        return map
    end, {})

    React.useEffect(function()
        local connection = Points.ClientObserver.OnClientEvent:Connect(function(prevPoints, updatedPoints)
            setPointsState({prev = prevPoints, fake = updatedPoints})
        end)

        return function()
            connection:Disconnect()
        end
    end, {})

    React.useEffect(function()
        local connection = UpdateHitStreak.OnClientEvent:Connect(function(updatedHitstreak)
            local now = os.clock()
            if now - lastStreakUpdate >= updateInterval then
                lastStreakUpdate = now

                setHistreak(function(prevState)
                    local newHits = prevState.hits
                    if updatedHitstreak > 0 then
                        newHits = newHits + 1
                    end

                    return {
                        streak = updatedHitstreak,
                        hits = newHits,
                    }
                end)
            end
        end)

        return function()
            connection:Disconnect()
        end
    end, {})

    React.useEffect(function()
        local cancelled = false
        local currentPoints = prevPoints

        local conn = RunService.Heartbeat:Connect(function()
            if cancelled then return end

            if currentPoints < fakePoints then
                currentPoints += 1
                setPoints(currentPoints)
            elseif currentPoints > fakePoints then
                currentPoints -= 1
                setPoints(currentPoints)
            end
        end)

        -- Trigger animation only once per change
        api.start({
            pointsSize = 1.1,
            from = { pointsSize = 1 },
            config = { tension = 180, friction = 12 },
        })

        return function()
            cancelled = true
            conn:Disconnect()
        end
    end, { fakePoints })

    React.useEffect(function()
        task.spawn(function()
            task.wait(0.5)
            api.start({
                streakSize = 1.1,
                from = { streakSize = 1 },
                config = { tension = 180, friction = 12 },
            })
        end)
    end, { hitStreak })

    -- Boat position tracker
   React.useEffect(function()
    local running = true
    local lastUpdateTime = 0
    local updateInterval = 0.2 -- Set your desired interval here
    local isRendering = false

    task.spawn(function()
        while running do
            local now = os.clock()
            if now - lastUpdateTime < updateInterval then
                task.wait(updateInterval - (now - lastUpdateTime))
                continue
            end
            lastUpdateTime = now

            local boatParts = workspace:FindFirstChild("BoatParts")
            if boatParts then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if not finishDistance then
                        continue
                    end

                    local progress = playerProgress[plr.UserId]
                    if not progress then
                        continue
                    end

                    local plrBoat = boatParts:FindFirstChild(tostring(plr.UserId))
                    if not plrBoat then
                        continue
                    end

                    local z = math.abs(plrBoat.Position.Z)
                    local range = finishDistance - START_Z
                    local x = (range ~= 0) and math.clamp((z - START_Z) / range, 0, 1) or 0

                    local currentValue = progress.value:getValue()
                    if math.abs(currentValue - x) > 0.01 then
                        if not isRendering then
                            isRendering = true
                            progress.set(x)
                            -- Defer unlocking rendering so React can finish updating
                            task.defer(function()
                                isRendering = false
                            end)
                        end
                    end
                end
            end
        end
    end)

    return function()
        running = false
    end
end, {})


   React.useEffect(function()
        local lastUpdate = 0
        local conn
        local lastPlaces = {}

        local function shallowEqual(a, b)
            for k, v in pairs(a) do
                if b[k] ~= v then
                    return false
                end
            end
            for k in pairs(b) do
                if a[k] == nil then
                    return false
                end
            end
            return true
        end

        conn = RunService.Heartbeat:Connect(function()
            local now = os.clock()
            if now - lastUpdate < 0.2 then return end
            lastUpdate = now

            local BoatParts = workspace:FindFirstChild("BoatParts")
            if not BoatParts then return end
            if typeof(finishDistance) ~= "number" or finishDistance <= 0 then return end

            local distances = {}
            for _, boatPart in ipairs(BoatParts:GetChildren()) do
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

            local places = {}
            for i, entry in ipairs(distances) do
                places[entry.userId] = i
            end

            if not shallowEqual(lastPlaces, places) then
                lastPlaces = places
                setPlacePerPlayer(places)
            end
        end)

        return function()
            if conn then
                conn:Disconnect()
                conn = nil
            end
        end
    end, { finishDistance })


    if placePerPlayer[player.UserId] then
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

        placeString = getPlaceString(placePerPlayer[player.UserId])
    end


    for _, plr in Players:GetPlayers() do
        local progress = playerProgress[plr.UserId]
        if progress then
            playerHeadshots[#playerHeadshots+1] = React.createElement("Frame", {
                Size = UDim2.fromScale(0.075, 1),
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = progress.value:map(function(x)
                    return UDim2.fromScale(x, 0.5)
                end),
                ClipsDescendants = true,
            }, {
                UIScale = React.createElement("UIScale", {
                    Scale = 1.5,
                }),

                ImageLabel = React.createElement("ImageLabel", {
                    BackgroundTransparency = 1,
                    Image = getPlayerHeadshot(plr.UserId),
                    Size = UDim2.fromScale(1, 1),
                    ScaleType = Enum.ScaleType.Fit,
                }, {
                    UICorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(1, 0),
                    }),
                })
            })
        end
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Active = false,
        Selectable = false,
    }, {
        BottomLeftHolder = React.createElement("Frame", {
            Size = UDim2.fromScale(0.2, 0.3),
            Position = UDim2.fromScale(0, 0.6),
            BackgroundTransparency = 1,
        }, {
            PlayerStatsHolder = React.createElement("Frame", {
                Visible = true,

                Size = UDim2.fromScale(0.9, 0.9),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 1,
            }, {
                UIListLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                }),

                PointsHolder = React.createElement("Frame", {
                    Size = UDim2.fromScale(1, 0.2),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.fromScale(0, 0.5),
                    BackgroundTransparency = 1,
                    LayoutOrder = 2,
                }, {
                    PointsLabel = React.createElement("TextLabel", {
                        Text = `<font color="#80BFE0"><i>Points:</i></font>   <font color="#FFFFFF">{points}</font>`,

                        Size = UDim2.fromScale(1, 1),
                        AnchorPoint = Vector2.new(0, 0),
                        Position = UDim2.fromScale(0, 0.05),

                        TextXAlignment = Enum.TextXAlignment.Left,
                        BackgroundTransparency = 1,
                        TextScaled = true,
                        RichText = true,
                        FontFace = Font,
                    }, {
                        UIScale = React.createElement("UIScale", {
                            Scale = styles.pointsSize,
                        }),
                        UIStroke = React.createElement("UIStroke", {
                            Thickness = 2,
                        }),

                        UIGradient = React.createElement("UIGradient", {
                            Rotation = 90,
                            Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 200, 200)),
                                ColorSequenceKeypoint.new(0.8, Color3.fromRGB(50, 156, 255)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 95, 180)),
                            }),
                        })
                    })
                }),

                PlaceHolder = React.createElement("Frame", {
                    Size = UDim2.fromScale(1, 0.2),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.fromScale(0, 0.5),
                    BackgroundTransparency = 1,
                    LayoutOrder = 2,
                }, {
                    PlaceLabel = React.createElement("TextLabel", {
                        Text = `<font color="#FFD700"><i>Place:</i></font>   <font color="#FFFFFF">{placeString}</font>`,

                        Size = UDim2.fromScale(1, 1),
                        AnchorPoint = Vector2.new(0, 0),
                        Position = UDim2.fromScale(0, 0.05),

                        TextXAlignment = Enum.TextXAlignment.Left,
                        BackgroundTransparency = 1,
                        TextScaled = true,
                        RichText = true,
                        FontFace = Font,
                    }, {
                        UIScale = React.createElement("UIScale", {
                            Scale = styles.pointsSize,
                        }),
                        UIStroke = React.createElement("UIStroke", {
                            Thickness = 2,
                        }),

                        UIGradient = React.createElement("UIGradient", {
                            Rotation = 90,
                            Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 200, 200)),
                                ColorSequenceKeypoint.new(0.8, Color3.fromRGB(255, 190, 69)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(241, 148, 26)),
                            }),
                        })
                    })
                }),

                HitsHolder = React.createElement("Frame", {
                    Size = UDim2.fromScale(1, 0.2),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.fromScale(0, 0.5),
                    BackgroundTransparency = 1,
                    LayoutOrder = 2,
                }, {
                    PointsLabel = React.createElement("TextLabel", {
                        Text = `<font color="#2CCE17"><i>Hits:</i></font>   <font color="#FFFFFF">{hitStreak.hits}</font>`,

                        Size = UDim2.fromScale(1, 1),
                        AnchorPoint = Vector2.new(0, 0),
                        Position = UDim2.fromScale(0, 0.05),

                        TextXAlignment = Enum.TextXAlignment.Left,
                        BackgroundTransparency = 1,
                        TextScaled = true,
                        RichText = true,
                        FontFace = Font,
                    }, {
                        UIScale = React.createElement("UIScale", {
                            Scale = styles.pointsSize,
                        }),
                        UIStroke = React.createElement("UIStroke", {
                            Thickness = 2,
                        }),

                        UIGradient = React.createElement("UIGradient", {
                            Rotation = 90,
                            Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 200, 200)),
                                ColorSequenceKeypoint.new(0.8, Color3.fromRGB(50, 255, 67)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 167, 16)),
                            }),
                        })
                    })
                }),

                HitStreakHolder = React.createElement("Frame", {
                    Size = UDim2.fromScale(1, 0.2),
                    Position = UDim2.fromScale(0, 0),
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Rotation = -2.5,
                }, {
                    -- UIListLayout = React.createElement("UIListLayout", {
                    --     FillDirection = Enum.FillDirection.Vertical,
                    --     VerticalAlignment = Enum.VerticalAlignment.Center,
                    --     HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    --     SortOrder = Enum.SortOrder.LayoutOrder,
                    -- }),

                    StreakLabel = React.createElement("TextLabel", {
                        Text = `<font color="#FC835C"><i>Streak:</i></font>   <font color="#FFFFFF">{hitStreak.streak}</font>`,
                        -- Visible = props.hitStreak > 0,

                        Size = UDim2.fromScale(1, 1),
                        AnchorPoint = Vector2.new(0, 0),
                        Position = UDim2.fromScale(0, 0.05),

                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = 1,
                        Rotation = 0,
                        BackgroundTransparency = 1,
                        TextScaled = true,
                        RichText = true,
                        FontFace = Font,
                    }, {
                        UIScale = React.createElement("UIScale", {
                            Scale = styles.streakSize,
                        }),
                        UIStroke = React.createElement("UIStroke", {
                            Thickness = 2,
                        }),
                        UIGradient = React.createElement("UIGradient", {
                            Rotation = 90,
                            Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 200, 200)),
                                ColorSequenceKeypoint.new(0.8, Color3.fromRGB(255, 100, 50)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 50, 20)),
                            }),
                        })
                    })
                }),
            }),
        }),

        MiddleHolder = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 0.1),
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale(0.875, 0.5),
            BackgroundTransparency = 1,
            Active = false,
            Selectable = false,
        }, {
            
        }),

        Bottomholder = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 0.15),
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromScale(0.5, 0.7),
            BackgroundTransparency = 1,
            Active = false,
            Selectable = false,
        }, {
            
        }),
        
        TopHolder = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 0.15),
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromScale(0.5, 0.05),
            BackgroundTransparency = 1,
        }, {
            UIListLayout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
            }),

            ProgressPerPlayerHolder = React.createElement("Frame", {
                LayoutOrder = 1,
                Size = UDim2.fromScale(1, 0.65),
                BackgroundTransparency = 1,
            }, {
                ProgressBar = React.createElement("Frame", {
                    Size = UDim2.fromScale(0.55, 0.5),
                    BackgroundColor3 = Color3.fromRGB(15, 255, 123),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                }, {
                    UIStroke = React.createElement("UIStroke", {
                        Thickness = 2,
                    }),
                    UICorner = React.createElement("UICorner", {
                        CornerRadius = UDim.new(0.3, 0),
                    }),
                }, playerHeadshots)
            }),

            StatsHolder = React.createElement("Frame", {
                LayoutOrder = 2,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0.35),
            }, {
                UIListLayout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                }),
            }),
        })
    })
end

local root = ReactRoblox.createRoot(ScreenGui)
-- root:render(React.createElement(statsComponent, {}))

root:render(
    React.createElement(React.StrictMode, nil, 
        React.createElement(statsComponent, {})
    )
)