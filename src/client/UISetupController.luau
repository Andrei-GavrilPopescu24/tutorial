local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UISetupController = {}

function UISetupController:Init()
	self.PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	self:SetupCoreUI()
end

function UISetupController:SetupCoreUI()
	-- Prevent double setup
	if self.PlayerGui:FindFirstChild("MainUI") then
		return
	end

	-- 1. Create MainUI ScreenGui
	local mainUI = Instance.new("ScreenGui")
	mainUI.Name = "MainUI"
	mainUI.ResetOnSpawn = false
	mainUI.Parent = self.PlayerGui

	-- 2. Create Click Display (Counter)
	local clickDisplay = Instance.new("TextLabel")
	clickDisplay.Name = "ClickDisplay"
	clickDisplay.Size = UDim2.new(0, 400, 0, 50)
	clickDisplay.Position = UDim2.new(0.5, -200, 0.05, 0)
	clickDisplay.BackgroundTransparency = 1
	clickDisplay.Text = "Clicks: 0"
	clickDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
	clickDisplay.Font = Enum.Font.GothamBold
	clickDisplay.TextSize = 28
	clickDisplay.TextStrokeTransparency = 0.5
	clickDisplay.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	clickDisplay.Parent = mainUI

	-- 3. Create Rebirth Display (Details)
	local rebirthDisplay = Instance.new("TextLabel")
	rebirthDisplay.Name = "RebirthDisplay"
	rebirthDisplay.Size = UDim2.new(0, 500, 0, 30)
	rebirthDisplay.Position = UDim2.new(0.5, -250, 0.12, 0)
	rebirthDisplay.BackgroundTransparency = 1
	rebirthDisplay.Text = "Rebirths: 0 | Multiplier: x1 | Next Cost: 100"
	rebirthDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
	rebirthDisplay.Font = Enum.Font.Gotham
	rebirthDisplay.TextSize = 14
	rebirthDisplay.TextStrokeTransparency = 0.6
	rebirthDisplay.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rebirthDisplay.Parent = mainUI

	-- 4. Create Click Button (Large Circle in center)
	local clickButton = Instance.new("TextButton")
	clickButton.Name = "ClickButton"
	clickButton.Size = UDim2.new(0, 160, 0, 160)
	clickButton.Position = UDim2.new(0.5, -80, 0.38, 0)
	clickButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
	clickButton.Text = "CLICK!"
	clickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	clickButton.Font = Enum.Font.GothamBold
	clickButton.TextSize = 22
	clickButton.Parent = mainUI

	local clickCorner = Instance.new("UICorner")
	clickCorner.CornerRadius = UDim.new(0.5, 0) -- Circle
	clickCorner.Parent = clickButton

	local clickStroke = Instance.new("UIStroke")
	clickStroke.Color = Color3.fromRGB(0, 120, 220)
	clickStroke.Thickness = 4
	clickStroke.Parent = clickButton

	-- Hover Effect for ClickButton
	clickButton.MouseEnter:Connect(function()
		TweenService:Create(clickButton, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(20, 180, 255),
		}):Play()
		TweenService:Create(clickStroke, TweenInfo.new(0.15), {
			Color = Color3.fromRGB(0, 150, 255),
		}):Play()
	end)
	clickButton.MouseLeave:Connect(function()
		TweenService:Create(clickButton, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(0, 162, 255),
		}):Play()
		TweenService:Create(clickStroke, TweenInfo.new(0.15), {
			Color = Color3.fromRGB(0, 120, 220),
		}):Play()
	end)

	-- 5. Create Rebirth Button
	local rebirthButton = Instance.new("TextButton")
	rebirthButton.Name = "RebirthButton"
	rebirthButton.Size = UDim2.new(0, 140, 0, 50)
	rebirthButton.Position = UDim2.new(0.5, 30, 0.75, 0)
	rebirthButton.BackgroundColor3 = Color3.fromRGB(0, 180, 50)
	rebirthButton.Text = "Rebirth"
	rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	rebirthButton.Font = Enum.Font.GothamBold
	rebirthButton.TextSize = 15
	rebirthButton.Parent = mainUI

	local rebirthCorner = Instance.new("UICorner")
	rebirthCorner.CornerRadius = UDim.new(0, 10)
	rebirthCorner.Parent = rebirthButton

	local rebirthStroke = Instance.new("UIStroke")
	rebirthStroke.Color = Color3.fromRGB(0, 130, 30)
	rebirthStroke.Thickness = 1.5
	rebirthStroke.Parent = rebirthButton

	rebirthButton.MouseEnter:Connect(function()
		TweenService:Create(rebirthButton, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(20, 200, 70),
		}):Play()
	end)
	rebirthButton.MouseLeave:Connect(function()
		TweenService:Create(rebirthButton, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(0, 180, 50),
		}):Play()
	end)

	-- 6. Create Crate Button (Unbox Crate)
	local crateButton = Instance.new("TextButton")
	crateButton.Name = "CrateButton"
	crateButton.Size = UDim2.new(0, 150, 0, 50)
	crateButton.Position = UDim2.new(0.5, -180, 0.75, 0)
	crateButton.BackgroundColor3 = Color3.fromRGB(162, 0, 255)
	crateButton.Text = "Unbox Crate\n(Loading...)"
	crateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	crateButton.Font = Enum.Font.GothamBold
	crateButton.TextSize = 12
	crateButton.Parent = mainUI

	local crateCorner = Instance.new("UICorner")
	crateCorner.CornerRadius = UDim.new(0, 10)
	crateCorner.Parent = crateButton

	local crateStroke = Instance.new("UIStroke")
	crateStroke.Color = Color3.fromRGB(120, 0, 200)
	crateStroke.Thickness = 1.5
	crateStroke.Parent = crateButton

	crateButton.MouseEnter:Connect(function()
		TweenService:Create(crateButton, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(182, 30, 255),
		}):Play()
	end)
	crateButton.MouseLeave:Connect(function()
		TweenService:Create(crateButton, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(162, 0, 255),
		}):Play()
	end)
end

return UISetupController
