local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputController = {}

function InputController:Init()
	self.ClickEvent = ReplicatedStorage:WaitForChild("ClickEvent")
	self.RebirthFunction = ReplicatedStorage:WaitForChild("RebirthFunction")
	self.OpenCrateFunction = ReplicatedStorage:WaitForChild("OpenCrateFunction")
	self.PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function InputController:Start()
	local mainUI = self.PlayerGui:WaitForChild("MainUI")
	local clickButton = mainUI:WaitForChild("ClickButton")
	local rebirthButton = mainUI:WaitForChild("RebirthButton")
	local crateButton = mainUI:WaitForChild("CrateButton")

	clickButton.MouseButton1Click:Connect(function()
		self.ClickEvent:FireServer()
	end)

	rebirthButton.MouseButton1Click:Connect(function()
		local success = self.RebirthFunction:InvokeServer()
		if success then
			print("Rebirth successful.")
		else
			print("Insufficient clicks for rebirth.")
		end
	end)

	crateButton.MouseButton1Click:Connect(function()
		if not _G.ActiveShopCrates then
			return
		end

		local targetCrate = _G.ActiveShopCrates[1]
		local success, result = self.OpenCrateFunction:InvokeServer(targetCrate)

		if success then
			print("Unboxed:", result.Rarity)
		else
			print("Transaction Failed:", result)
		end
	end)
end

return InputController
