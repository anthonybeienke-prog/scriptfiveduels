local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- // CONFIGURAÇÕES ESTILO ARENA //
local aimbotLigado = false
local espLigado = false
local RAIO_FOV = 150 
local SUAVIDADE = 0.6 -- Ajustado para duelos rápidos

-- // INTERFACE (GUI) //
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ArenaDevPanel"
screenGui.ResetOnSpawn = false -- Importante para não sumir no duelo
screenGui.Parent = player:WaitForChild("PlayerGui")

local function criarBotao(nome, posicao, texto)
    local btn = Instance.new("TextButton", screenGui)
    btn.Name = nome
    btn.Size = UDim2.new(0, 160, 0, 45)
    btn.Position = posicao
    btn.Text = texto
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.BorderSizePixel = 2
    return btn
end

local btnAimbot = criarBotao("AimbotBtn", UDim2.new(0, 20, 0, 20), "AIMBOT: OFF")
local btnESP = criarBotao("ESPBtn", UDim2.new(0, 20, 0, 75), "ESP: OFF")

-- Desenho do FOV
local fovCircle = Instance.new("Frame", screenGui)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Size = UDim2.new(0, RAIO_FOV * 2, 0, RAIO_FOV * 2)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.BackgroundColor3 = Color3.new(1, 1, 1)
fovCircle.BackgroundTransparency = 0.9
fovCircle.Visible = false
-- Torna o frame redondo
local uiCorner = Instance.new("UICorner", fovCircle)
uiCorner.CornerRadius = UDim.new(1, 0)

-- // LÓGICA ESP (NOMES E HIGHLIGHT) //
local function gerenciarESP()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character then
            local char = v.Character
            local head = char:FindFirstChild("Head")
            
            if espLigado and head then
                -- Highlight (Silhueta)
                if not char:FindFirstChild("ESPHighlight") then
                    local hl = Instance.new("Highlight", char)
                    hl.Name = "ESPHighlight"
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end
                -- Nome (Billboard)
                if not head:FindFirstChild("ESPName") then
                    local bgu = Instance.new("BillboardGui", head)
                    bgu.Name = "ESPName"
                    bgu.Size = UDim2.new(0, 200, 0, 50)
                    bgu.StudsOffset = Vector3.new(0, 3, 0)
                    bgu.AlwaysOnTop = true
                    
                    local lbl = Instance.new("TextLabel", bgu)
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.Text = v.Name
                    lbl.TextColor3 = Color3.new(1, 1, 1)
                    lbl.BackgroundTransparency = 1
                    lbl.TextStrokeTransparency = 0
                    lbl.Font = Enum.Font.GothamBold
                end
            elseif not espLigado then
                if char:FindFirstChild("ESPHighlight") then char.ESPHighlight:Destroy() end
                if head:FindFirstChild("ESPName") then head.ESPName:Destroy() end
            end
        end
    end
end

-- // LÓGICA AIMBOT //
local function pegarAlvo()
    local alvoProx = nil
    local menorDist = RAIO_FOV

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("Head") then
            local head = v.Character.Head
            local pos, visivel = camera:WorldToViewportPoint(head.Position)
            
            if visivel then
                local mousePos = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
                local distTela = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                
                if distTela < menorDist then
                    -- Raycast (não atravessa paredes)
                    local params = RaycastParams.new()
                    params.FilterDescendantsInstances = {player.Character}
                    local ray = workspace:Raycast(camera.CFrame.Position, (head.Position - camera.CFrame.Position).Unit * 1000, params)
                    
                    if ray and ray.Instance:IsDescendantOf(v.Character) then
                        menorDist = distTela
                        alvoProx = head
                    end
                end
            end
        end
    end
    return alvoProx
end

-- // ATIVAÇÃO //
btnAimbot.MouseButton1Click:Connect(function()
    aimbotLigado = not aimbotLigado
    btnAimbot.Text = aimbotLigado and "AIMBOT: ON" or "AIMBOT: OFF"
    btnAimbot.BackgroundColor3 = aimbotLigado and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    fovCircle.Visible = aimbotLigado
end)

btnESP.MouseButton1Click:Connect(function()
    espLigado = not espLigado
    btnESP.Text = espLigado and "ESP: ON" or "ESP: OFF"
    btnESP.BackgroundColor3 = espLigado and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    gerenciarESP()
end)

RunService.RenderStepped:Connect(function()
    if aimbotLigado then
        local alvo = pegarAlvo()
        if alvo then
            camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, alvo.Position), SUAVIDADE)
        end
    end
    if espLigado then gerenciarESP() end
end)
