local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Constants = require(Shared.Constants)

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
end

function InventoryController:BuildUI()
	-- 1. Create the Inventory Open Button next to other buttons
	local inventoryButton = Instance.new("TextButton")
	inventoryButton.Name = "InventoryButton"
	inventoryButton.Size = UDim2.new(0, 130, 0, 45)
	-- Float above/left of standard bottom buttons
	inventoryButton.Position = UDim2.new(0, 20, 0.85, 0)
	inventoryButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	inventoryButton.Text = "💼 Inventory"
	inventoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	inventoryButton.Font = Enum.Font.GothamBold
	inventoryButton.TextSize = 16
	inventoryButton.Parent = self.MainUI

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = inventoryButton

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(65, 65, 80)
	btnStroke.Thickness = 1.5
	btnStroke.Parent = inventoryButton

	-- Button Hover Animations
	inventoryButton.MouseEnter:Connect(function()
		TweenService:Create(inventoryButton, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(50, 50, 65),
		}):Play()
		TweenService:Create(btnStroke, TweenInfo.new(0.15), {
			Color = Color3.fromRGB(100, 100, 130),
		}):Play()
	end)
	inventoryButton.MouseLeave:Connect(function()
		TweenService:Create(inventoryButton, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(35, 35, 45),
		}):Play()
		TweenService:Create(btnStroke, TweenInfo.new(0.15), {
			Color = Color3.fromRGB(65, 65, 80),
		}):Play()
	end)

	-- 2. Create main Inventory Frame
	local frame = Instance.new("Frame")
	frame.Name = "InventoryFrame"
	frame.Size = UDim2.new(0, 530, 0, 350)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	frame.BackgroundTransparency = 0.15
	frame.Visible = false
	frame.Parent = self.MainUI
	self.InventoryFrame = frame

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 12)
	frameCorner.Parent = frame

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Color3.fromRGB(55, 55, 70)
	frameStroke.Thickness = 2
	frameStroke.Parent = frame

	-- 3. Title Label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -60, 0, 40)
	titleLabel.Position = UDim2.new(0, 20, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "ANIME CHARACTERS"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 18
	titleLabel.Parent = frame

	-- 4. Close Button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -40, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 14
	closeButton.Parent = frame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		self:ToggleFrame(false)
	end)

	-- Open/Close toggle connection
	inventoryButton.MouseButton1Click:Connect(function()
		self:ToggleFrame(not frame.Visible)
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
	details.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	details.Parent = frame

	local detailsCorner = Instance.new("UICorner")
	detailsCorner.CornerRadius = UDim.new(0, 8)
	detailsCorner.Parent = details

	local detailsStroke = Instance.new("UIStroke")
	detailsStroke.Color = Color3.fromRGB(45, 45, 55)
	detailsStroke.Thickness = 1
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
	actionButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
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

	self.DetailPanel = {
		Frame = details,
		PreviewImage = previewImage,
		NameLabel = nameLabel,
		RarityLabel = rarityLabel,
		StatsLabel = statsLabel,
		PerkLabel = perkLabel,
		ActionButton = actionButton,
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
		-- Apply pop scale open animation
		self.InventoryFrame.Size = UDim2.new(0, 400, 0, 260)
		TweenService:Create(self.InventoryFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 530, 0, 350)
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
		slot.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		slot.BorderSizePixel = 0
		slot.Parent = self.GridScroll

		local slotCorner = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 6)
		slotCorner.Parent = slot

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
		slotStroke.Color = rarityColor
		slotStroke.Thickness = (equippedId == itemId) and 2.5 or 1.2
		slotStroke.Parent = slot

		-- Equipped badge / indicator
		if equippedId == itemId then
			local badge = Instance.new("Frame")
			badge.Name = "EquippedBadge"
			badge.Size = UDim2.new(0, 16, 0, 16)
			badge.Position = UDim2.new(0, 4, 0, 4)
			badge.BackgroundColor3 = Color3.fromRGB(0, 180, 50)
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
				Size = UDim2.new(1.1, 0, 1.1, 0),
			}):Play()
			TweenService:Create(slotStroke, TweenInfo.new(0.12), {
				Thickness = (equippedId == itemId) and 3.5 or 2.2,
			}):Play()
		end)
		inner.MouseLeave:Connect(function()
			TweenService:Create(inner, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 1, 0),
			}):Play()
			TweenService:Create(slotStroke, TweenInfo.new(0.12), {
				Thickness = (equippedId == itemId) and 2.5 or 1.2,
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

	if equippedId == itemId then
		if itemId == "rbxassetid://0000000" then
			-- Default item can't be unequipped since it's the baseline
			panel.ActionButton.Text = "Equipped"
			panel.ActionButton.BackgroundColor3 = Color3.fromRGB(45, 120, 60)
			panel.ActionButton.AutoButtonColor = false
		else
			panel.ActionButton.Text = "Unequip"
			panel.ActionButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
			panel.ActionButton.AutoButtonColor = true
		end
	else
		panel.ActionButton.Text = "Equip"
		panel.ActionButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		panel.ActionButton.AutoButtonColor = true
	end
end

return InventoryController
