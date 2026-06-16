local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)

local ShopController = {}

function ShopController:Init()
	self.ShopUpdateEvent = ReplicatedStorage:WaitForChild("ShopUpdateEvent")
	self.PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function ShopController:Start()
	self.ShopUpdateEvent.OnClientEvent:Connect(function(activeCrates)
		print("--- SHOP ROTATION ---")
		for i, crateId in ipairs(activeCrates) do
			local crateData = Constants.CRATES[crateId]
			print(string.format("Slot %d: %s | Cost: %d", i, crateId, crateData.Cost))
		end

		-- Store globally for input testing
		_G.ActiveShopCrates = activeCrates

		-- Update CrateButton text
		local mainUI = self.PlayerGui:FindFirstChild("MainUI")
		if mainUI then
			local crateButton = mainUI:FindFirstChild("CrateButton")
			if crateButton and activeCrates[1] then
				local crateId = activeCrates[1]
				local crateData = Constants.CRATES[crateId]
				crateButton.Text = string.format("Unbox %s\n(%d Clicks)", crateId, crateData.Cost)
			end
		end
	end)
end


return ShopController
