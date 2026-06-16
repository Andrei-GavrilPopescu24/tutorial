local Constants = {
	MAX_CLICKS_PER_SECOND = 15,
	BASE_CLICK_YIELD = 1,
	BASE_REBIRTH_COST = 100,
	REBIRTH_COST_SCALING = 1.5,

	BGM_ID = "rbxassetid://1837849285",

	SHOP_REFRESH_INTERVAL = 60, -- Seconds
	SHOP_SLOT_COUNT = 3,

	ITEMS = {
		["rbxassetid://0000000"] = {
			Name = "Novice Clicker",
			Rarity = "Common",
			Multiplier = 1,
			PerkName = "None",
			PerkDesc = "No special perk.",
		},
		["rbxassetid://1111111"] = {
			Name = "Goku (SSJ)",
			Rarity = "Common",
			Multiplier = 1,
			PerkName = "Z-Fighter",
			PerkDesc = "10% chance of double click yield.",
		},
		["rbxassetid://2222222"] = {
			Name = "Naruto (Sage)",
			Rarity = "Rare",
			Multiplier = 2,
			PerkName = "Shadow Clone",
			PerkDesc = "15% chance of triple click yield.",
		},
		["rbxassetid://3333333"] = {
			Name = "Luffy (Gear 4)",
			Rarity = "Epic",
			Multiplier = 5,
			PerkName = "Gear Second",
			PerkDesc = "20% chance of quadruple click yield.",
		},
		["rbxassetid://4444444"] = {
			Name = "Ichigo (Bankai)",
			Rarity = "Legendary",
			Multiplier = 15,
			PerkName = "Hollowification",
			PerkDesc = "10% chance of 10x click yield.",
		},
	},

	CRATES = {
		["StandardCrate"] = {
			Cost = 500,
			Rarity = "Common",
			LootTable = {
				{ Id = "rbxassetid://1111111", Weight = 80 },
				{ Id = "rbxassetid://2222222", Weight = 20 },
			},
		},
		["PremiumCrate"] = {
			Cost = 2500,
			Rarity = "Rare",
			LootTable = {
				{ Id = "rbxassetid://2222222", Weight = 70 },
				{ Id = "rbxassetid://3333333", Weight = 30 },
			},
		},
		["MythicCrate"] = {
			Cost = 10000,
			Rarity = "Legendary",
			LootTable = {
				{ Id = "rbxassetid://3333333", Weight = 90 },
				{ Id = "rbxassetid://4444444", Weight = 10 },
			},
		},
	},
}

return Constants

