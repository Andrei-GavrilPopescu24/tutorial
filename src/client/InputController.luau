local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputController = {}

function InputController:Init()
	-- Emptied to prevent bootstrapper deadlocks
end

function InputController:Start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local mainUI = playerGui:WaitForChild("MainUI", 5)

	if not mainUI then
		warn("[InputController] MainUI missing. UIController failed.")
		return
	end

	local clickButton = mainUI:WaitForChild("ClickButton")
	local menuBar = mainUI:WaitForChild("MenuBar")
	local rebirthButton = menuBar:WaitForChild("RebirthButton")

	local clickEvent = ReplicatedStorage:WaitForChild("ClickEvent", 10)
	local rebirthFunction = ReplicatedStorage:WaitForChild("RebirthFunction", 10)

	if not clickEvent or not rebirthFunction then
		warn("[InputController] Network instances missing. Server failed to boot.")
		return
	end

	clickButton.MouseButton1Down:Connect(function()
		-- Block clicking when either menu is open
		local shopFrame = mainUI:FindFirstChild("ShopFrame")
		local inventoryFrame = mainUI:FindFirstChild("InventoryFrame")

		local shopVisible = shopFrame and shopFrame.Visible
		local inventoryVisible = inventoryFrame and inventoryFrame.Visible

		if shopVisible or inventoryVisible then
			return
		end

		clickEvent:FireServer()
	end)

	rebirthButton.MouseButton1Click:Connect(function()
		local success = rebirthFunction:InvokeServer()
		if success then
			print("Rebirth successful.")
		else
			print("Insufficient clicks for rebirth.")
		end
	end)
end

return InputController
