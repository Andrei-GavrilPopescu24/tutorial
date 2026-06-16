local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputController = {}

function InputController:Init()
	self.ClickEvent = ReplicatedStorage:WaitForChild("ClickEvent")
	self.RebirthFunction = ReplicatedStorage:WaitForChild("RebirthFunction")
	self.PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function InputController:Start()
	local mainUI = self.PlayerGui:WaitForChild("MainUI")
	local clickButton = mainUI:WaitForChild("ClickButton")
	local rebirthButton = mainUI:WaitForChild("RebirthButton")

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
end

return InputController
