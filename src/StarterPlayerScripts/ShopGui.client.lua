-- ShopGui — положить как LocalScript в StarterPlayer > StarterPlayerScripts
-- Создаёт две кнопки: покупка скорости и пропуск уровня.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- ===== НАСТРОЙКИ (те же ID, что в GameServer) =====
local SPEED_PASS_ID = 0
local SKIP_PRODUCT_ID = 0
-- ==================================================

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "ShopGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeButton(text, xOffset, color, onClick)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 170, 0, 50)
	button.AnchorPoint = Vector2.new(0, 1)
	button.Position = UDim2.new(0, xOffset, 1, -20)
	button.BackgroundColor3 = color
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Text = text
	button.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button

	button.Activated:Connect(onClick)
end

if SPEED_PASS_ID ~= 0 then makeButton("SPEED BOOST", 20, Color3.fromRGB(255, 170, 0), function()
	MarketplaceService:PromptGamePassPurchase(player, SPEED_PASS_ID)
end) end

if SKIP_PRODUCT_ID ~= 0 then makeButton("SKIP STAGE", 200, Color3.fromRGB(0, 160, 255), function()
	MarketplaceService:PromptProductPurchase(player, SKIP_PRODUCT_ID)
end) end
