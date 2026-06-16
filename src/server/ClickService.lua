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

	self.PerkTriggerEvent = Instance.new("RemoteEvent")
	self.PerkTriggerEvent.Name = "PerkTriggerEvent"
	self.PerkTriggerEvent.Parent = ReplicatedStorage

	self.RequestDataFunction = Instance.new("RemoteFunction")
	self.RequestDataFunction.Name = "RequestDataFunction"
	self.RequestDataFunction.Parent = ReplicatedStorage
end

function ClickService:Start()
	self.ClickEvent.OnServerEvent:Connect(function(player)
		self:ProcessClick(player)
	end)

	self.RequestDataFunction.OnServerInvoke = function(player)
		local profile = DataController.Profiles[player]
		if profile then
			return profile.Data
		end
		-- Retry loop in case profile is still loading asynchronously
		for _ = 1, 10 do
			task.wait(0.2)
			profile = DataController.Profiles[player]
			if profile then
				return profile.Data
			end
		end
		return nil
	end
end

function ClickService:ProcessClick(player)
	print("[ClickService] ProcessClick called by " .. tostring(player.Name))
	local profile = DataController.Profiles[player]
	if not profile then
		warn("[ClickService] Profile not found for player: " .. tostring(player.Name))
		return
	end

	local data = profile.Data
	local equippedId = data.EquippedImage or "rbxassetid://0000000"
	local itemInfo = Constants.ITEMS[equippedId] or Constants.ITEMS["rbxassetid://0000000"]
	print("[ClickService] Player " .. player.Name .. " equipped item: " .. tostring(equippedId) .. " (Mult: " .. tostring(itemInfo.Multiplier) .. ")")

	local baseYield = Constants.BASE_CLICK_YIELD
	local rebirthMult = data.Multipliers.Base or 1
	local itemMult = itemInfo.Multiplier or 1

	local yield = baseYield * rebirthMult * itemMult

	-- Roll for critical perk activation
	local perkTriggered = false
	local perkMultiplier = 1
	local rolledChance = math.random(1, 100)

	if equippedId == "rbxassetid://1111111" then -- Goku (SSJ): 10% chance to double click yield
		if rolledChance <= 10 then
			perkTriggered = true
			perkMultiplier = 2
		end
	elseif equippedId == "rbxassetid://2222222" then -- Naruto (Sage): 15% chance to triple click yield
		if rolledChance <= 15 then
			perkTriggered = true
			perkMultiplier = 3
		end
	elseif equippedId == "rbxassetid://3333333" then -- Luffy (Gear 4): 20% chance to quadruple click yield
		if rolledChance <= 20 then
			perkTriggered = true
			perkMultiplier = 4
		end
	elseif equippedId == "rbxassetid://4444444" then -- Ichigo (Bankai): 10% chance to gain 10x click yield
		if rolledChance <= 10 then
			perkTriggered = true
			perkMultiplier = 10
		end
	end

	if perkTriggered then
		yield *= perkMultiplier
		self.PerkTriggerEvent:FireClient(player, itemInfo.PerkName, perkMultiplier)
	end

	data.Coins += yield
	print("[ClickService] Coins updated for " .. player.Name .. " -> Coins: " .. tostring(data.Coins) .. " (Yield: " .. tostring(yield) .. ")")
	self.DataUpdateEvent:FireClient(player, data)
end


return ClickService
