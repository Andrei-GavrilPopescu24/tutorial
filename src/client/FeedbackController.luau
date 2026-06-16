local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local FeedbackController = {}

function FeedbackController:Init()
	self.PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	self.ClickSound = Instance.new("Sound")
	self.ClickSound.SoundId = "rbxassetid://6895079853"
	self.ClickSound.Volume = 0.5
	self.ClickSound.Parent = SoundService
end

function FeedbackController:Start()
	local mainUI = self.PlayerGui:WaitForChild("MainUI")
	local clickButton = mainUI:WaitForChild("ClickButton")

	-- Ensure exact property existence before tweening
	if not clickButton then
		return
	end

	local originalSize = clickButton.Size
	local tweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)

	local targetSize = UDim2.new(
		originalSize.X.Scale * 0.9,
		originalSize.X.Offset * 0.9,
		originalSize.Y.Scale * 0.9,
		originalSize.Y.Offset * 0.9
	)

	local clickTween = TweenService:Create(clickButton, tweenInfo, { Size = targetSize })

	clickButton.MouseButton1Down:Connect(function()
		-- Block animations and sounds when menus are open
		local shopFrame = mainUI:FindFirstChild("ShopFrame")
		local inventoryFrame = mainUI:FindFirstChild("InventoryFrame")

		local shopVisible = shopFrame and shopFrame.Visible
		local inventoryVisible = inventoryFrame and inventoryFrame.Visible

		if shopVisible or inventoryVisible then
			return
		end

		self.ClickSound:Play()
		clickTween:Play()
	end)
end

return FeedbackController
