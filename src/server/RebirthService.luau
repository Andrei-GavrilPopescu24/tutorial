local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Constants = require(Shared.Constants)
local DataController = require(script.Parent.DataController)
local ClickService = require(script.Parent.ClickService)

local RebirthService = {}

function RebirthService:Init()
	self.RebirthFunction = Instance.new("RemoteFunction")
	self.RebirthFunction.Name = "RebirthFunction"
	self.RebirthFunction.Parent = ReplicatedStorage
end

function RebirthService:Start()
	self.RebirthFunction.OnServerInvoke = function(player)
		return self:ProcessRebirth(player)
	end
end

function RebirthService:ProcessRebirth(player)
	local profile = DataController.Profiles[player]
	if not profile then
		return false
	end

	local data = profile.Data
	local cost = math.floor(Constants.BASE_REBIRTH_COST * (Constants.REBIRTH_COST_SCALING ^ data.Rebirths))

	if data.Clicks >= cost then
		data.Clicks -= cost
		data.Rebirths += 1
		data.Multipliers.Base = data.Rebirths + 1

		ClickService.DataUpdateEvent:FireClient(player, data)
		return true
	end

	return false
end

return RebirthService
