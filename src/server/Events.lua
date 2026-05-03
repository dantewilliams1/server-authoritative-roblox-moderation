--[[
	Events.lua

	Handles admin RemoteFunction requests.
	Client sends requests, but the server validates and executes all actions.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(script.Parent:WaitForChild("Settings"))
local Functions = require(script.Parent:WaitForChild("Functions"))

local Events = {}

local AdminRemote = Instance.new("RemoteFunction")
AdminRemote.Name = "Admin"
AdminRemote.Parent = ReplicatedStorage

local VALID_OPTIONS = {
	Ban = true,
	Unban = true,
	Kick = true,
	ResetRecord = true,
	RequestAdminData = true,
}

local LastRequest = {}
local REQUEST_COOLDOWN = 1

local function isRateLimited(player)
	local now = os.clock()
	local last = LastRequest[player.UserId] or 0

	if now - last < REQUEST_COOLDOWN then
		return true
	end

	LastRequest[player.UserId] = now
	return false
end

local function resolveTarget(targetInput)
	if not targetInput or targetInput == "" then
		return nil, nil, "error: no target entered"
	end

	local targetId
	local targetName

	if tonumber(targetInput) then
		targetId = tonumber(targetInput)

		local success, result = pcall(function()
			return Players:GetNameFromUserIdAsync(targetId)
		end)

		if not success then
			return nil, nil, "error: invalid user id"
		end

		targetName = result
	else
		targetName = targetInput

		local success, result = pcall(function()
			return Players:GetUserIdFromNameAsync(targetName)
		end)

		if not success then
			return nil, nil, "error: username not found"
		end

		targetId = result
	end

	return targetName, targetId, nil
end

function AdminRemote.OnServerInvoke(sender, arguments)
	if typeof(arguments) ~= "table" then
		sender:Kick("Invalid admin request.")
		return nil
	end

	if isRateLimited(sender) then
		return "error: slow down before sending another request"
	end

	local option = arguments.Option
	local reason = arguments.Reason or "No reason provided"
	local duration = arguments.Duration
	local targetInput = arguments.Name

	if not VALID_OPTIONS[option] then
		return "error: invalid admin option"
	end

	local moderatorName = sender.Name
	local moderatorId = sender.UserId

	local targetName, targetId, resolveError = resolveTarget(targetInput)

	if resolveError then
		return resolveError
	end

	if not Functions:IsAdmin(sender) then
		Functions:BanPlayer(
			sender.Name,
			sender.UserId,
			"System",
			"Unauthorized admin remote request",
			"Permanent",
			os.time()
		)

		return sender:Kick("Unauthorized admin request.")
	end

	local targetIsAdmin = Settings.Staff.Administrators[targetId] ~= nil
	local senderIsDeveloper = Settings.Staff.Developers[moderatorId] ~= nil

	if targetIsAdmin and not senderIsDeveloper and option ~= "Unban" then
		return "error: your rank is not high enough to moderate this user"
	end

	if option == "Ban" then
		return Functions:BanPlayer(targetName, targetId, moderatorName, reason, duration, os.time())

	elseif option == "Unban" then
		return Functions:UnbanPlayer(targetName, targetId, moderatorName)

	elseif option == "Kick" then
		return Functions:RemovePlayer(targetName)

	elseif option == "ResetRecord" then
		return Functions:ResetPlayerData(moderatorName, targetName, targetId)

	elseif option == "RequestAdminData" then
		return Functions:RequestAdminData(moderatorName, targetName, targetId)
	end
end

return Events
