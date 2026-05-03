--[[
	Functions.lua

	Core moderation logic:
	- bans
	- unbans
	- player removal
	- data resets
	- admin data requests
	- Discord audit logging
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")

local Handler = script.Parent.Parent
local Settings = require(script.Parent:WaitForChild("Settings"))

local AdminFunctions = {}

local function safeSetAsync(dataStore, key, value, attempts)
	attempts = attempts or 3

	for attempt = 1, attempts do
		local success = pcall(function()
			dataStore:SetAsync(key, value)
		end)

		if success then
			return true
		end

		task.wait(0.5)
	end

	return false
end

local function safeGetAsync(dataStore, key, attempts)
	attempts = attempts or 3

	for attempt = 1, attempts do
		local success, result = pcall(function()
			return dataStore:GetAsync(key)
		end)

		if success then
			return result
		end

		task.wait(0.5)
	end

	return nil
end

function AdminFunctions:ConvertSecondsToTime(seconds)
	seconds = tonumber(seconds)

	if not seconds then
		return "unknown"
	end

	local minutes = math.floor(seconds / 60)
	seconds = seconds % 60

	local hours = math.floor(minutes / 60)
	minutes = minutes % 60

	local days = math.floor(hours / 24)
	hours = hours % 24

	local months = math.floor(days / 30)
	days = days % 30

	local years = math.floor(months / 12)
	months = months % 12

	if years > 0 then
		return years == 1 and "1 yr" or years .. " yrs"
	elseif months > 0 then
		return months .. " mo"
	elseif days > 0 then
		return days .. " d"
	elseif hours > 0 then
		return hours == 1 and "1 hr" or hours .. " hrs"
	elseif minutes > 0 then
		return minutes .. " min"
	else
		return seconds .. " sec"
	end
end

function AdminFunctions:IsPermanentBan(duration)
	return typeof(duration) == "string" and string.find(string.lower(duration), "perm") ~= nil
end

function AdminFunctions:IsTemporaryBan(duration)
	return typeof(duration) == "number" or tonumber(duration) ~= nil
end

function AdminFunctions:BanPlayer(targetName, targetId, moderator, reason, duration, currentTime)
	if not targetName or not targetId then
		return "error: missing target data"
	end

	reason = reason or "No reason provided"

	local banData = {
		Banned = true,
		Reason = reason,
		Moderator = moderator,
		Duration = duration,
		TimeOfBan = currentTime,
	}

	local success = safeSetAsync(Settings.DataStores.Punish, targetId, banData)

	if not success then
		return string.format("error: failed to ban %s", targetName)
	end

	task.spawn(function()
		if self:IsPermanentBan(duration) then
			self:DiscordLog(
				string.format(
					"%s banned [ %s | %s ] [ %s ] | Permanently",
					moderator,
					targetName,
					targetId,
					reason
				),
				"Ban"
			)
		elseif self:IsTemporaryBan(duration) then
			self:DiscordLog(
				string.format(
					"%s banned [ %s | %s ] [ %s ] | %s",
					moderator,
					targetName,
					targetId,
					reason,
					self:ConvertSecondsToTime(duration)
				),
				"Ban"
			)
		end

		pcall(function()
			MessagingService:PublishAsync("REMOVE_PLAYER", {
				Target = targetName,
			})
		end)
	end)

	if self:IsPermanentBan(duration) then
		return string.format("you banned %s | %s | permanent", targetName, targetId)
	end

	return string.format(
		"you banned %s | %s | %s",
		targetName,
		targetId,
		self:ConvertSecondsToTime(duration)
	)
end

function AdminFunctions:UnbanPlayer(targetName, targetId, moderator)
	local banData = safeGetAsync(Settings.DataStores.Punish, targetId)

	if not banData then
		return string.format("user not found in punishment database: %s | %s", targetName, targetId)
	end

	banData.Banned = false

	local success = safeSetAsync(Settings.DataStores.Punish, targetId, banData)

	if not success then
		return string.format("error: failed to unban %s", targetName)
	end

	task.spawn(function()
		self:DiscordLog(
			string.format("%s unbanned [ %s | %s ]", moderator, targetName, targetId),
			"Unban"
		)
	end)

	return string.format("you unbanned %s | %s", targetName, targetId)
end

function AdminFunctions:RemovePlayer(targetName)
	local success = pcall(function()
		MessagingService:PublishAsync("REMOVE_PLAYER", {
			Target = targetName,
		})
	end)

	if success then
		return string.format("you kicked %s", targetName)
	end

	return string.format("error: failed to kick %s", targetName)
end

function AdminFunctions:ResetPlayerData(moderator, targetName, targetId)
	self:RemovePlayer(targetName)

	task.wait(1.5)

	local recordData = safeGetAsync(Settings.DataStores.Record, targetId)
	local streakData = safeGetAsync(Settings.DataStores.ParkStreak, targetId)
	local leaderboardData = safeGetAsync(Settings.DataStores.ParkLeaderboard, targetId)

	if not recordData or streakData == nil or leaderboardData == nil then
		return "no data found for user"
	end

	local previousWins = recordData.Wins or 0
	local previousLosses = recordData.Losses or 0
	local previousStreak = streakData or 0

	local recordSuccess = safeSetAsync(Settings.DataStores.Record, targetId, {
		Wins = 0,
		Losses = 0,
	})

	local streakSuccess = safeSetAsync(Settings.DataStores.ParkStreak, targetId, 0)
	local leaderboardSuccess = safeSetAsync(Settings.DataStores.ParkLeaderboard, targetId, 0)

	if recordSuccess and streakSuccess and leaderboardSuccess then
		self:DiscordLog(
			string.format(
				"%s reset park data for [ %s | %s ]\nPrevious Data: [Wins: %s | Losses: %s | Streak: %s]",
				moderator,
				targetName,
				targetId,
				previousWins,
				previousLosses,
				previousStreak
			),
			"Records"
		)

		return string.format(
			"successfully wiped park data for %s | %s [Previously: %s Wins | %s Losses | %s Streak]",
			targetName,
			targetId,
			previousWins,
			previousLosses,
			previousStreak
		)
	end

	return string.format("unable to wipe park data for %s | %s", targetName, targetId)
end

function AdminFunctions:RequestAdminData(moderator, targetName, targetId)
	local recordData = safeGetAsync(Settings.DataStores.Record, targetId)
	local streakData = safeGetAsync(Settings.DataStores.ParkStreak, targetId)
	local adminData = safeGetAsync(Settings.DataStores.Punish, targetId)

	local adminString = "no moderator actions | "
	local recordString = "no record data"

	if adminData then
		local currentStatus = adminData.Banned and "banned" or "unbanned"

		if self:IsPermanentBan(adminData.Duration) then
			adminString = string.format(
				"previous status: banned | reason: %s | by: %s | duration: permanent | current status: %s | ",
				adminData.Reason,
				adminData.Moderator,
				currentStatus
			)
		elseif self:IsTemporaryBan(adminData.Duration) then
			adminString = string.format(
				"previous status: banned | reason: %s | by: %s | duration: %s | current status: %s | ",
				adminData.Reason,
				adminData.Moderator,
				self:ConvertSecondsToTime(adminData.Duration),
				currentStatus
			)
		end
	end

	if recordData or streakData then
		local wins = recordData and recordData.Wins or 0
		local losses = recordData and recordData.Losses or 0
		local streak = streakData or 0

		recordString = string.format(
			"park | [Wins: %s | Losses: %s | Streak: %s]",
			wins,
			losses,
			streak
		)
	end

	self:DiscordLog(
		string.format(
			"%s requested data on %s\n%s\n%s",
			moderator,
			targetName,
			adminString,
			recordString
		),
		"DataRequest"
	)

	return adminString .. recordString
end

function AdminFunctions:IsAdmin(player)
	return player:GetRankInGroup(Settings.Group.ID) >= Settings.Group.Administrator
end

function AdminFunctions:IsDev(player)
	return player:GetRankInGroup(Settings.Group.ID) >= Settings.Group.Developer
end

function AdminFunctions:PlayerAdded(player)
	player.CharacterAdded:Connect(function()
		if self:IsAdmin(player) then
			local clientAdmin = Handler:WaitForChild("Client_Admin"):Clone()
			clientAdmin.Parent = player:WaitForChild("PlayerGui")
			clientAdmin.Disabled = false
		end
	end)

	if Settings.ManualBans[player.UserId] then
		player:Kick("You have been removed from this experience.")
		return
	end

	local punishData = safeGetAsync(Settings.DataStores.Punish, player.UserId)

	if not punishData or not punishData.Banned then
		return
	end

	local reason = punishData.Reason or "No reason provided"
	local moderator = punishData.Moderator or "System"
	local duration = punishData.Duration
	local timeOfBan = punishData.TimeOfBan or os.time()

	if self:IsPermanentBan(duration) then
		player:Kick(
			string.format(
				"Banned. | Reason: %s | By: %s | Permanently",
				reason,
				moderator
			)
		)
		return
	end

	if self:IsTemporaryBan(duration) then
		local currentTime = os.time()
		local elapsedTime = currentTime - timeOfBan
		local remainingTime = tonumber(duration) - elapsedTime

		if remainingTime > 0 then
			player:Kick(
				string.format(
					"Banned. | Reason: %s | By: %s | Time Left: %s",
					reason,
					moderator,
					self:ConvertSecondsToTime(remainingTime)
				)
			)
		else
			punishData.Banned = false
			safeSetAsync(Settings.DataStores.Punish, player.UserId, punishData)
		end
	end
end

function AdminFunctions:DiscordLog(message, channelName)
	local webhookUrl = Settings.Channels[channelName]

	if not webhookUrl or webhookUrl == "" or string.find(webhookUrl, "YOUR_") then
		return false
	end

	local payload = {
		embeds = {
			{
				description = message,
			},
		},
	}

	local success = pcall(function()
		local encodedPayload = HttpService:JSONEncode(payload)
		HttpService:PostAsync(webhookUrl, encodedPayload)
	end)

	return success
end

return AdminFunctions
