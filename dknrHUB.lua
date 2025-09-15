local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local AimbotEnabled = false
local ESPEnabled = false
local dragging = false
local dragOffset = Vector2.new()

-- Aimbot設定
local FOV = 70
local Smoothness = 3
local LockPart = "Head"
local MaxDistance = 500

local mousemoverel = mousemoverel or (Input and Input.MouseMove)

-- UI構築
local window = Drawing.new("Square")
window.Size = Vector2.new(220, 120)
window.Position = Vector2.new(100, 100)
window.Color = Color3.fromRGB(25, 25, 25)
window.Filled = true
window.Transparency = 0.85
window.Visible = true

local title = Drawing.new("Text")
title.Text = "dknrHUB"
title.Size = 20
title.Position = window.Position + Vector2.new(10, 8)
title.Color = Color3.fromRGB(255, 255, 255)
title.Outline = true
title.Visible = true

local function createButton(text, offsetY)
    local btn = Drawing.new("Text")
    btn.Text = text
    btn.Size = 16
    btn.Position = window.Position + Vector2.new(15, offsetY)
    btn.Color = Color3.fromRGB(180, 180, 180)
    btn.Outline = true
    btn.Visible = true
    return btn
end

local aimbotBtn = createButton("[Aimbot: OFF]", 40)
local espBtn = createButton("[ESP: OFF]", 70)

local function hoverEffect(btn, active, mouse)
    local hovered = (mouse.X >= btn.Position.X and mouse.X <= btn.Position.X + btn.Text:len() * 8) and
                    (mouse.Y >= btn.Position.Y and mouse.Y <= btn.Position.Y + btn.Size)
    btn.Color = active and Color3.fromRGB(0, 255, 100) or (hovered and Color3.fromRGB(255, 255, 100) or Color3.fromRGB(180, 180, 180))
end

local function isInsideButton(mouse, btn)
    local width = btn.Text:len() * 8
    local height = btn.Size
    local pos = btn.Position
    return mouse.X >= pos.X and mouse.X <= pos.X + width and
           mouse.Y >= pos.Y and mouse.Y <= pos.Y + height
end

-- Aimbot（FOV＋距離＋生存チェック＋スムージング）
local function runAimbot()
    local closest, distance = nil, math.huge
    local mouse = UIS:GetMouseLocation()

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(LockPart) then
            local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local head = v.Character[LockPart]
                local pos = Camera:WorldToViewportPoint(head.Position)
                local dist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                local range = (Camera.CFrame.Position - head.Position).Magnitude

                if pos.Z > 0 and dist < distance and dist < FOV and range <= MaxDistance then
                    distance = dist
                    closest = pos
                end
            end
        end
    end

    if closest and mousemoverel then
        local dx = (closest.X - mouse.X) / Smoothness
        local dy = (closest.Y - mouse.Y) / Smoothness
        mousemoverel(dx, dy)
    end
end

-- Box型ESP（カメラ正面に固定）
local activeESP = {}

local function clearESP()
    for _, obj in pairs(activeESP) do
        if obj.Remove then obj:Remove() end
    end
    activeESP = {}
end

local function runESP()
    clearESP()

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local root = v.Character.HumanoidRootPart
                local center = root.Position
                local up = Vector3.new(0, 3, 0)
                local right = Camera.CFrame.RightVector * 2

                local tl = Camera:WorldToViewportPoint(center + up - right)
                local tr = Camera:WorldToViewportPoint(center + up + right)
                local bl = Camera:WorldToViewportPoint(center - up - right)
                local br = Camera:WorldToViewportPoint(center - up + right)

                if tl.Z > 0 and tr.Z > 0 and bl.Z > 0 and br.Z > 0 then
                    local lines = {}
                    local function drawLine(p1, p2)
                        local line = Drawing.new("Line")
                        line.From = Vector2.new(p1.X, p1.Y)
                        line.To = Vector2.new(p2.X, p2.Y)
                        line.Color = Color3.fromRGB(255, 0, 0)
                        line.Thickness = 2
                        line.Visible = true
                        table.insert(lines, line)
                    end

                    drawLine(tl, tr)
                    drawLine(tr, br)
                    drawLine(br, bl)
                    drawLine(bl, tl)

                    for _, l in pairs(lines) do
                        table.insert(activeESP, l)
                    end
                end
            end
        end
    end
end

-- クリック処理
UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mouse = UIS:GetMouseLocation()

        if (mouse.X > window.Position.X and mouse.X < window.Position.X + window.Size.X) and
           (mouse.Y > window.Position.Y and mouse.Y < window.Position.Y + 25) then
            dragging = true
            dragOffset = mouse - window.Position
            return
        end

        if isInsideButton(mouse, aimbotBtn) then
            AimbotEnabled = not AimbotEnabled
            aimbotBtn.Text = "[Aimbot: " .. (AimbotEnabled and "ON" or "OFF") .. "]"
            return
        end

        if isInsideButton(mouse, espBtn) then
            ESPEnabled = not ESPEnabled
            espBtn.Text = "[ESP: " .. (ESPEnabled and "ON" or "OFF") .. "]"
            if not ESPEnabled then clearESP() end
            return
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- メインループ
RS.RenderStepped:Connect(function()
    local mouse = UIS:GetMouseLocation()

    if dragging then
        window.Position = mouse - dragOffset
        title.Position = window.Position + Vector2.new(10, 8)
        aimbotBtn.Position = window.Position + Vector2.new(15, 40)
        espBtn.Position = window.Position + Vector2.new(15, 70)
    end

    hoverEffect(aimbotBtn, AimbotEnabled, mouse)
    hoverEffect(espBtn, ESPEnabled, mouse)

    if AimbotEnabled then runAimbot() end
    if ESPEnabled then runESP() end
end)