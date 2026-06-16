local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Constants = require(Shared.Constants)

local UIController = {}

function UIController:Init()
	self.DataUpdateEvent = ReplicatedStorage:WaitForChild("DataUpdateEvent")
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
end

return UIController
