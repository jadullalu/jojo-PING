--// JOJO - ME STATS TINY WIDGET (CENTER) - FIX MINIMIZE CPM OUT
--// Fix: frame.ClipsDescendants = true + reposition CPM when minimized

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer

local CONFIG = {
	TOGGLE_KEY = Enum.KeyCode.F4,
	REFRESH_SEC = 1.0,
	ROOT = ReplicatedStorage,
	MAX_REMOTE_HOOK = 2500,
}

local UI_W, UI_H = 150, 116
local UI_H_MIN = 54

local function now() return os.clock() end

local function commaNum(n)
	n = tonumber(n) or 0
	n = math.floor(n + 0.5)
	local s = tostring(n)
	local sign = ""
	if s:sub(1,1) == "-" then sign = "-" s = s:sub(2) end
	local rev = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if rev:sub(1,1) == "," then rev = rev:sub(2) end
	return sign .. rev
end

local function safeParentGui()
	if gethui then
		local ok, hui = pcall(gethui)
		if ok and hui then return hui end
	end
	local ok, core = pcall(function() return game:GetService("CoreGui") end)
	if ok and core then return core end
	return LP:WaitForChild("PlayerGui")
end

local function protectGui(gui)
	if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
	if protectgui then pcall(protectgui, gui) end
end

local function isRemoteLike(inst)
	if not inst then return false end
	if inst:IsA("RemoteEvent") then return true end
	if inst.ClassName == "UnreliableRemoteEvent" then return true end
	return false
end

local function mergeMeta(a, b)
	local out = {}
	if type(a) == "table" then for k,v in pairs(a) do out[k] = v end end
	if type(b) == "table" then
		for k,v in pairs(b) do
			if out[k] == nil then out[k] = v end
		end
	end
	return out
end

local function tryFindNetREFolder()
	local pk = ReplicatedStorage:FindFirstChild("Packages")
	if not pk then return nil end
	local idx = pk:FindFirstChild("_Index")
	if not idx then return nil end
	for _,child in ipairs(idx:GetChildren()) do
		if child.Name:find("sleitnick_net@") then
			local net = child:FindFirstChild("net")
			if net then
				local re = net:FindFirstChild("RE")
				if re and re:IsA("Folder") then return re end
			end
		end
	end
	return nil
end

--==================== ME STATS ====================
local ALIVE = true
local seenUUID = {}

local meCatchTimes = {}
local meCatchTotal = 0
local meStartT = now()

local function meCPM()
	local t = now()
	for i = #meCatchTimes, 1, -1 do
		if (t - meCatchTimes[i]) > 60 then
			table.remove(meCatchTimes, i)
		end
	end
	return #meCatchTimes
end

local function meAvgSecPerCatch()
	if meCatchTotal <= 0 then return 0 end
	local elapsed = now() - meStartT
	if elapsed < 0 then elapsed = 0 end
	return elapsed / meCatchTotal
end

local function onMEInventory(_, meta, notif)
	if not ALIVE then return end

	local invItem = (type(notif) == "table") and notif.InventoryItem or nil
	if type(invItem) == "table" and type(invItem.Metadata) == "table" then
		meta = mergeMeta(meta, invItem.Metadata)
	end

	local uuidStr = (type(invItem) == "table" and invItem.UUID) or (type(meta)=="table" and meta.UUID) or nil
	if uuidStr and seenUUID[uuidStr] then return end
	if uuidStr then seenUUID[uuidStr] = true end

	meCatchTotal += 1
	meCatchTimes[#meCatchTimes+1] = now()
end

local function looksLikeInventoryArgs(a)
	if type(a[1]) ~= "number" then return false end
	local id = a[1]
	local meta = a[2]
	local notif = a[3]
	if type(meta) ~= "table" then return false end
	if type(notif) ~= "table" then return false end
	if notif.ItemType == "Fish" then return true end
	if type(notif.InventoryItem) == "table" then
		local it = notif.InventoryItem
		if it.Id == id or it.ItemId == id or notif.ItemId == id then return true end
	end
	if type(notif.ItemId) == "number" and notif.ItemId == id then return true end
	return false
end

--==================== UI ====================
local parentGui = safeParentGui()
pcall(function()
	local old = parentGui:FindFirstChild("JOJO_ME_STATS_TINY_CENTER_FIX")
	if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "JOJO_ME_STATS_TINY_CENTER_FIX"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = parentGui
protectGui(gui)

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.new(0, UI_W, 0, UI_H)
frame.Position = UDim2.fromScale(0.12, 0.25)
frame.BackgroundColor3 = Color3.fromRGB(18,18,22)
frame.BackgroundTransparency = 0.12
frame.BorderSizePixel = 0
frame.ClipsDescendants = true -- ✅ biar teks ga bisa keluar
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Transparency = 0.72
stroke.Color = Color3.fromRGB(255,255,255)
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 10, 0, 6)
title.Size = UDim2.new(1, -52, 0, 16)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(245,245,245)
title.TextStrokeTransparency = 0.88
title.Text = "ME Stats"
title.Parent = frame

local btnWrap = Instance.new("Frame")
btnWrap.BackgroundTransparency = 1
btnWrap.Size = UDim2.new(0, 44, 0, 18)
btnWrap.Position = UDim2.new(1, -8, 0, 6)
btnWrap.AnchorPoint = Vector2.new(1, 0)
btnWrap.Parent = frame

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
btnLayout.Padding = UDim.new(0, 6)
btnLayout.Parent = btnWrap

local function mkIconBtn(txt, bg)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.Size = UDim2.new(0, 18, 0, 18)
	b.BackgroundColor3 = bg
	b.BorderSizePixel = 0
	b.TextColor3 = Color3.fromRGB(245,245,245)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.Text = txt
	b.Parent = btnWrap
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
	return b
end

local btnMin = mkIconBtn("–", Color3.fromRGB(60,60,66))
local btnX   = mkIconBtn("×", Color3.fromRGB(88,45,45))

-- CPM (center)
local cpmValue = Instance.new("TextLabel")
cpmValue.BackgroundTransparency = 1
cpmValue.Position = UDim2.new(0, 10, 0, 28)
cpmValue.Size = UDim2.new(1, -20, 0, 40)
cpmValue.Font = Enum.Font.GothamBlack
cpmValue.TextSize = 36
cpmValue.TextXAlignment = Enum.TextXAlignment.Center
cpmValue.TextColor3 = Color3.fromRGB(245,245,245)
cpmValue.TextStrokeTransparency = 0.86
cpmValue.Text = "0"
cpmValue.Parent = frame

local cpmCaption = Instance.new("TextLabel")
cpmCaption.BackgroundTransparency = 1
cpmCaption.Position = UDim2.new(0, 10, 0, 66)
cpmCaption.Size = UDim2.new(1, -20, 0, 12)
cpmCaption.Font = Enum.Font.Gotham
cpmCaption.TextSize = 11
cpmCaption.TextXAlignment = Enum.TextXAlignment.Center
cpmCaption.TextColor3 = Color3.fromRGB(180,180,180)
cpmCaption.Text = "c/min (60s)"
cpmCaption.Parent = frame

local avgLabel = Instance.new("TextLabel")
avgLabel.BackgroundTransparency = 1
avgLabel.Position = UDim2.new(0, 10, 0, 82)
avgLabel.Size = UDim2.new(1, -20, 0, 14)
avgLabel.Font = Enum.Font.GothamSemibold
avgLabel.TextSize = 12
avgLabel.TextXAlignment = Enum.TextXAlignment.Center
avgLabel.TextColor3 = Color3.fromRGB(245,245,245)
avgLabel.TextStrokeTransparency = 0.9
avgLabel.Text = "Avg: 0.00s"
avgLabel.Parent = frame

local totalLabel = Instance.new("TextLabel")
totalLabel.BackgroundTransparency = 1
totalLabel.Position = UDim2.new(0, 10, 0, 98)
totalLabel.Size = UDim2.new(1, -20, 0, 14)
totalLabel.Font = Enum.Font.GothamSemibold
totalLabel.TextSize = 12
totalLabel.TextXAlignment = Enum.TextXAlignment.Center
totalLabel.TextColor3 = Color3.fromRGB(245,245,245)
totalLabel.TextStrokeTransparency = 0.9
totalLabel.Text = "Tot: 0"
totalLabel.Parent = frame

-- Drag
local dragging = false
local dragInput, dragStart, startPos
frame.Active = true

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Minimize FIX: pindah posisi CPM + kecilin supaya muat
local minimized = false
local function setMinimize(v)
	minimized = (v == true)

	avgLabel.Visible = not minimized
	totalLabel.Visible = not minimized
	cpmCaption.Visible = not minimized

	frame.Size = UDim2.new(0, UI_W, 0, minimized and UI_H_MIN or UI_H)
	btnMin.Text = minimized and "+" or "–"

	if minimized then
		-- taruh CPM di tengah area kecil
		cpmValue.Position = UDim2.new(0, 10, 0, 22)
		cpmValue.Size = UDim2.new(1, -20, 0, 30)
		cpmValue.TextSize = 30
	else
		cpmValue.Position = UDim2.new(0, 10, 0, 28)
		cpmValue.Size = UDim2.new(1, -20, 0, 40)
		cpmValue.TextSize = 36
	end
end

btnMin.MouseButton1Click:Connect(function()
	setMinimize(not minimized)
end)

btnX.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == CONFIG.TOGGLE_KEY then
		gui.Enabled = not gui.Enabled
	end
end)

local function updateHUD()
	local cpm60 = meCPM()
	local avgSec = meAvgSecPerCatch()
	cpmValue.Text = tostring(cpm60)
	avgLabel.Text = ("Avg: %.2fs"):format(avgSec)
	totalLabel.Text = ("Tot: %s"):format(commaNum(meCatchTotal))
end

--==================== sniff remotes ====================
local hooked = 0
local hookedSet = {}

local function hookRemote(r)
	if hookedSet[r] then return end
	hookedSet[r] = true
	hooked += 1
	if hooked > CONFIG.MAX_REMOTE_HOOK then return end

	pcall(function()
		r.OnClientEvent:Connect(function(...)
			local args = {...}
			if looksLikeInventoryArgs(args) then
				onMEInventory(args[1], args[2], args[3])
				updateHUD()
			end
		end)
	end)
end

local function startSniff()
	local root = tryFindNetREFolder() or CONFIG.ROOT
	for _,d in ipairs(root:GetDescendants()) do
		if isRemoteLike(d) then hookRemote(d) end
	end
	root.DescendantAdded:Connect(function(d)
		if isRemoteLike(d) then hookRemote(d) end
	end)
end

startSniff()
updateHUD()

task.spawn(function()
	while ALIVE and gui and gui.Parent do
		task.wait(CONFIG.REFRESH_SEC)
		pcall(updateHUD)
	end
end)
