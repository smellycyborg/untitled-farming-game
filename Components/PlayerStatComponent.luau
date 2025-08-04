local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local React = require(Packages:WaitForChild("react"))
local ReactRoblox = require(Packages:WaitForChild("react-roblox"))
local ReactSpring = require(Packages:WaitForChild("react-spring"))



local FONT_ID: number = 12187368625




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

return function(props: {[string]: any})
    return React.createElement("Frame", {
        LayoutOrder = props.placeNumber,

        Size = UDim2.fromScale(0.95, 0.3),
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
    }, {
        UIListLayout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),

        Playerheadshot = React.createElement("Frame", {
            LayoutOrder = 1,
            Size = UDim2.fromScale(0.075, 1),
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            ClipsDescendants = true,
        }, {
            UIScale = React.createElement("UIScale", {
                Scale = 1.5,
            }),

            ImageLabel = React.createElement("ImageLabel", {
                Image = getPlayerHeadshot(props.userId),
                
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                ScaleType = Enum.ScaleType.Fit,
            })
        }),

        TextLabel = React.createElement("TextLabel", {
            Text = `{props.displayName}: {props.statText}`,
            FontFace = Font,

            LayoutOrder = 2,
            Size = UDim2.fromScale(0.95, 1),
            BackgroundTransparency = 1,
            TextScaled = true,
            TextColor3 = Color3.fromRGB(255, 255, 255),
        }),
    })
end
