local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Constants = require(Shared.Constants)
local DataController = require(script.Parent.DataController)
local ClickService = require(script.Parent.ClickService)

local InventoryService = {}

function InventoryService:Init()
	-- Create EquipItemFunction in ReplicatedStorage
	self.EquipItemFunction = Instance.new("RemoteFunction")
	self.EquipItemFunction.Name = "EquipItemFunction"
	self.EquipItemFunction.Parent = ReplicatedStorage
end

function InventoryService:Start()
	self.EquipItemFunction.OnServerInvoke = function(player, itemId)
		return self:EquipItem(player, itemId)
	end
end

function InventoryService:EquipItem(player, itemId)
	local profile = DataController.Profiles[player]
	if not profile then
		return false, "No player data"
	end

	local data = profile.Data

	-- Validate that player owns the item, or it's the default baseline item
	local isDefault = (itemId == "rbxassetid://0000000")
	local ownsItem = (data.Inventory[itemId] and data.Inventory[itemId] > 0)

	if not (isDefault or ownsItem) then
		return false, "Item not owned"
	end

	-- Update equipped item
	data.EquippedImage = itemId

	-- Push data update to client
	ClickService.DataUpdateEvent:FireClient(player, data)

	return true, itemId
end

return InventoryService
