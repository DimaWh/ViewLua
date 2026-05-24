--[[
  Severe Player View — spectate via CameraSubject (stable on external)

  HUD list (green text, no extra GUI):
    V      — view selected player (V again to stop)
    P      — previous player in list
    ;      — next player in list
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local COOLDOWN = 0.25
local LIST_REFRESH = 0.5
local MAX_SHOWN = 12
local LINE_H = 15
local HUD_X, HUD_Y = 12, 56

local viewing = false
local viewTarget = nil
local savedSubject = nil
local playerList = {}
local selected = 1
local listScroll = 0
local lastRefresh = 0
local lastToggle = 0

local keyPrev = { v = false, p = false, down = false }

local hudHeader = nil
local hudRows = {}
local hudFooter = nil

local function notify(msg)
	print("[View] " .. tostring(msg))
	if type(send_notification) == "function" then
		pcall(send_notification, tostring(msg))
	end
end

local function clamp(n, a, b)
	return math.max(a, math.min(b, n))
end

local function getKeys()
	if type(getpressedkeys) ~= "function" then
		return {}
	end
	local ok, keys = pcall(getpressedkeys)
	return (ok and type(keys) == "table") and keys or {}
end

local function keyDown(keys, name)
	local want = string.lower(name)
	for i = 1, #keys do
		local ok, s = pcall(string.lower, tostring(keys[i]))
		if ok and s == want then
			return true
		end
	end
	return false
end

local function semicolonDown(keys)
	for i = 1, #keys do
		local ok, s = pcall(string.lower, tostring(keys[i]))
		if ok and (s == ";" or s == "semicolon" or s == "oem_1") then
			return true
		end
	end
	return false
end

local function justPressed(keys, id, downFn)
	local down = downFn(keys)
	local was = keyPrev[id]
	keyPrev[id] = down
	return down and not was
end

local function ensureHud()
	if hudHeader then
		return
	end
	if type(Drawing) ~= "table" or type(Drawing.new) ~= "function" then
		return
	end

	local function line(y)
		local t = Drawing.new("Text")
		t.Visible = true
		t.Size = 13
		t.Outline = true
		t.Color = Color3.fromRGB(0, 255, 0)
		t.ZIndex = 999
		t.Position = Vector2.new(HUD_X, y)
		return t
	end

	hudHeader = line(HUD_Y)
	hudFooter = line(HUD_Y + LINE_H * (MAX_SHOWN + 2))
	for i = 1, MAX_SHOWN do
		hudRows[i] = line(HUD_Y + LINE_H * i)
	end
end

local function rebuildList()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			list[#list + 1] = p
		end
	end
	table.sort(list, function(a, b)
		return a.Name:lower() < b.Name:lower()
	end)
	playerList = list
	if #list == 0 then
		selected = 1
	else
		selected = clamp(selected, 1, #list)
	end
end

local function getHumanoid(player)
	if not player then
		return nil
	end
	local char = player.Character
	if not char then
		return nil
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		return hum
	end
	return char:FindFirstChild("Humanoid")
end

local function startView(player)
	if not player or player == LocalPlayer then
		notify("Cannot view that player")
		return false
	end

	local hum = getHumanoid(player)
	if not hum then
		notify("No character")
		return false
	end

	local cam = workspace.CurrentCamera
	if not cam then
		notify("No camera")
		return false
	end

	pcall(function()
		if not viewing then
			savedSubject = cam.CameraSubject
		end
		cam.CameraSubject = hum
	end)

	viewing = true
	viewTarget = player
	notify("Viewing " .. player.Name)
	return true
end

local function stopView()
	viewing = false
	viewTarget = nil

	pcall(function()
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local hum = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
		if hum then
			cam.CameraSubject = hum
		elseif savedSubject then
			cam.CameraSubject = savedSubject
		end
	end)
	savedSubject = nil
	notify("Stopped viewing")
end

local function viewSelected()
	if #playerList == 0 then
		notify("No players")
		return
	end
	startView(playerList[selected])
end

local function stepSelection(delta)
	if #playerList == 0 then
		return
	end
	selected = selected + delta
	if selected < 1 then
		selected = #playerList
	elseif selected > #playerList then
		selected = 1
	end
	if viewing then
		startView(playerList[selected])
	end
end

local function validateView()
	if not viewing or not viewTarget then
		return
	end
	if not viewTarget.Parent then
		stopView()
		return
	end
	if not getHumanoid(viewTarget) then
		stopView()
	end
end

local function drawHud()
	ensureHud()
	if not hudHeader then
		return
	end

	if viewing and viewTarget then
		hudHeader.Text = "VIEW: " .. viewTarget.Name .. "  (V = stop)"
		hudHeader.Color = Color3.fromRGB(255, 255, 100)
	else
		hudHeader.Text = "Player list  |  V = view  |  P / ; = up/down"
		hudHeader.Color = Color3.fromRGB(0, 255, 0)
	end

	if #playerList == 0 then
		hudRows[1].Text = "  (no other players in server)"
		hudRows[1].Visible = true
		for i = 2, MAX_SHOWN do
			hudRows[i].Visible = false
		end
	else
		listScroll = clamp(selected - math.floor(MAX_SHOWN / 2), 0, math.max(0, #playerList - MAX_SHOWN))
		for i = 1, MAX_SHOWN do
			local row = hudRows[i]
			local idx = listScroll + i
			local plr = playerList[idx]
			if plr then
				local prefix = (idx == selected) and "> " or "  "
				local tag = (viewing and viewTarget == plr) and " *" or ""
				row.Text = prefix .. plr.Name .. tag
				row.Color = (idx == selected) and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(0, 220, 0)
				row.Visible = true
			else
				row.Visible = false
			end
		end
	end

	hudFooter.Text = string.format("Selected [%d/%d]", selected, math.max(1, #playerList))
	hudFooter.Color = Color3.fromRGB(180, 180, 180)
	hudFooter.Visible = true
end

local function onInput()
	local keys = getKeys()
	local now = os.clock()

	if justPressed(keys, "v", function(k)
		return keyDown(k, "v")
	end) and now - lastToggle > COOLDOWN then
		lastToggle = now
		if viewing then
			stopView()
		else
			viewSelected()
		end
		drawHud()
		return
	end

	if justPressed(keys, "p", function(k)
		return keyDown(k, "p")
	end) and now - lastToggle > COOLDOWN then
		lastToggle = now
		stepSelection(-1)
		drawHud()
		return
	end

	if justPressed(keys, "down", semicolonDown) and now - lastToggle > COOLDOWN then
		lastToggle = now
		stepSelection(1)
		drawHud()
	end
end

local function onTick()
	onInput()

	local now = os.clock()
	if now - lastRefresh >= LIST_REFRESH then
		lastRefresh = now
		rebuildList()
		validateView()
		drawHud()
	end
end

-- Boot
if _G.__ViewConn then
	pcall(function()
		_G.__ViewConn:Disconnect()
	end)
end
if _G.__ViewHud then
	for _, t in ipairs(_G.__ViewHud) do
		pcall(function()
			t:Remove()
		end)
	end
end

rebuildList()
ensureHud()
drawHud()

Players.PlayerAdded:Connect(function()
	rebuildList()
	drawHud()
end)
Players.PlayerRemoving:Connect(function()
	rebuildList()
	if viewTarget and not viewTarget.Parent then
		stopView()
	end
	drawHud()
end)

local loop = RunService.Render or RunService.Heartbeat
_G.__ViewConn = loop:Connect(function()
	pcall(onTick)
end)

_G.__ViewHud = { hudHeader, hudFooter }
for _, r in ipairs(hudRows) do
	table.insert(_G.__ViewHud, r)
end

notify("Player view loaded — V watch | P / ; list")
