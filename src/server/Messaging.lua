--[[
	Messaging.lua

	Handles cross-server player removal through Roblox MessagingService.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MessagingService = game:GetService("MessagingService")

local MessagingModule = {}

if not RunService:IsStudio() then
	pcall(function()
		MessagingService:SubscribeAsync("REMOVE_PLAYER", function(message)
			local data = message.Data

			if typeof(data) ~= "table" then
				return
			end

			local targetName = data.Target

			if not targetName then
				return
			end

			local targetPlayer = Players:FindFirstChild(targetName)

			if targetPlayer then
				targetPlayer:Kick("You have been removed from this experience.")
			end
		end)
	end)
end

return MessagingModule
