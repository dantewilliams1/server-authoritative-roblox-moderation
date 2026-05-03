--[[
	ClientAdmin.client.lua

	Client-side admin panel controller.
	The client only submits requests. The server validates and executes all moderation actions.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local AdminRemote = ReplicatedStorage:WaitForChild("Admin")
local AdminUI = script:WaitForChild("AdminUI")

local DraggableObject = require(script:WaitForChild("DraggableObject"))

local debounce = false

local MainFrame = AdminUI:WaitForChild("modUI")
local TextBoxFrame = MainFrame.mainBG.textBoxes
local ButtonFrame = MainFrame.mainBG.mainButtons
local Description = MainFrame.notice.info

local PlayerTextBox = TextBoxFrame.playerBox.nameBox
local ReasonTextBox = TextBoxFrame.reasonBox.nameBox
local DurationTextBox = TextBoxFrame.secondsBox.nameBox

local frameDrag = DraggableObject.new(MainFrame)
frameDrag:Enable()

local function setDescription(text)
	Description.Text = text or ""
end

local function sendAdminRequest(payload)
	if debounce then
		return
	end

	debounce = true
	setDescription("")

	local success, response = pcall(function()
		return AdminRemote:InvokeServer(payload)
	end)

	if success then
		setDescription(response)
	else
		setDescription("error: request failed")
	end

	task.delay(0.5, function()
		debounce = false
	end)
end

local ButtonActions = {
	banPerm = function()
		sendAdminRequest({
			Name = PlayerTextBox.Text,
			Reason = ReasonTextBox.Text,
			Duration = "Permanent",
			Option = "Ban",
		})
	end,

	banTemp = function()
		sendAdminRequest({
			Name = PlayerTextBox.Text,
			Reason = ReasonTextBox.Text,
			Duration = tonumber(DurationTextBox.Text),
			Option = "Ban",
		})
	end,

	unban = function()
		sendAdminRequest({
			Name = PlayerTextBox.Text,
			Option = "Unban",
		})
	end,

	kick = function()
		sendAdminRequest({
			Name = PlayerTextBox.Text,
			Option = "Kick",
		})
	end,

	dataReq = function()
		sendAdminRequest({
			Name = PlayerTextBox.Text,
			Option = "RequestAdminData",
		})
	end,

	resetRecord = function()
		sendAdminRequest({
			Name = PlayerTextBox.Text,
			Option = "ResetRecord",
		})
	end,
}

for _, button in ipairs(ButtonFrame:GetChildren()) do
	if button:IsA("GuiButton") and ButtonActions[button.Name] then
		button.MouseButton1Click:Connect(ButtonActions[button.Name])
	end
end
