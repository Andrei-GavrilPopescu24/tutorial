local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Assumes ProfileService module is synced to ReplicatedStorage.Shared
local ProfileService = require(ReplicatedStorage.Shared.ProfileService)

local ProfileTemplate = {
	Coins = 0,
	Rebirths = 0,
	Multipliers = {
		Base = 1,
	},
	Inventory = {
		["rbxassetid://0000000"] = 1, -- Default image ID: Quantity
	},
	EquippedImage = "rbxassetid://0000000",
}

local ProfileStore = ProfileService.GetProfileStore("ClickerData_v1", ProfileTemplate)

local Profiles = {}

local function PlayerAdded(player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)

	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick("Data session terminated. Rejoin.")
		end)

		if player:IsDescendantOf(Players) == true then
			Profiles[player] = profile
			
			-- Migration: Convert Clicks to Coins if upgrading old profile
			if profile.Data.Clicks ~= nil then
				profile.Data.Coins = profile.Data.Clicks
				profile.Data.Clicks = nil
			end
			
			-- Fire initial data update once client is initialized
			task.spawn(function()
				task.wait(1.5)
				local ClickService = require(script.Parent.ClickService)
				if ClickService and ClickService.DataUpdateEvent then
					ClickService.DataUpdateEvent:FireClient(player, profile.Data)
				end
			end)
		else
			profile:Release()
		end
	else
		player:Kick("Data load failure. Rejoin.")
	end
end

local function PlayerRemoving(player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:Release()
	end
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerAdded, player)
end

return {
	Profiles = Profiles,
}
