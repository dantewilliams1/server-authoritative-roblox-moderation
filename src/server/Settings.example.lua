--[[
	Settings.example.lua

	Example configuration file.
	Do not upload real webhook URLs or private production settings.
]]

local DataStoreService = game:GetService("DataStoreService")

local Settings = {
	Group = {
		ID = 00000000,
		Developer = 252,
		Administrator = 250,
	},

	DataStores = {
		Record = DataStoreService:GetDataStore("Records-Example"),
		ParkStreak = DataStoreService:GetOrderedDataStore("Streaks-Example"),
		ParkLeaderboard = DataStoreService:GetOrderedDataStore("Leaderboard-Example"),
		Punish = DataStoreService:GetDataStore("Punish-Example"),
	},

	Staff = {
		Developers = {
			[123456789] = {"DeveloperUsername"},
		},

		Administrators = {
			[123456789] = {"AdminUsername"},
		},
	},

	ManualBans = {},

	Channels = {
		Ban = "YOUR_BAN_WEBHOOK_URL",
		Unban = "YOUR_UNBAN_WEBHOOK_URL",
		Records = "YOUR_RECORDS_WEBHOOK_URL",
		DataRequest = "YOUR_DATA_REQUEST_WEBHOOK_URL",
	},
}

return Settings
