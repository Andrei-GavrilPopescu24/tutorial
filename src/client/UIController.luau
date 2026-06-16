local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Constants = require(Shared.Constants)

local UIController = {}

function UIController:AnimateGradient(gradient)
	task.spawn(function()
		while gradient and gradient.Parent do
			local tween = TweenService:Create(gradient, TweenInfo.new(4, Enum.EasingStyle.Linear), {Rotation = 360})
			tween:Play()
			tween.Completed:Wait()
			if gradient then
				gradient.Rotation = 0
			end
		end
	end)
end

function UIController:ApplyGlowingBorder(frame, color1, color2, thickness)
	local stroke = frame:FindFirstChild("GlowingStroke") or Instance.new("UIStroke")
	stroke.Name = "GlowingStroke"
	stroke.Thickness = thickness or 1.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	
	local gradient = stroke:FindFirstChild("GlowGradient") or Instance.new("UIGradient")
	gradient.Name = "GlowGradient"
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(0.5, color2),
		ColorSequenceKeypoint.new(1, color1)
	})
	gradient.Parent = stroke
	
	self:AnimateGradient(gradient)
	return stroke
end

function UIController:AddTechCorners(parent, color)
	local size = 8
	local thickness = 2
	local zIndex = parent.ZIndex + 1

	-- Tidy container
	local cornersContainer = parent:FindFirstChild("TechCorners") or Instance.new("Frame")
	cornersContainer.Name = "TechCorners"
	cornersContainer.Size = UDim2.new(1, 0, 1, 0)
	cornersContainer.BackgroundTransparency = 1
	cornersContainer.ZIndex = zIndex
	cornersContainer.Parent = parent

	cornersContainer:ClearAllChildren()

	-- Top Left Horizontal
	local tlh = Instance.new("Frame")
	tlh.Size = UDim2.new(0, size, 0, thickness)
	tlh.Position = UDim2.new(0, 0, 0, 0)
	tlh.BackgroundColor3 = color
	tlh.BorderSizePixel = 0
	tlh.Parent = cornersContainer
	
	-- Top Left Vertical
	local tlv = Instance.new("Frame")
	tlv.Size = UDim2.new(0, thickness, 0, size)
	tlv.Position = UDim2.new(0, 0, 0, 0)
	tlv.BackgroundColor3 = color
	tlv.BorderSizePixel = 0
	tlv.Parent = cornersContainer

	-- Top Right Horizontal
	local trh = Instance.new("Frame")
	trh.Size = UDim2.new(0, size, 0, thickness)
	trh.Position = UDim2.new(1, -size, 0, 0)
	trh.BackgroundColor3 = color
	trh.BorderSizePixel = 0
	trh.Parent = cornersContainer
	
	-- Top Right Vertical
	local trv = Instance.new("Frame")
	trv.Size = UDim2.new(0, thickness, 0, size)
	trv.Position = UDim2.new(1, -thickness, 0, 0)
	trv.BackgroundColor3 = color
	trv.BorderSizePixel = 0
	trv.Parent = cornersContainer

	-- Bottom Left Horizontal
	local blh = Instance.new("Frame")
	blh.Size = UDim2.new(0, size, 0, thickness)
	blh.Position = UDim2.new(0, 0, 1, -thickness)
	blh.BackgroundColor3 = color
	blh.BorderSizePixel = 0
	blh.Parent = cornersContainer
	
	-- Bottom Left Vertical
	local blv = Instance.new("Frame")
	blv.Size = UDim2.new(0, thickness, 0, size)
	blv.Position = UDim2.new(0, 0, 1, -size)
	blv.BackgroundColor3 = color
	blv.BorderSizePixel = 0
	blv.Parent = cornersContainer

	-- Bottom Right Horizontal
	local brh = Instance.new("Frame")
	brh.Size = UDim2.new(0, size, 0, thickness)
	brh.Position = UDim2.new(1, -size, 1, -thickness)
	brh.BackgroundColor3 = color
	brh.BorderSizePixel = 0
	brh.Parent = cornersContainer
	
	-- Bottom Right Vertical
	local brv = Instance.new("Frame")
	brv.Size = UDim2.new(0, thickness, 0, size)
	brv.Position = UDim2.new(1, -thickness, 1, -size)
	brv.BackgroundColor3 = color
	brv.BorderSizePixel = 0
	brv.Parent = cornersContainer
end

function UIController:Init()
	self.DataUpdateEvent = ReplicatedStorage:WaitForChild("DataUpdateEvent")
	self.PerkTriggerEvent = ReplicatedStorage:WaitForChild("PerkTriggerEvent")
	self.PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function UIController:Start()
	-- Wait for character load
	if not Players.LocalPlayer.Character then
		Players.LocalPlayer.CharacterAdded:Wait()
	end
	task.wait(0.1)

	self:BuildCoreUI()
	self:LockControls()

	-- Register updates
	local function updateUI(data)
		self.ClickDisplay.Text = "Coins: " .. tostring(math.floor(data.Coins))

		local nextCost = math.floor(Constants.BASE_REBIRTH_COST * (Constants.REBIRTH_COST_SCALING ^ data.Rebirths))
		self.RebirthDisplay.Text = string.format(
			"Rebirths: %d  |  Multiplier: x%d  |  Next: %d Coins",
			data.Rebirths,
			data.Multipliers.Base,
			nextCost
		)

		if data.EquippedImage and data.EquippedImage ~= "" then
			self.ClickButton.Image = data.EquippedImage
			if data.EquippedImage == "rbxassetid://0000000" then
				self.ClickButtonText.Visible = true
				self.ClickButtonText.Text = "CLICK!"
			else
				self.ClickButtonText.Visible = false
			end
		else
			self.ClickButton.Image = ""
			self.ClickButtonText.Visible = true
			self.ClickButtonText.Text = "CLICK!"
		end
	end

	self.DataUpdateEvent.OnClientEvent:Connect(updateUI)

	-- Sync initial data
	local requestFunc = ReplicatedStorage:WaitForChild("RequestDataFunction", 10)
	if requestFunc then
		task.spawn(function()
			local initialData = requestFunc:InvokeServer()
			if initialData then
				updateUI(initialData)
			end
		end)
	end

	-- Connect float perk crits popups
	self.PerkTriggerEvent.OnClientEvent:Connect(function(perkName, perkMultiplier)
		local popLabel = Instance.new("TextLabel")
		popLabel.Name = "PerkPopup"
		popLabel.BackgroundTransparency = 1
		
		-- Random position near center
		local rx = math.random(-80, 80)
		local ry = math.random(-40, 40)
		popLabel.Position = UDim2.new(0.5, rx, 0.45, ry)
		popLabel.Size = UDim2.new(0, 250, 0, 30)
		popLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		
		popLabel.Text = string.format("🔥 %s CRIT! (x%d)", perkName, perkMultiplier)
		popLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
		popLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		popLabel.TextStrokeTransparency = 0
		popLabel.Font = Enum.Font.GothamBold
		popLabel.TextSize = 18
		popLabel.Parent = self.MainUI

		-- Pop scale open
		popLabel.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(popLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 250, 0, 30)
		}):Play()

		-- Fade and rise upwards
		local fadeTween = TweenService:Create(popLabel, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.15), {
			Position = UDim2.new(0.5, rx, 0.45, ry - 65),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		
		fadeTween.Completed:Connect(function()
			popLabel:Destroy()
		end)
		
		fadeTween:Play()
	end)
end

function UIController:LockControls()
	task.spawn(function()
		local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts", 10)
		if playerScripts then
			local playerModuleModule = playerScripts:WaitForChild("PlayerModule", 10)
			if playerModuleModule then
				local playerModule = require(playerModuleModule)
				if playerModule and type(playerModule.GetControls) == "function" then
					local controls = playerModule:GetControls()
					controls:Disable()
					print("[UIController] Player movement controls locked.")
				end
			end
		end
	end)
end

function UIController:BuildCoreUI()
	-- 1. Main ScreenGui
	local mainUI = Instance.new("ScreenGui")
	mainUI.Name = "MainUI"
	mainUI.ResetOnSpawn = false
	mainUI.IgnoreGuiInset = true -- Ensure the UI completely covers the whole screen including Roblox topbar
	mainUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Use Sibling mode for nested ZIndex layers
	mainUI.Parent = self.PlayerGui
	self.MainUI = mainUI

	-- 2. Textured Full-Screen Background (Not clear / Dark Space Nebula)
	local bgTexture = Instance.new("ImageLabel")
	bgTexture.Name = "BackgroundTexture"
	bgTexture.Size = UDim2.new(1, 0, 1, 0)
	bgTexture.Position = UDim2.new(0, 0, 0, 0)
	bgTexture.Image = "rbxassetid://6073628185" -- High quality space texture
	bgTexture.ScaleType = Enum.ScaleType.Crop
	bgTexture.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	bgTexture.ImageTransparency = 0.85 -- Make the image texture not clear / very subtle
	bgTexture.ImageColor3 = Color3.fromRGB(120, 130, 160) -- Desaturated steel-blue tint
	bgTexture.ZIndex = 0
	bgTexture.Parent = mainUI
	self.BackgroundTexture = bgTexture

	-- Dark blur tint overlay to make the texture subtle
	local bgOverlay = Instance.new("Frame")
	bgOverlay.Name = "BackgroundOverlay"
	bgOverlay.Size = UDim2.new(1, 0, 1, 0)
	bgOverlay.Position = UDim2.new(0, 0, 0, 0)
	bgOverlay.BackgroundColor3 = Color3.fromRGB(10, 12, 18) -- Dark sci-fi navy
	bgOverlay.BackgroundTransparency = 0.6 -- Let texture show subtly
	bgOverlay.ZIndex = 0
	bgOverlay.Parent = mainUI

	-- 3. Glassmorphic Stats Container (Top Center)
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsFrame"
	statsFrame.Size = UDim2.new(0, 440, 0, 80)
	statsFrame.Position = UDim2.new(0.5, -220, 0.04, 0)
	statsFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
	statsFrame.BackgroundTransparency = 0.2
	statsFrame.ZIndex = 2
	statsFrame.Parent = mainUI

	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 10)
	statsCorner.Parent = statsFrame

	-- Glowing gradient outline and sci-fi brackets
	self:ApplyGlowingBorder(statsFrame, Color3.fromRGB(0, 240, 255), Color3.fromRGB(180, 0, 255), 1.5)
	self:AddTechCorners(statsFrame, Color3.fromRGB(0, 240, 255))

	-- Tiny diagnostic feed label
	local statsTechLabel = Instance.new("TextLabel")
	statsTechLabel.Name = "TechLabel"
	statsTechLabel.Size = UDim2.new(1, 0, 0, 12)
	statsTechLabel.Position = UDim2.new(0, 0, 0, 4)
	statsTechLabel.BackgroundTransparency = 1
	statsTechLabel.Text = "SYSTEM DIAGNOSTICS // DATABASE FEED"
	statsTechLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
	statsTechLabel.TextTransparency = 0.4
	statsTechLabel.Font = Enum.Font.RobotoMono
	statsTechLabel.TextSize = 8
	statsTechLabel.ZIndex = 3
	statsTechLabel.Parent = statsFrame

	-- Click Display inside statsFrame
	local clickDisplay = Instance.new("TextLabel")
	clickDisplay.Name = "ClickDisplay"
	clickDisplay.Size = UDim2.new(1, 0, 0.45, 0)
	clickDisplay.Position = UDim2.new(0, 0, 0, 16)
	clickDisplay.BackgroundTransparency = 1
	clickDisplay.Text = "Coins: 0"
	clickDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
	clickDisplay.Font = Enum.Font.GothamBold
	clickDisplay.TextSize = 22
	clickDisplay.TextStrokeTransparency = 0.5
	clickDisplay.ZIndex = 3
	clickDisplay.Parent = statsFrame
	self.ClickDisplay = clickDisplay

	-- Rebirth Display inside statsFrame
	local rebirthDisplay = Instance.new("TextLabel")
	rebirthDisplay.Name = "RebirthDisplay"
	rebirthDisplay.Size = UDim2.new(1, 0, 0.3, 0)
	rebirthDisplay.Position = UDim2.new(0, 0, 0.58, 0)
	rebirthDisplay.BackgroundTransparency = 1
	rebirthDisplay.Text = "Rebirths: 0  |  Multiplier: x1  |  Next: 100 Coins"
	rebirthDisplay.TextColor3 = Color3.fromRGB(180, 180, 195)
	rebirthDisplay.Font = Enum.Font.GothamMedium
	rebirthDisplay.TextSize = 12
	rebirthDisplay.ZIndex = 3
	rebirthDisplay.Parent = statsFrame
	self.RebirthDisplay = rebirthDisplay

	-- Separator Line inside statsFrame
	local separator = Instance.new("Frame")
	separator.Name = "Separator"
	separator.Size = UDim2.new(0.8, 0, 0, 1)
	separator.Position = UDim2.new(0.1, 0, 0.55, 0)
	separator.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
	separator.BackgroundTransparency = 0.7
	separator.BorderSizePixel = 0
	separator.ZIndex = 3
	separator.Parent = statsFrame

	-- 4. Center Circular Click Button (Power Core Reactor)
	local clickButton = Instance.new("ImageButton")
	clickButton.Name = "ClickButton"
	clickButton.Size = UDim2.new(0, 160, 0, 160)
	clickButton.AnchorPoint = Vector2.new(0.5, 0.5)
	clickButton.Position = UDim2.new(0.5, 0, 0.45, 0)
	clickButton.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	clickButton.BackgroundTransparency = 0.1
	clickButton.ScaleType = Enum.ScaleType.Fit
	clickButton.ZIndex = 2
	clickButton.Parent = mainUI
	self.ClickButton = clickButton

	local clickButtonCorner = Instance.new("UICorner")
	clickButtonCorner.CornerRadius = UDim.new(0.5, 0) -- Perfect Circle
	clickButtonCorner.Parent = clickButton

	self:ApplyGlowingBorder(clickButton, Color3.fromRGB(0, 240, 255), Color3.fromRGB(180, 0, 255), 3)

	-- Pulsing outer reactor ring
	local clickPulse = Instance.new("Frame")
	clickPulse.Name = "ClickPulse"
	clickPulse.Size = UDim2.new(1, 0, 1, 0)
	clickPulse.Position = UDim2.new(0.5, 0, 0.5, 0)
	clickPulse.AnchorPoint = Vector2.new(0.5, 0.5)
	clickPulse.BackgroundTransparency = 1
	clickPulse.ZIndex = 1
	clickPulse.Parent = clickButton

	local pulseCorner = Instance.new("UICorner")
	pulseCorner.CornerRadius = UDim.new(0.5, 0)
	pulseCorner.Parent = clickPulse

	local pulseStroke = Instance.new("UIStroke")
	pulseStroke.Color = Color3.fromRGB(0, 240, 255)
	pulseStroke.Thickness = 2
	pulseStroke.Transparency = 0.5
	pulseStroke.Parent = clickPulse

	task.spawn(function()
		while clickPulse and clickPulse.Parent do
			clickPulse.Size = UDim2.new(1, 0, 1, 0)
			pulseStroke.Transparency = 0.2
			local tweenSize = TweenService:Create(clickPulse, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 35, 1, 35)
			})
			local tweenFade = TweenService:Create(pulseStroke, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1
			})
			tweenSize:Play()
			tweenFade:Play()
			task.wait(1.8)
		end
	end)

	-- Text fallback label inside Click Button
	local clickButtonText = Instance.new("TextLabel")
	clickButtonText.Name = "ClickButtonText"
	clickButtonText.Size = UDim2.new(1, 0, 1, 0)
	clickButtonText.BackgroundTransparency = 1
	clickButtonText.Text = "CLICK!"
	clickButtonText.TextColor3 = Color3.fromRGB(0, 240, 255)
	clickButtonText.Font = Enum.Font.GothamBlack
	clickButtonText.TextSize = 22
	clickButtonText.TextStrokeTransparency = 0.5
	clickButtonText.Active = false
	clickButtonText.Selectable = false
	clickButtonText.ZIndex = 3
	clickButtonText.Parent = clickButton
	self.ClickButtonText = clickButtonText

	-- Reactor sub-text
	local clickSubText = Instance.new("TextLabel")
	clickSubText.Name = "ClickSubText"
	clickSubText.Size = UDim2.new(1, 0, 0, 15)
	clickSubText.Position = UDim2.new(0, 0, 0.68, 0)
	clickSubText.BackgroundTransparency = 1
	clickSubText.Text = "REACTOR MODULE"
	clickSubText.TextColor3 = Color3.fromRGB(180, 0, 255) -- Plasma Purple
	clickSubText.Font = Enum.Font.RobotoMono
	clickSubText.TextSize = 8
	clickSubText.ZIndex = 3
	clickSubText.Parent = clickButton

	-- Hover & Pulsing animations for ClickButton
	clickButton.MouseEnter:Connect(function()
		TweenService:Create(clickButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 175, 0, 175)
		}):Play()
	end)
	clickButton.MouseLeave:Connect(function()
		TweenService:Create(clickButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 160, 0, 160)
		}):Play()
	end)

	-- 5. Bottom Menu Bar Spanning HUD Console
	local menuBar = Instance.new("Frame")
	menuBar.Name = "MenuBar"
	menuBar.Size = UDim2.new(0, 380, 0, 70)
	menuBar.Position = UDim2.new(0.5, -190, 0.83, 0)
	menuBar.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
	menuBar.BackgroundTransparency = 0.15
	menuBar.ZIndex = 2
	menuBar.Parent = mainUI
	self.MenuBar = menuBar

	local menuCorner = Instance.new("UICorner")
	menuCorner.CornerRadius = UDim.new(0, 12)
	menuCorner.Parent = menuBar

	self:ApplyGlowingBorder(menuBar, Color3.fromRGB(0, 240, 255), Color3.fromRGB(180, 0, 255), 1.5)
	self:AddTechCorners(menuBar, Color3.fromRGB(0, 240, 255))

	-- Console sub-header
	local menuTechLabel = Instance.new("TextLabel")
	menuTechLabel.Name = "TechLabel"
	menuTechLabel.Size = UDim2.new(1, 0, 0, 12)
	menuTechLabel.Position = UDim2.new(0, 0, 0, 4)
	menuTechLabel.BackgroundTransparency = 1
	menuTechLabel.Text = "HOLOGRAPHIC CHANNELS // CONSOLE V1.0"
	menuTechLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
	menuTechLabel.TextTransparency = 0.5
	menuTechLabel.Font = Enum.Font.RobotoMono
	menuTechLabel.TextSize = 7
	menuTechLabel.ZIndex = 3
	menuTechLabel.Parent = menuBar

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 12)
	listLayout.Parent = menuBar

	-- Add padding to bottom to fit layout neatly
	local layoutPadding = Instance.new("UIPadding")
	layoutPadding.PaddingBottom = UDim.new(0, 8)
	layoutPadding.Parent = menuBar

	-- Rebirth Button (Inside MenuBar)
	local rebirthButton = Instance.new("TextButton")
	rebirthButton.Name = "RebirthButton"
	rebirthButton.Size = UDim2.new(0, 110, 0, 42)
	rebirthButton.BackgroundColor3 = Color3.fromRGB(10, 32, 22) -- Dark sci-fi green
	rebirthButton.Text = "♻ REBIRTH.EXE"
	rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	rebirthButton.Font = Enum.Font.GothamBold
	rebirthButton.TextSize = 11
	rebirthButton.LayoutOrder = 1
	rebirthButton.ZIndex = 3
	rebirthButton.Parent = menuBar

	local rebirthCorner = Instance.new("UICorner")
	rebirthCorner.CornerRadius = UDim.new(0, 6)
	rebirthCorner.Parent = rebirthButton

	local rebirthStroke = Instance.new("UIStroke")
	rebirthStroke.Color = Color3.fromRGB(0, 255, 100) -- glowing neon green stroke
	rebirthStroke.Thickness = 1.2
	rebirthStroke.Parent = rebirthButton

	rebirthButton.MouseEnter:Connect(function()
		TweenService:Create(rebirthButton, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(15, 50, 32) }):Play()
		TweenService:Create(rebirthStroke, TweenInfo.new(0.12), { Thickness = 2 }):Play()
	end)
	rebirthButton.MouseLeave:Connect(function()
		TweenService:Create(rebirthButton, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(10, 32, 22) }):Play()
		TweenService:Create(rebirthStroke, TweenInfo.new(0.12), { Thickness = 1.2 }):Play()
	end)

	-- Shop Button (Inside MenuBar)
	local shopButton = Instance.new("TextButton")
	shopButton.Name = "CrateShopButton"
	shopButton.Size = UDim2.new(0, 110, 0, 42)
	shopButton.BackgroundColor3 = Color3.fromRGB(32, 10, 32) -- Dark sci-fi violet
	shopButton.Text = "🏪 SHOP.NET"
	shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopButton.Font = Enum.Font.GothamBold
	shopButton.TextSize = 11
	shopButton.LayoutOrder = 3
	shopButton.ZIndex = 3
	shopButton.Parent = menuBar

	local shopCorner = Instance.new("UICorner")
	shopCorner.CornerRadius = UDim.new(0, 6)
	shopCorner.Parent = shopButton

	local shopStroke = Instance.new("UIStroke")
	shopStroke.Color = Color3.fromRGB(180, 0, 255) -- glowing neon purple stroke
	shopStroke.Thickness = 1.2
	shopStroke.Parent = shopButton

	shopButton.MouseEnter:Connect(function()
		TweenService:Create(shopButton, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(50, 15, 50) }):Play()
		TweenService:Create(shopStroke, TweenInfo.new(0.12), { Thickness = 2 }):Play()
	end)
	shopButton.MouseLeave:Connect(function()
		TweenService:Create(shopButton, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(32, 10, 32) }):Play()
		TweenService:Create(shopStroke, TweenInfo.new(0.12), { Thickness = 1.2 }):Play()
	end)
end

function UIController:SetBackgroundTexture(imageId)
	if self.BackgroundTexture then
		self.BackgroundTexture.Image = imageId
	end
end

function UIController:SetBackgroundClearness(clearness)
	-- clearness should be a number from 0 to 1
	-- where 0 is completely hidden/dark and 1 is as clear as possible (capped to keep it "not that clear")
	if self.BackgroundTexture then
		self.BackgroundTexture.ImageTransparency = 1 - (clearness * 0.4)
	end
end

return UIController
