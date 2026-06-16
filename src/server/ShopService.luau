local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Constants = require(Shared.Constants)

local ShopService = {
	ActiveCrates = {},
}

function ShopService:Init()
	-- Create ShopUpdateEvent in ReplicatedStorage
	self.ShopUpdateEvent = Instance.new("RemoteEvent")
	self.ShopUpdateEvent.Name = "ShopUpdateEvent"
	self.ShopUpdateEvent.Parent = ReplicatedStorage
end

function ShopService:Start()
	-- Start periodic rotation loop
	task.spawn(function()
		while true do
			self:RotateShop()
			task.wait(Constants.SHOP_REFRESH_INTERVAL)
		end
	end)

	-- Send currently active crates to players who join later
	Players.PlayerAdded:Connect(function(player)
		-- Wait a short moment to ensure client is ready to receive
		task.wait(2)
		self.ShopUpdateEvent:FireClient(player, self.ActiveCrates)
	end)
end

function ShopService:RotateShop()
	-- Get all available crates from Constants
	local allCrateIds = {}
	for crateId, _ in pairs(Constants.CRATES) do
		table.insert(allCrateIds, crateId)
	end

	local newActiveCrates = {}
	local slotCount = math.min(Constants.SHOP_SLOT_COUNT, #allCrateIds)

	-- Randomly pick slotCount crates (without duplicates if possible)
	local tempCrates = { unpack(allCrateIds) }
	for _ = 1, slotCount do
		local idx = math.random(1, #tempCrates)
		table.insert(newActiveCrates, tempCrates[idx])
		table.remove(tempCrates, idx)
	end

	self.ActiveCrates = newActiveCrates

	-- Notify all players
	self.ShopUpdateEvent:FireAllClients(self.ActiveCrates)
	print("Shop Rotated: " .. table.concat(self.ActiveCrates, ", "))
end

function ShopService:IsCrateActive(crateId)
	for _, id in ipairs(self.ActiveCrates) do
		if id == crateId then
			return true
		end
	end
	return false
end

return ShopService
