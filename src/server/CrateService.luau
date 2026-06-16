local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Constants = require(Shared.Constants)
local DataController = require(script.Parent.DataController)
local ClickService = require(script.Parent.ClickService)
local ShopService = require(script.Parent.ShopService)

local CrateService = {}

function CrateService:Init()
	self.OpenCrateFunction = Instance.new("RemoteFunction")
	self.OpenCrateFunction.Name = "OpenCrateFunction"
	self.OpenCrateFunction.Parent = ReplicatedStorage
end

function CrateService:Start()
	self.OpenCrateFunction.OnServerInvoke = function(player, crateId)
		return self:ProcessCrateRoll(player, crateId)
	end
end

function CrateService:ProcessCrateRoll(player, crateId)
	local profile = DataController.Profiles[player]
	if not profile then
		return false, "No Data"
	end

	if not ShopService:IsCrateActive(crateId) then
		return false, "Crate not in shop"
	end

	local crateData = Constants.CRATES[crateId]
	local data = profile.Data

	if data.Clicks < crateData.Cost then
		return false, "Insufficient Clicks"
	end

	data.Clicks -= crateData.Cost

	local totalWeight = 0
	for _, item in ipairs(crateData.LootTable) do
		totalWeight += item.Weight
	end

	local roll = math.random(1, totalWeight)
	local currentWeight = 0
	local selectedItem = nil

	for _, item in ipairs(crateData.LootTable) do
		currentWeight += item.Weight
		if roll <= currentWeight then
			selectedItem = item
			break
		end
	end

	local returnItem = nil
	if selectedItem then
		local id = selectedItem.Id
		data.Inventory[id] = (data.Inventory[id] or 0) + 1
		data.EquippedImage = id

		local itemInfo = Constants.ITEMS[id]
		returnItem = {
			Id = id,
			Name = itemInfo.Name,
			Rarity = itemInfo.Rarity,
			Multiplier = itemInfo.Multiplier,
		}
	end

	ClickService.DataUpdateEvent:FireClient(player, data)
	return true, returnItem
end

return CrateService
