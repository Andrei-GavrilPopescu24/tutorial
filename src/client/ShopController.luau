local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)

local ShopController = {}

function ShopController:Init()
	self.ShopUpdateEvent = ReplicatedStorage:WaitForChild("ShopUpdateEvent")
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
	end)
end

return ShopController
