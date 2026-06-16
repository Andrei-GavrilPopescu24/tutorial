local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Constants = require(Shared.Constants)
local UIController = require(script.Parent:WaitForChild("UIController"))

local InventoryController = {
	SelectedItemId = nil,
	CurrentData = nil,
}

local RarityColors = {
	["Common"] = Color3.fromRGB(140, 140, 140),
	["Rare"] = Color3.fromRGB(0, 150, 255),
	["Epic"] = Color3.fromRGB(160, 0, 255),
	["Legendary"] = Color3.fromRGB(255, 150, 0),
}

function InventoryController:Init()
	self.DataUpdateEvent = ReplicatedStorage:WaitForChild("DataUpdateEvent")
	self.EquipItemFunction = ReplicatedStorage:WaitForChild("EquipItemFunction")
	self.PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function InventoryController:Start()
	self.MainUI = self.PlayerGui:WaitForChild("MainUI")
	
	self:BuildUI()
	
	self.DataUpdateEvent.OnClientEvent:Connect(function(data)
		self.CurrentData = data
		if self.InventoryFrame.Visible then
			self:RefreshGrid()
		end
	end)

	-- Request initial data on startup
	local requestFunc = ReplicatedStorage:WaitForChild("RequestDataFunction")
	task.spawn(function()
		local initialData = requestFunc:InvokeServer()
		if initialData then
			self.CurrentData = initialData
			if self.InventoryFrame.Visible then
				self:RefreshGrid()
			end
		end
	end)
end

function InventoryController:BuildUI()
	local menuBar = self.MainUI:WaitForChild("MenuBar")

	-- 1. Create the Inventory Open Button inside bottom MenuBar
	local inventoryButton = Instance.new("TextButton")
	inventoryButton.Name = "InventoryButton"
	inventoryButton.Size = UDim2.new(0, 110, 0, 42)
	inventoryButton.BackgroundColor3 = Color3.fromRGB(10, 25, 35) -- Dark steel blue
	inventoryButton.Text = "💼 ARCHIVE.SYS"
	inventoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	inventoryButton.Font = Enum.Font.GothamBold
	inventoryButton.TextSize = 11
	inventoryButton.LayoutOrder = 2
	inventoryButton.Parent = menuBar

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = inventoryButton

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(0, 150, 255) -- neon blue
	btnStroke.Thickness = 1.2
	btnStroke.Parent = inventoryButton

	-- Button Hover Animations
	inventoryButton.MouseEnter:Connect(function()
		TweenService:Create(inventoryButton, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(15, 40, 55),
		}):Play()
		TweenService:Create(btnStroke, TweenInfo.new(0.15), {
			Thickness = 2,
		}):Play()
	end)
	inventoryButton.MouseLeave:Connect(function()
		TweenService:Create(inventoryButton, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(10, 25, 35),
		}):Play()
		TweenService:Create(btnStroke, TweenInfo.new(0.15), {
			Thickness = 1.2,
		}):Play()
	end)

	-- Open/Close toggle connection
	inventoryButton.MouseButton1Click:Connect(function()
		self:ToggleFrame(not self.InventoryFrame.Visible)
	end)

	-- 2. Create main Inventory Frame
	local frame = Instance.new("Frame")
	frame.Name = "InventoryFrame"
	frame.Size = UDim2.new(0, 520, 0, 350)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(12, 13, 20) -- Dark Slate Navy
	frame.BackgroundTransparency = 0.15
	frame.Visible = false
	frame.ZIndex = 5 -- Render on top of HUD click button / stats
	frame.Parent = self.MainUI
	self.InventoryFrame = frame

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 12)
	frameCorner.Parent = frame

	-- Apply glowing border and corners using UIController
	UIController:ApplyGlowingBorder(frame, Color3.fromRGB(0, 240, 255), Color3.fromRGB(180, 0, 255), 1.8)
	UIController:AddTechCorners(frame, Color3.fromRGB(0, 240, 255))

	-- 3. Title Label & Subtitle
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -60, 0, 25)
	titleLabel.Position = UDim2.new(0, 20, 0, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "// DATA ARCHIVE"
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
	subtitleLabel.Text = "ACTIVE DIAGNOSTICS // EQUIPPED MODULES INVENTORY"
	subtitleLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
	subtitleLabel.TextTransparency = 0.5
	subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	subtitleLabel.Font = Enum.Font.RobotoMono
	subtitleLabel.TextSize = 8
	subtitleLabel.Parent = frame

	-- 4. Close Button
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
		self:ToggleFrame(false)
	end)

	-- 5. Left Side: Grid Scrolling Frame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "GridScroll"
	scroll.Size = UDim2.new(0.6, -15, 0.8, -10)
	scroll.Position = UDim2.new(0, 15, 0.18, 0)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
	scroll.Parent = frame
	self.GridScroll = scroll

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 74, 0, 74)
	gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = scroll

	-- 6. Right Side: Detail Panel
	local details = Instance.new("Frame")
	details.Name = "DetailPanel"
	details.Size = UDim2.new(0.4, -20, 0.8, -10)
	details.Position = UDim2.new(0.6, 5, 0.18, 0)
	details.BackgroundColor3 = Color3.fromRGB(16, 17, 24)
	details.Parent = frame

	local detailsCorner = Instance.new("UICorner")
	detailsCorner.CornerRadius = UDim.new(0, 8)
	detailsCorner.Parent = details

	local detailsStroke = Instance.new("UIStroke")
	detailsStroke.Color = Color3.fromRGB(0, 240, 255) -- Cyan outline
	detailsStroke.Thickness = 1.2
	detailsStroke.Parent = details

	-- Detail Components
	local previewImage = Instance.new("ImageLabel")
	previewImage.Name = "PreviewImage"
	previewImage.Size = UDim2.new(0, 80, 0, 80)
	previewImage.Position = UDim2.new(0.5, -40, 0, 15)
	previewImage.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	previewImage.Parent = details

	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0, 8)
	previewCorner.Parent = previewImage

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -20, 0, 25)
	nameLabel.Position = UDim2.new(0, 10, 0, 105)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Select an Item"
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.Parent = details

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, -20, 0, 15)
	rarityLabel.Position = UDim2.new(0, 10, 0, 130)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = ""
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextSize = 12
	rarityLabel.Parent = details

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "StatsLabel"
	statsLabel.Size = UDim2.new(1, -20, 0, 20)
	statsLabel.Position = UDim2.new(0, 10, 0, 150)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = ""
	statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextSize = 13
	statsLabel.Parent = details

	local perkLabel = Instance.new("TextLabel")
	perkLabel.Name = "PerkLabel"
	perkLabel.Size = UDim2.new(1, -20, 0, 50)
	perkLabel.Position = UDim2.new(0, 10, 0, 175)
	perkLabel.BackgroundTransparency = 1
	perkLabel.Text = ""
	perkLabel.TextColor3 = Color3.fromRGB(160, 160, 175)
	perkLabel.Font = Enum.Font.Gotham
	perkLabel.TextSize = 11
	perkLabel.TextWrapped = true
	perkLabel.TextYAlignment = Enum.TextYAlignment.Top
	perkLabel.Parent = details

	local actionButton = Instance.new("TextButton")
	actionButton.Name = "ActionButton"
	actionButton.Size = UDim2.new(1, -30, 0, 35)
	actionButton.Position = UDim2.new(0, 15, 1, -45)
	actionButton.BackgroundColor3 = Color3.fromRGB(10, 25, 40)
	actionButton.Text = "Equip"
	actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	actionButton.Font = Enum.Font.GothamBold
	actionButton.TextSize = 13
	actionButton.Visible = false
	actionButton.Parent = details
	self.ActionButton = actionButton

	local actionCorner = Instance.new("UICorner")
	actionCorner.CornerRadius = UDim.new(0, 6)
	actionCorner.Parent = actionButton

	local actionStroke = Instance.new("UIStroke")
	actionStroke.Color = Color3.fromRGB(0, 150, 255)
	actionStroke.Thickness = 1.2
	actionStroke.Parent = actionButton

	self.DetailPanel = {
		Frame = details,
		PreviewImage = previewImage,
		NameLabel = nameLabel,
		RarityLabel = rarityLabel,
		StatsLabel = statsLabel,
		PerkLabel = perkLabel,
		ActionButton = actionButton,
		ActionStroke = actionStroke,
	}

	-- Action Button Event
	actionButton.MouseButton1Click:Connect(function()
		if not self.SelectedItemId then return end
		
		local targetAction = actionButton.Text
		local success, result
		
		if targetAction == "Equip" then
			success, result = self.EquipItemFunction:InvokeServer(self.SelectedItemId)
		elseif targetAction == "Unequip" then
			-- Unequipping sets back to default novice clicker item
			success, result = self.EquipItemFunction:InvokeServer("rbxassetid://0000000")
		end
		
		if success then
			print("Equip updated successfully for ID:", result)
			if self.CurrentData then
				self.CurrentData.EquippedImage = result
				self:RefreshGrid()
				self:SelectGridItem(self.SelectedItemId)
			end
		else
			warn("Equip failed:", result)
		end
	end)
end

function InventoryController:ToggleFrame(visible)
	self.InventoryFrame.Visible = visible
	if visible then
		-- Close Shop frame if open to prevent menu overlap
		local shopFrame = self.MainUI:FindFirstChild("ShopFrame")
		if shopFrame then
			shopFrame.Visible = false
		end

		-- Apply pop scale open animation
		self.InventoryFrame.Size = UDim2.new(0, 400, 0, 260)
		TweenService:Create(self.InventoryFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 520, 0, 350)
		}):Play()

		self:RefreshGrid()
	end
end

function InventoryController:RefreshGrid()
	-- Clear grid scroll contents except grid layout
	for _, child in ipairs(self.GridScroll:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	if not self.CurrentData then return end

	local equippedId = self.CurrentData.EquippedImage or "rbxassetid://0000000"
	
	-- Keep track if selected item is still owned
	local stillOwnsSelected = false

	-- Compile list of owned items (always include default, and anything in inventory with count > 0)
	local owned = {}
	for itemId, details in pairs(Constants.ITEMS) do
		local quantity = self.CurrentData.Inventory[itemId] or 0
		if itemId == "rbxassetid://0000000" then
			quantity = 1 -- baseline item is always owned
		end

		if quantity > 0 then
			table.insert(owned, {
				Id = itemId,
				Quantity = quantity,
				Details = details,
			})
			if itemId == self.SelectedItemId then
				stillOwnsSelected = true
			end
		end
	end

	-- Sort items by rarity multiplier (descending) then name
	table.sort(owned, function(a, b)
		if a.Details.Multiplier ~= b.Details.Multiplier then
			return a.Details.Multiplier > b.Details.Multiplier
		end
		return a.Details.Name < b.Details.Name
	end)

	-- Populate Slots
	for _, item in ipairs(owned) do
		local itemId = item.Id
		local quantity = item.Quantity
		local details = item.Details
		local rarityColor = RarityColors[details.Rarity] or Color3.fromRGB(255, 255, 255)

		local slot = Instance.new("Frame")
		slot.Name = "ItemSlot_" .. details.Name
		slot.BackgroundColor3 = Color3.fromRGB(16, 17, 24)
		slot.BackgroundTransparency = 0.2
		slot.BorderSizePixel = 0
		slot.Parent = self.GridScroll

		local slotCorner = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 6)
		slotCorner.Parent = slot

		-- Top Rarity Stripe Accent
		local accentBar = Instance.new("Frame")
		accentBar.Name = "AccentBar"
		accentBar.Size = UDim2.new(1, 0, 0, 3)
		accentBar.Position = UDim2.new(0, 0, 0, 0)
		accentBar.BackgroundColor3 = rarityColor
		accentBar.BorderSizePixel = 0
		accentBar.Parent = slot

		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(0, 3)
		accentCorner.Parent = accentBar

		-- Inner frame for scaling animation inside UIGridLayout
		local inner = Instance.new("ImageButton")
		inner.Name = "Inner"
		inner.Size = UDim2.new(1, 0, 1, 0)
		inner.Position = UDim2.new(0.5, 0, 0.5, 0)
		inner.AnchorPoint = Vector2.new(0.5, 0.5)
		inner.BackgroundTransparency = 1
		inner.Image = itemId
		inner.Parent = slot

		local innerCorner = Instance.new("UICorner")
		innerCorner.CornerRadius = UDim.new(0, 6)
		innerCorner.Parent = inner

		local slotStroke = Instance.new("UIStroke")
		slotStroke.Color = (equippedId == itemId) and rarityColor or Color3.fromRGB(35, 38, 48)
		slotStroke.Thickness = (equippedId == itemId) and 2 or 1.2
		slotStroke.Parent = slot

		-- Equipped badge / indicator
		if equippedId == itemId then
			local badge = Instance.new("Frame")
			badge.Name = "EquippedBadge"
			badge.Size = UDim2.new(0, 16, 0, 16)
			badge.Position = UDim2.new(0, 4, 0, 4)
			badge.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
			badge.Parent = inner

			local badgeCorner = Instance.new("UICorner")
			badgeCorner.CornerRadius = UDim.new(1, 0)
			badgeCorner.Parent = badge

			local badgeText = Instance.new("TextLabel")
			badgeText.Size = UDim2.new(1, 0, 1, 0)
			badgeText.BackgroundTransparency = 1
			badgeText.Text = "✔"
			badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
			badgeText.TextSize = 10
			badgeText.Font = Enum.Font.GothamBold
			badgeText.Parent = badge
		end

		-- Quantity Label
		if quantity > 1 then
			local qty = Instance.new("TextLabel")
			qty.Name = "QuantityLabel"
			qty.Size = UDim2.new(0, 24, 0, 16)
			qty.Position = UDim2.new(1, -26, 1, -18)
			qty.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
			qty.BackgroundTransparency = 0.2
			qty.Text = "x" .. tostring(quantity)
			qty.TextColor3 = Color3.fromRGB(255, 255, 255)
			qty.Font = Enum.Font.GothamBold
			qty.TextSize = 10
			qty.Parent = inner

			local qtyCorner = Instance.new("UICorner")
			qtyCorner.CornerRadius = UDim.new(0, 4)
			qtyCorner.Parent = qty
		end

		-- Micro-animations for Hover
		inner.MouseEnter:Connect(function()
			TweenService:Create(inner, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1.04, 0, 1.04, 0),
			}):Play()
			TweenService:Create(slotStroke, TweenInfo.new(0.12), {
				Color = rarityColor,
				Thickness = 2,
			}):Play()
		end)
		inner.MouseLeave:Connect(function()
			TweenService:Create(inner, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 1, 0),
			}):Play()
			TweenService:Create(slotStroke, TweenInfo.new(0.12), {
				Color = (equippedId == itemId) and rarityColor or Color3.fromRGB(35, 38, 48),
				Thickness = (equippedId == itemId) and 2 or 1.2,
			}):Play()
		end)

		inner.MouseButton1Click:Connect(function()
			self:SelectGridItem(itemId)
		end)
	end

	-- Auto select equipped or first item if nothing selected
	if not stillOwnsSelected then
		self:SelectGridItem(equippedId)
	else
		self:SelectGridItem(self.SelectedItemId)
	end
end

function InventoryController:SelectGridItem(itemId)
	self.SelectedItemId = itemId
	local details = Constants.ITEMS[itemId]
	if not details then return end

	local panel = self.DetailPanel
	panel.PreviewImage.Image = itemId
	panel.NameLabel.Text = details.Name
	panel.RarityLabel.Text = string.upper(details.Rarity)
	panel.RarityLabel.TextColor3 = RarityColors[details.Rarity] or Color3.fromRGB(255, 255, 255)
	panel.StatsLabel.Text = string.format("Multiplier: x%d", details.Multiplier)
	panel.PerkLabel.Text = string.format("Perk: %s\n%s", details.PerkName, details.PerkDesc)

	panel.ActionButton.Visible = true

	local equippedId = self.CurrentData and self.CurrentData.EquippedImage or "rbxassetid://0000000"
	local actionStroke = panel.ActionStroke

	if equippedId == itemId then
		if itemId == "rbxassetid://0000000" then
			panel.ActionButton.Text = "EQUIPPED"
			panel.ActionButton.BackgroundColor3 = Color3.fromRGB(10, 35, 20)
			if actionStroke then
				actionStroke.Color = Color3.fromRGB(0, 220, 80)
			end
			panel.ActionButton.AutoButtonColor = false
		else
			panel.ActionButton.Text = "UNEQUIP"
			panel.ActionButton.BackgroundColor3 = Color3.fromRGB(35, 10, 15)
			if actionStroke then
				actionStroke.Color = Color3.fromRGB(200, 50, 50)
			end
			panel.ActionButton.AutoButtonColor = true
		end
	else
		panel.ActionButton.Text = "EQUIP"
		panel.ActionButton.BackgroundColor3 = Color3.fromRGB(10, 25, 40)
		if actionStroke then
			actionStroke.Color = Color3.fromRGB(0, 150, 255)
		end
		panel.ActionButton.AutoButtonColor = true
	end
end

return InventoryController
