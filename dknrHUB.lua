local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local Aim = false
local ESP = false
local dragging = false
local dragOffset = Vector2.new()

local FOV = 70
local Smoothness = 3
local MaxDistance = 500
local LockPart = "Head"

local mmr = mousemoverel or (Input and Input.MouseMove)

local function HSV(h)
    local s, v = 1, 1
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p, q, t = v*(1-s), v*(1-f*s), v*(1-(1-f)*s)
    i = i % 6
    local r, g, b =
        ({v,q,p,p,t,v})[i+1],
        ({t,v,v,q,p,p})[i+1],
        ({p,p,t,v,v,q})[i+1]
    return Color3.fromRGB(r*255, g*255, b*255)
end

local win = Drawing.new("Square")
win.Size = Vector2.new(200, 80)
win.Position = Vector2.new(100, 100)
win.Color = Color3.fromRGB(30, 30, 30)
win.Filled = true
win.Transparency = 0.85
win.Visible = true

local ttl = Drawing.new("Text")
ttl.Text = "dknrHUB"
ttl.Size = 20
ttl.Position = win.Position + Vector2.new(10, 5)
ttl.Color = Color3.fromRGB(255, 255, 255)
ttl.Outline = true
ttl.Visible = true

local function makeBtn(text, y)
    local b = Drawing.new("Text")
    b.Text = text
    b.Size = 16
    b.Position = win.Position + Vector2.new(15, y)
    b.Color = Color3.fromRGB(180, 180, 180)
    b.Outline = true
    b.Visible = true
    return b
end

local ab = makeBtn("[Aimbot: OFF]", 30)
local eb = makeBtn("[ESP: OFF]", 50)

local function hover(btn, active, m)
    local w, h = btn.Text:len()*8, btn.Size
    local p = btn.Position
    local over = m.X>=p.X and m.X<=p.X+w and m.Y>=p.Y and m.Y<=p.Y+h
    btn.Color = active and Color3.fromRGB(0,255,100)
        or (over and Color3.fromRGB(255,255,100) or Color3.fromRGB(180,180,180))
end

local function inside(m, btn)
    local w, h = btn.Text:len()*8, btn.Size
    local p = btn.Position
    return m.X>=p.X and m.X<=p.X+w and m.Y>=p.Y and m.Y<=p.Y+h
end

local function runAim()
    local closest, dist = nil, math.huge
    local m = UIS:GetMouseLocation()
    for _, v in pairs(Players:GetPlayers()) do
        if v~=LP and v.Character and v.Character:FindFirstChild(LockPart) then
            local hum = v.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = v.Character[LockPart]
                local pos = Camera:WorldToViewportPoint(head.Position)
                local d = (Vector2.new(pos.X,pos.Y)-m).Magnitude
                local r = (Camera.CFrame.Position-head.Position).Magnitude
                if pos.Z>0 and d<dist and d<FOV and r<=MaxDistance then
                    dist, closest = d, pos
                end
            end
        end
    end
    if closest and mmr then
        mmr((closest.X-m.X)/Smoothness, (closest.Y-m.Y)/Smoothness)
    end
end

local lines = {}

local function clearESP()
    for _, t in pairs(lines) do
        for _, l in ipairs(t) do
            l.Visible = false
        end
    end
end

local function runESP()
    local col = HSV((tick()%5)/5)
    for _, v in pairs(Players:GetPlayers()) do
        if v~=LP and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local hum = v.Character:FindFirstChildOfClass("Humanoid")
            local root = v.Character.HumanoidRootPart
            if hum and hum.Health > 0 then
                local c = root.Position
                local up = Vector3.new(0, 3, 0)
                local rt = Camera.CFrame.RightVector * 2
                local tl,tr,bl,br =
                    Camera:WorldToViewportPoint(c+up-rt),
                    Camera:WorldToViewportPoint(c+up+rt),
                    Camera:WorldToViewportPoint(c-up-rt),
                    Camera:WorldToViewportPoint(c-up+rt)
                if tl.Z>0 and tr.Z>0 and bl.Z>0 and br.Z>0 then
                    if not lines[v] then
                        lines[v] = {}
                        for i=1,4 do
                            local l = Drawing.new("Line")
                            l.Thickness = 2
                            l.Visible = true
                            table.insert(lines[v], l)
                        end
                    end
                    local L = lines[v]
                    L[1].From, L[1].To = Vector2.new(tl.X,tl.Y), Vector2.new(tr.X,tr.Y)
                    L[2].From, L[2].To = Vector2.new(tr.X,tr.Y), Vector2.new(br.X,br.Y)
                    L[3].From, L[3].To = Vector2.new(br.X,br.Y), Vector2.new(bl.X,bl.Y)
                    L[4].From, L[4].To = Vector2.new(bl.X,bl.Y), Vector2.new(tl.X,tl.Y)
                    for _, l in ipairs(L) do
                        l.Color = col
                        l.Visible = true
                    end
                else
                    if lines[v] then
                        for _, l in ipairs(lines[v]) do l.Visible = false end
                    end
                end
            else
                if lines[v] then
                    for _, l in ipairs(lines[v]) do l.Visible = false end
                end
            end
        else
            if lines[v] then
                for _, l in ipairs(lines[v]) do l.Visible = false end
            end
        end
    end
end

UIS.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        local m = UIS:GetMouseLocation()
        if m.X>win.Position.X and m.X<win.Position.X+win.Size.X
           and m.Y>win.Position.Y and m.Y<win.Position.Y+25 then
            dragging = true
            dragOffset = m - win.Position
            return
        end
        if inside(m, ab) then
            Aim = not Aim
            ab.Text = "[Aimbot: "..(Aim and "ON" or "OFF").."]"
        elseif inside(m, eb) then
            ESP = not ESP
            eb.Text = "[ESP: "..(ESP and "ON" or "OFF").."]"
            if not ESP then clearESP() end
        end
    end
end)

UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

RS.RenderStepped:Connect(function()
    local m = UIS:GetMouseLocation()
    if dragging then
        win.Position = m - dragOffset
        ttl.Position = win.Position + Vector2.new(10,5)
        ab.Position = win.Position + Vector2.new(15,30)
        eb.Position = win.Position + Vector2.new(15,50)
    end
    hover(ab, Aim, m)
    hover(eb, ESP, m)
    if Aim then runAim() end
    if ESP then runESP() end
end)
