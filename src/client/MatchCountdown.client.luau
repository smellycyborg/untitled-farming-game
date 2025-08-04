local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local TypedRemote = require(Packages:WaitForChild("typed-remote"))
local React = require(Packages:WaitForChild("react"))
local ReactRoblox = require(Packages:WaitForChild("react-roblox"))
local ReactSpring = require(Packages:WaitForChild("react-spring"))




local UpdateCountdown = TypedRemote.event("UpdateCountdown", ReplicatedStorage) :: TypedRemote.Event<number>




local FONT_ID: number = 12187368625




local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")



local TimeLeft = 10

local Enabled = false




local ScreenGui: ScreenGui = Instance.new("ScreenGui", playerGui) :: ScreenGui
ScreenGui.Name = "Countdown"
ScreenGui.ResetOnSpawn = false

local Font = Font.fromId(FONT_ID, Enum.FontWeight.Bold, Enum.FontStyle.Italic)




local function countdownComponent()
	local countdown, setCountdown = React.useState(5)
	local enabled, setEnabled = React.useState(false)

	React.useEffect(function()
		local conn = UpdateCountdown.OnClientEvent:Connect(function(newCountdown: number)
			setEnabled(true)
			setCountdown(newCountdown)

			if newCountdown <= 0 then
				task.delay(2, function()
					setEnabled(false)
				end)
			end
		end)

		return function()
			conn:Disconnect()
		end
	end, {})

	local displayText = countdown >= 1 and `<i><b>{countdown}</b></i>` or "<i><b>Aura Farming!</b></i>"
	local textColor = Color3.new(1, 1, 1)
	if countdown <= 3 and countdown > 0 then
		textColor = Color3.fromRGB(255, 111, 111)
	elseif countdown <= 0 then
		textColor = Color3.fromRGB(59, 255, 52)
	end

	return React.createElement("Frame", {
		Visible = enabled,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	}, {
		CountdownLabel = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.24, 0, 0.14, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.3),
			TextScaled = true,
			TextWrapped = true,
			RichText = true,
			FontFace = Font,
			Text = displayText,
			TextColor3 = textColor,
		}, {
			UIStroke = React.createElement("UIStroke", { Thickness = 2 }),
			Gradient = React.createElement("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 200, 200)),
					ColorSequenceKeypoint.new(0.8, Color3.fromRGB(150, 150, 150)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(126, 126, 126)),
				}),
			}),
		}),
	})
end





local root = ReactRoblox.createLegacyRoot(ScreenGui)
root:render(React.createElement(countdownComponent, {}))