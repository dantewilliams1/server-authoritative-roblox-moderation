--[[
	Server-Authoritative Moderation System
	Main server handler.

	Loads admin modules and connects player initialization logic.
]]

local Players = game:GetService("Players")

local Modules = script:WaitForChild("Modules")

local Events = require(Modules:WaitForChild("Events"))
local Functions = require(Modules:WaitForChild("Functions"))
local Messaging = require(Modules:WaitForChild("Messaging"))

Players.PlayerAdded:Connect(function(player)
	Functions:PlayerAdded(player)
end)
