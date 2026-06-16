local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Constants = require(Shared.Constants)
local UIController = require(script.Parent:WaitForChild("UIController"))

local ShopController = {
	ShopFrame = nil,
	MainUI = nil,
	CurrentData = nil,
}

local RarityColors = {
	["Common"] = Color3.fromRGB(140, 140, 140),
	["Rare"] = Color3.fromRGB(0, 150, 255),
	["Epic"] = Color3.fromRGB(160, 0, 255),
	["Legendary"] = Color3.fromRGB(255, 150, 0),
}

function ShopController:Init()
	self.ShopUpdateEvent = ReplicatedStorage:WaitForChild("ShopUpdateEvent")
	self.OpenCrateFunction = ReplicatedStorage:WaitForChild("OpenCrateFunction")
	self.DataUpdateEvent = ReplicatedStorage:WaitForChild("DataUpdateEvent")
	self.PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function ShopController:Start()
	self.MainUI = self.PlayerGui:WaitForChild("MainUI")
	
	self:BuildShopUI()

	-- Track player currency/data for purchase validations
	self.DataUpdateEvent.OnClientEvent:Connect(function(data)
		self.CurrentData = data
	end)

	-- Request initial data in case it's not set
	local requestFunc = ReplicatedStorage:WaitForChild("RequestDataFunction", 10)
	if requestFunc then
		task.spawn(function()
			local initialData = requestFunc:InvokeServer()
			if initialData then
				self.CurrentData = initialData
			end
		end)
	end

	-- Listen to Shop Rotations
	self.ShopUpdateEvent.OnClientEvent:Connect(function(activeCrates)
		print("--- SHOP ROTATION RECIEVED ---")
		_G.ActiveShopCrates = activeCrates
		if self.ShopFrame.Visible then
			self:RefreshShopCards()
		end
	end)
end

function ShopController:BuildShopUI()
	local menuBar = self.MainUI:WaitForChild("MenuBar")
	local shopBtn = menuBar:WaitForChild("CrateShopButton")

	-- 1. Create main Shop Frame
	local frame = Instance.new("Frame")
	frame.Name = "ShopFrame"
	frame.Size = UDim2.new(0, 520, 0, 350)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(12, 13, 20) -- Dark Slate Navy
	frame.BackgroundTransparency = 0.15
	frame.Visible = false
	frame.ZIndex = 5 -- Render on top of HUD click button / stats
	frame.Parent = self.MainUI
	self.ShopFrame = frame

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 12)
	frameCorner.Parent = frame

	-- Apply glowing border and corners using UIController
	UIController:ApplyGlowingBorder(frame, Color3.fromRGB(0, 240, 255), Color3.fromRGB(180, 0, 255), 1.8)
	UIController:AddTechCorners(frame, Color3.fromRGB(0, 240, 255))

	-- 2. Title Label & Subtitle
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -60, 0, 25)
	titleLabel.Position = UDim2.new(0, 20, 0, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "// HOLOGRAPHIC MARKET"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 16
	titleLabel.Parent = frame

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "SubtitleLabel"
	subtitleLabel.Size = UDim2.new(1, -60, 0, 15)
	subtitleLabel.Position = UDim2.new(0, 20, 0, 32)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "SECURE NETWORK CONNECTION // DATA ENCRYPTED"
	subtitleLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
	subtitleLabel.TextTransparency = 0.5
	subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	subtitleLabel.Font = Enum.Font.RobotoMono
	subtitleLabel.TextSize = 8
	subtitleLabel.Parent = frame

	-- 3. Close Button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -40, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(35, 15, 20)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 100, 100)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 14
	closeButton.Parent = frame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton

	local closeStroke = Instance.new("UIStroke")
	closeStroke.Color = Color3.fromRGB(180, 50, 50)
	closeStroke.Thickness = 1.2
	closeStroke.Parent = closeButton
	
	closeButton.MouseEnter:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(80, 20, 25), TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
		TweenService:Create(closeStroke, TweenInfo.new(0.12), { Thickness = 2 }):Play()
	end)
	closeButton.MouseLeave:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(35, 15, 20), TextColor3 = Color3.fromRGB(255, 100, 100) }):Play()
		TweenService:Create(closeStroke, TweenInfo.new(0.12), { Thickness = 1.2 }):Play()
	end)

	closeButton.MouseButton1Click:Connect(function()
		self:ToggleShop(false)
	end)

	-- Open/Close toggle connection
	shopBtn.MouseButton1Click:Connect(function()
		self:ToggleShop(not frame.Visible)
	end)

	-- 4. Container for cards
	local container = Instance.new("Frame")
	container.Name = "CardsContainer"
	container.Size = UDim2.new(1, -30, 0.8, -10)
	container.Position = UDim2.new(0, 15, 0.18, 0)
	container.BackgroundTransparency = 1
	container.Parent = frame
	self.CardsContainer = container

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 15)
	listLayout.Parent = container
end

function ShopController:ToggleShop(visible)
	self.ShopFrame.Visible = visible
	if visible then
		-- Close Inventory frame if open to prevent menu overlap
		local inventoryFrame = self.MainUI:FindFirstChild("InventoryFrame")
		if inventoryFrame then
			inventoryFrame.Visible = false
		end

		self.ShopFrame.Size = UDim2.new(0, 400, 0, 260)
		TweenService:Create(self.ShopFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 520, 0, 350)
		}):Play()
		self:RefreshShopCards()
	end
end

function ShopController:RefreshShopCards()
	-- Clear container items
	for _, child in ipairs(self.CardsContainer:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local activeCrates = _G.ActiveShopCrates
	if not activeCrates or #activeCrates == 0 then
		local loading = Instance.new("TextLabel")
		loading.Size = UDim2.new(1, 0, 1, 0)
		loading.BackgroundTransparency = 1
		loading.Text = "Waiting for shop rotation..."
		loading.TextColor3 = Color3.fromRGB(150, 150, 150)
		loading.Font = Enum.Font.GothamMedium
		loading.TextSize = 16
		loading.Parent = self.CardsContainer
		return
	end

	for idx, crateId in ipairs(activeCrates) do
		local crateData = Constants.CRATES[crateId]
		if not crateData then continue end

		local cardColor = RarityColors[crateData.Rarity] or Color3.fromRGB(255, 255, 255)

		-- Card Slot Frame
		local card = Instance.new("Frame")
		card.Name = "CrateCard_" .. crateId
		card.Size = UDim2.new(0, 145, 0, 240)
		card.BackgroundColor3 = Color3.fromRGB(16, 17, 24)
		card.BackgroundTransparency = 0.2
		card.LayoutOrder = idx
		card.Parent = self.CardsContainer

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 8)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = Color3.fromRGB(35, 38, 48) -- slate dark outline
		cardStroke.Thickness = 1.2
		cardStroke.Parent = card

		-- Top Rarity Stripe Accent
		local accentBar = Instance.new("Frame")
		accentBar.Name = "AccentBar"
		accentBar.Size = UDim2.new(1, 0, 0, 4)
		accentBar.Position = UDim2.new(0, 0, 0, 0)
		accentBar.BackgroundColor3 = cardColor
		accentBar.BorderSizePixel = 0
		accentBar.Parent = card

		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(0, 4)
		accentCorner.Parent = accentBar

		-- Inner container for hover scaling
		local inner = Instance.new("Frame")
		inner.Name = "Inner"
		inner.Size = UDim2.new(1, 0, 1, 0)
		inner.Position = UDim2.new(0.5, 0, 0.5, 0)
		inner.AnchorPoint = Vector2.new(0.5, 0.5)
		inner.BackgroundTransparency = 1
		inner.Parent = card

		-- Crate Title Label
		local crateTitle = Instance.new("TextLabel")
		crateTitle.Size = UDim2.new(1, -10, 0, 30)
		crateTitle.Position = UDim2.new(0, 5, 0, 10)
		crateTitle.BackgroundTransparency = 1
		crateTitle.Text = crateId:gsub("Crate", " Crate")
		crateTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		crateTitle.Font = Enum.Font.GothamBold
		crateTitle.TextSize = 13
		crateTitle.Parent = inner

		-- Rarity Badge
		local rarityBadge = Instance.new("TextLabel")
		rarityBadge.Size = UDim2.new(0, 80, 0, 18)
		rarityBadge.Position = UDim2.new(0.5, -40, 0, 42)
		rarityBadge.BackgroundColor3 = cardColor
		rarityBadge.Text = crateData.Rarity:upper()
		rarityBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
		rarityBadge.Font = Enum.Font.GothamBold
		rarityBadge.TextSize = 10
		rarityBadge.Parent = inner

		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 4)
		badgeCorner.Parent = rarityBadge

		-- Dynamic chest image based on crate type
		local chestImage = "rbxassetid://142662232" -- Standard: Wooden Crate
		if crateId == "PremiumCrate" then
			chestImage = "rbxassetid://152862804" -- Premium: Iron Chest
		elseif crateId == "MythicCrate" then
			chestImage = "rbxassetid://607901062" -- Mythic: Golden Treasure Chest
		end

		-- Glow frame for icon representing rarity
		local iconFrame = Instance.new("Frame")
		iconFrame.Name = "IconFrame"
		iconFrame.Size = UDim2.new(0, 64, 0, 64)
		iconFrame.Position = UDim2.new(0.5, -32, 0, 68)
		iconFrame.BackgroundColor3 = cardColor
		iconFrame.BackgroundTransparency = 0.85
		iconFrame.Parent = inner

		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, 8)
		iconCorner.Parent = iconFrame

		local iconStroke = Instance.new("UIStroke")
		iconStroke.Color = cardColor
		iconStroke.Thickness = 1
		iconStroke.Parent = iconFrame

		local crateImage = Instance.new("ImageLabel")
		crateImage.Name = "CrateImage"
		crateImage.Size = UDim2.new(1, -12, 1, -12) -- Inset slightly inside glow box
		crateImage.Position = UDim2.new(0, 6, 0, 6)
		crateImage.BackgroundTransparency = 1
		crateImage.Image = chestImage
		crateImage.ScaleType = Enum.ScaleType.Fit
		crateImage.Parent = iconFrame

		-- Cost Display
		local costLabel = Instance.new("TextLabel")
		costLabel.Size = UDim2.new(1, 0, 0, 20)
		costLabel.Position = UDim2.new(0, 0, 0, 140)
		costLabel.BackgroundTransparency = 1
		costLabel.Text = string.format("💰 $%d", crateData.Cost)
		costLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold text
		costLabel.Font = Enum.Font.RobotoMono
		costLabel.TextSize = 12
		costLabel.Parent = inner

		-- Purchase Button (labeled "Open" as requested)
		local buyBtn = Instance.new("TextButton")
		buyBtn.Name = "BuyButton"
		buyBtn.Size = UDim2.new(1, -24, 0, 32)
		buyBtn.Position = UDim2.new(0, 12, 1, -44)
		buyBtn.BackgroundColor3 = Color3.fromRGB(22, 23, 30)
		buyBtn.Text = "Open"
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.TextSize = 13
		buyBtn.Parent = inner

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 6)
		buyCorner.Parent = buyBtn

		local buyStroke = Instance.new("UIStroke")
		buyStroke.Color = cardColor
		buyStroke.Thickness = 1.2
		buyStroke.Parent = buyBtn

		-- Hover Transitions on Card
		card.MouseEnter:Connect(function()
			TweenService:Create(inner, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1.04, 0, 1.04, 0)
			}):Play()
			TweenService:Create(cardStroke, TweenInfo.new(0.12), {
				Color = cardColor,
				Thickness = 2
			}):Play()
			TweenService:Create(buyBtn, TweenInfo.new(0.12), {
				BackgroundColor3 = cardColor
			}):Play()
		end)
		card.MouseLeave:Connect(function()
			TweenService:Create(inner, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 1, 0)
			}):Play()
			TweenService:Create(cardStroke, TweenInfo.new(0.12), {
				Color = Color3.fromRGB(35, 38, 48),
				Thickness = 1.2
			}):Play()
			TweenService:Create(buyBtn, TweenInfo.new(0.12), {
				BackgroundColor3 = Color3.fromRGB(22, 23, 30)
			}):Play()
		end)

		-- Hook Purchase Event
		buyBtn.MouseButton1Click:Connect(function()
			-- Check coins
			if not self.CurrentData or self.CurrentData.Coins < crateData.Cost then
				buyBtn.Text = "Insufficient!"
				buyBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
				task.wait(1.5)
				buyBtn.Text = "Open"
				buyBtn.BackgroundColor3 = cardColor
				return
			end

			-- Play loading state
			buyBtn.Text = "Opening..."
			buyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			buyBtn.Active = false

			local success, result = self.OpenCrateFunction:InvokeServer(crateId)

			if success then
				-- Trigger dynamic character result modal unbox pop
				self:ShowUnboxPopup(result)
			else
				warn("Transaction Error:", result)
			end

			buyBtn.Text = "Open"
			buyBtn.BackgroundColor3 = cardColor
			buyBtn.Active = true
		end)
	end
end

function ShopController:ShowUnboxPopup(item)
	local rarityColor = RarityColors[item.Rarity] or Color3.fromRGB(255, 255, 255)

	-- 1. Result Popup Frame
	local pop = Instance.new("Frame")
	pop.Name = "UnboxResultPopup"
	pop.Size = UDim2.new(0, 230, 0, 300)
	pop.Position = UDim2.new(0.5, 0, 0.5, 0)
	pop.AnchorPoint = Vector2.new(0.5, 0.5)
	pop.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
	pop.ZIndex = 10 -- Render on top of ShopFrame and all other UI
	pop.Parent = self.MainUI

	local popCorner = Instance.new("UICorner")
	popCorner.CornerRadius = UDim.new(0, 10)
	popCorner.Parent = pop

	local popStroke = Instance.new("UIStroke")
	popStroke.Color = rarityColor
	popStroke.Thickness = 3
	popStroke.Parent = pop

	-- 2. Unlock Title
	local unlockTitle = Instance.new("TextLabel")
	unlockTitle.Size = UDim2.new(1, -20, 0, 30)
	unlockTitle.Position = UDim2.new(0, 10, 0, 15)
	unlockTitle.BackgroundTransparency = 1
	unlockTitle.Text = "NEW CHARACTER UNLOCKED!"
	unlockTitle.TextColor3 = Color3.fromRGB(255, 220, 80)
	unlockTitle.Font = Enum.Font.GothamBold
	unlockTitle.TextSize = 11
	unlockTitle.Parent = pop

	-- 3. Character Image
	local charImg = Instance.new("ImageLabel")
	charImg.Size = UDim2.new(0, 110, 0, 110)
	charImg.Position = UDim2.new(0.5, -55, 0, 55)
	charImg.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
	charImg.Image = item.Id
	charImg.ScaleType = Enum.ScaleType.Fit
	charImg.Parent = pop

	local imgCorner = Instance.new("UICorner")
	imgCorner.CornerRadius = UDim.new(0, 8)
	imgCorner.Parent = charImg

	-- 4. Character Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -20, 0, 25)
	nameLabel.Position = UDim2.new(0, 10, 0, 175)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 15
	nameLabel.Parent = pop

	-- 5. Rarity Text
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, -20, 0, 20)
	rarityLabel.Position = UDim2.new(0, 10, 0, 200)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = string.format("%s (x%d Multiplier)", item.Rarity:upper(), item.Multiplier)
	rarityLabel.TextColor3 = rarityColor
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextSize = 11
	rarityLabel.Parent = pop

	-- 6. Sound Effect
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://9086154641" -- standard unlock chime
	sound.Volume = 0.55
	sound.Parent = pop
	sound:Play()

	-- Dynamic entry animation
	pop.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(pop, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 230, 0, 300)
	}):Play()

	-- Auto fadeout and delete after 3 seconds
	task.delay(3, function()
		if not pop or not pop.Parent then return end
		
		local fade = TweenService:Create(pop, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		})
		
		-- Fade children recursively
		for _, child in ipairs(pop:GetChildren()) do
			if child:IsA("TextLabel") then
				TweenService:Create(child, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
			elseif child:IsA("ImageLabel") then
				TweenService:Create(child, TweenInfo.new(0.5), { ImageTransparency = 1, BackgroundTransparency = 1 }):Play()
			elseif child:IsA("UIStroke") then
				TweenService:Create(child, TweenInfo.new(0.5), { Transparency = 1 }):Play()
			end
		end

		fade.Completed:Connect(function()
			pop:Destroy()
		end)
		
		fade:Play()
	end)
end

return ShopController
