-- GameServer — положить как Script в ServerScriptService
-- Чекпоинты с сохранением, смертельные блоки, двигающиеся платформы,
-- геймпасс на скорость и платный пропуск уровня.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

-- ===== НАСТРОЙКИ =====
local SPEED_PASS_ID = 0      -- ID геймпасса «Speed» (вставь после создания)
local SKIP_PRODUCT_ID = 0    -- ID Developer Product «Skip Stage» (вставь после создания)
local NORMAL_SPEED = 16
local BOOST_SPEED = 26
-- =====================

local stageStore = DataStoreService:GetDataStore("ObbyStage_v1")
local checkpoints = workspace:WaitForChild("Checkpoints")

local maxStage = 0
for _, cp in ipairs(checkpoints:GetChildren()) do
	local n = tonumber(cp.Name)
	if n and n > maxStage then
		maxStage = n
	end
end

local function getStage(player)
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Stage")
end

local function teleportToStage(player)
	local character = player.Character
	local stage = getStage(player)
	if not character or not stage then return end
	local root = character:WaitForChild("HumanoidRootPart", 5)
	local cp = checkpoints:FindFirstChild(tostring(stage.Value))
	if root and cp then
		character:PivotTo(cp.CFrame + Vector3.new(0, 4, 0))
	end
end

local function setSpeed(player, owns)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = owns and BOOST_SPEED or NORMAL_SPEED
	end
end

local function checkSpeedPass(player)
	if SPEED_PASS_ID == 0 then
		setSpeed(player, false)
		return
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, SPEED_PASS_ID)
	end)
	setSpeed(player, ok and owns)
end

local function onCharacter(player)
	task.wait(0.1)
	teleportToStage(player)
	checkSpeedPass(player)
end

-- ===== ИГРОКИ И СОХРАНЕНИЕ =====
Players.PlayerAdded:Connect(function(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	local stage = Instance.new("IntValue")
	stage.Name = "Stage"
	stage.Value = 1
	stage.Parent = stats

	local ok, saved = pcall(function()
		return stageStore:GetAsync(tostring(player.UserId))
	end)
	if ok and typeof(saved) == "number" then
		stage.Value = math.clamp(saved, 1, math.max(maxStage, 1))
	end

	stats.Parent = player

	player.CharacterAdded:Connect(function()
		onCharacter(player)
	end)
	if player.Character then
		onCharacter(player)
	end
end)

local function save(player)
	local stage = getStage(player)
	if not stage then return end
	pcall(function()
		stageStore:SetAsync(tostring(player.UserId), stage.Value)
	end)
end

Players.PlayerRemoving:Connect(save)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		save(player)
	end
end)

-- ===== ЧЕКПОИНТЫ =====
for _, cp in ipairs(checkpoints:GetChildren()) do
	local number = tonumber(cp.Name)
	if cp:IsA("BasePart") and number then
		cp.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not player or not humanoid or humanoid.Health <= 0 then return end
			local stage = getStage(player)
			if stage and number == stage.Value + 1 then
				stage.Value = number
			end
		end)
	end
end

-- ===== СМЕРТЕЛЬНЫЕ БЛОКИ =====
local killBricks = workspace:FindFirstChild("KillBricks")
if killBricks then
	for _, part in ipairs(killBricks:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.Health = 0
				end
			end)
		end
	end
end

-- ===== ДВИГАЮЩИЕСЯ ПЛАТФОРМЫ =====
-- У платформы можно задать атрибуты: Offset (Vector3) и Time (number)
local moving = workspace:FindFirstChild("MovingPlatforms")
if moving then
	for _, part in ipairs(moving:GetChildren()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			local offset = part:GetAttribute("Offset") or Vector3.new(0, 8, 0)
			local duration = part:GetAttribute("Time") or 3
			local info = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			TweenService:Create(part, info, { CFrame = part.CFrame + offset }):Play()
		end
	end
end

-- ===== МОНЕТИЗАЦИЯ =====
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if purchased and passId == SPEED_PASS_ID then
		setSpeed(player, true)
	end
end)

MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receipt.ProductId == SKIP_PRODUCT_ID then
		local stage = getStage(player)
		if not stage then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		stage.Value = math.min(stage.Value + 1, maxStage)
		teleportToStage(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end
