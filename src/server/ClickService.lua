local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Constants = require(Shared.Constants)
local DataController = require(script.Parent.DataController)

local ClickService = {}

function ClickService:Init()
	self.ClickEvent = Instance.new("RemoteEvent")
	self.ClickEvent.Name = "ClickEvent"
	self.ClickEvent.Parent = ReplicatedStorage

	self.DataUpdateEvent = Instance.new("RemoteEvent")
	self.DataUpdateEvent.Name = "DataUpdateEvent"
	self.DataUpdateEvent.Parent = ReplicatedStorage
end

function ClickService:Start()
	self.ClickEvent.OnServerEvent:Connect(function(player)
		self:ProcessClick(player)
	end)
end

function ClickService:ProcessClick(player)
	local profile = DataController.Profiles[player]
	if not profile then
		return
	end

	local data = profile.Data
	local yield = Constants.BASE_CLICK_YIELD * data.Multipliers.Base

	data.Clicks += yield
	self.DataUpdateEvent:FireClient(player, data)
end

return ClickService
