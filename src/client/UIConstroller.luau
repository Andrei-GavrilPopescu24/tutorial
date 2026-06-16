local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Constants = require(Shared.Constants)

local UIController = {}

function UIController:Init()
	self.DataUpdateEvent = ReplicatedStorage:WaitForChild("DataUpdateEvent")
	self.PerkTriggerEvent = ReplicatedStorage:WaitForChild("PerkTriggerEvent")
	self.PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function UIController:Start()
	local mainUI = self.PlayerGui:WaitForChild("MainUI")
	local clickDisplay = mainUI:WaitForChild("ClickDisplay")
	local rebirthDisplay = mainUI:WaitForChild("RebirthDisplay")

	self.DataUpdateEvent.OnClientEvent:Connect(function(data)
		clickDisplay.Text = "Clicks: " .. tostring(math.floor(data.Clicks))

		local nextCost = math.floor(Constants.BASE_REBIRTH_COST * (Constants.REBIRTH_COST_SCALING ^ data.Rebirths))
		local statsString = string.format(
			"Rebirths: %d | Multiplier: x%d | Next Cost: %d",
			data.Rebirths,
			data.Multipliers.Base,
			nextCost
		)

		rebirthDisplay.Text = statsString
	end)

	-- Floating crit popups on perk triggers
	self.PerkTriggerEvent.OnClientEvent:Connect(function(perkName, perkMultiplier)
		local popLabel = Instance.new("TextLabel")
		popLabel.Name = "PerkPopup"
		popLabel.BackgroundTransparency = 1
		
		-- Random position near center screen
		local rx = math.random(-80, 80)
		local ry = math.random(-40, 40)
		popLabel.Position = UDim2.new(0.5, rx, 0.45, ry)
		popLabel.Size = UDim2.new(0, 250, 0, 30)
		popLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		
		popLabel.Text = string.format("🔥 %s CRIT! (x%d)", perkName, perkMultiplier)
		popLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
		popLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		popLabel.TextStrokeTransparency = 0
		popLabel.Font = Enum.Font.GothamBold
		popLabel.TextSize = 18
		popLabel.Parent = mainUI

		-- Pop scale opening
		popLabel.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(popLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 250, 0, 30)
		}):Play()

		-- Fade and rise upwards
		local fadeTween = TweenService:Create(popLabel, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.15), {
			Position = UDim2.new(0.5, rx, 0.45, ry - 65),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		
		fadeTween.Completed:Connect(function()
			popLabel:Destroy()
		end)
		
		fadeTween:Play()
	end)
end


return UIController
