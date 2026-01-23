-- Biblioteca para criar o menu
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/AikaV3rm/UiLib/master/Lib.lua"))()

--==============================================================================
-- KILL AURA PROFISSIONAL v5.0 - COM UI AVANÇADA
-- Sistema para testes de anti-cheat em ambiente controlado
--==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local localPlayer = Players.LocalPlayer

-- Sistema principal de Kill Aura
local ProfessionalAura = {
    -- Configurações principais
    Enabled = false,
    Version = "5.0.1",
    Author = "Security Research Team",
    
    -- Parâmetros de combate
    Damage = 35,
    AttackRange = 25,
    AttackSpeed = 0.3,
    InstantKill = false,
    AutoTarget = true,
    MultiTarget = true,
    
    -- Filtros de alvo
    TargetMobs = true,
    TargetBosses = true,
    TargetPlayers = false, -- Para testes PvP
    WhitelistFriends = true,
    
    -- Sistema de evasão
    Humanize = true,
    RandomDelay = 0.1,
    JitterAmount = 0.05,
    BehaviorPattern = "AGGRESSIVE", -- PASSIVE, AGGRESSIVE, STEALTH
    
    -- Estatísticas
    TotalKills = 0,
    TotalDamage = 0,
    SessionTime = 0,
    Efficiency = 100
}

-- Cache de mobs e entidades
local EntityCache = {
    mobs = {},
    players = {},
    lastScan = 0,
    scanInterval = 0.4
}

-- Sistema de UI Avançada
local AdvancedUI = {
    MainWindow = nil,
    IsDragging = false,
    DragStartPosition = nil,
    WindowPosition = UDim2.new(0.05, 0, 0.3, 0),
    Minimized = false,
    Theme = {
        Primary = Color3.fromRGB(45, 45, 45),
        Secondary = Color3.fromRGB(30, 30, 30),
        Accent = Color3.fromRGB(0, 170, 255),
        Text = Color3.fromRGB(240, 240, 240),
        Success = Color3.fromRGB(0, 200, 100),
        Warning = Color3.fromRGB(255, 150, 0),
        Danger = Color3.fromRGB(255, 50, 50)
    }
}

-- Detecção de mobs (adaptável ao seu jogo)
local MobDetector = {
    MobNames = {"Zombie", "Skeleton", "Goblin", "Orc", "Spider", "Wolf", "Bandit", "Monster"},
    BossNames = {"Boss", "Titan", "Dragon", "Giant", "King"},
    MobTags = {"Mob", "Enemy", "Monster", "NPC"}
}

-- Função para detectar mobs
local function ScanForMobs()
    local mobsFound = {}
    
    -- Método 1: Por nome
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            local isPlayer = obj:FindFirstChild("PlayerScripts") or obj:FindFirstChild("PlayerGui")
            
            if not isPlayer and humanoid.Health > 0 then
                -- Verificar por nome
                local isMob = false
                for _, mobName in pairs(MobDetector.MobNames) do
                    if obj.Name:find(mobName) then
                        isMob = true
                        break
                    end
                end
                
                -- Verificar por tags
                if not isMob then
                    for _, tag in pairs(MobDetector.MobTags) do
                        if obj:GetAttribute(tag) or obj.Name:match(tag) then
                            isMob = true
                            break
                        end
                    end
                end
                
                if isMob then
                    local rootPart = obj:FindFirstChild("HumanoidRootPart") or 
                                     obj:FindFirstChild("Torso") or 
                                     obj:FindFirstChild("UpperTorso")
                    
                    if rootPart then
                        table.insert(mobsFound, {
                            Model = obj,
                            Humanoid = humanoid,
                            RootPart = rootPart,
                            Name = obj.Name,
                            IsBoss = false
                        })
                    end
                end
            end
        end
    end
    
    return mobsFound
end

-- Função para obter alvos ativos
local function GetActiveTargets()
    local targets = {}
    local localChar = localPlayer.Character
    if not localChar then return targets end
    
    local localRoot = localChar:FindFirstChild("HumanoidRootPart") or 
                     localChar:FindFirstChild("Torso") or 
                     localChar:FindFirstChild("UpperTorso")
    if not localRoot then return targets end
    
    -- Scan de mobs
    if ProfessionalAura.TargetMobs then
        local mobs = ScanForMobs()
        for _, mob in pairs(mobs) do
            local distance = (mob.RootPart.Position - localRoot.Position).Magnitude
            if distance <= ProfessionalAura.AttackRange then
                table.insert(targets, {
                    Type = "MOB",
                    Object = mob.Model,
                    Humanoid = mob.Humanoid,
                    RootPart = mob.RootPart,
                    Distance = distance,
                    Name = mob.Name
                })
            end
        end
    end
    
    -- Scan de jogadores (se habilitado)
    if ProfessionalAura.TargetPlayers then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Character then
                local char = player.Character
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local rootPart = char:FindFirstChild("HumanoidRootPart") or 
                                char:FindFirstChild("Torso") or 
                                char:FindFirstChild("UpperTorso")
                
                if humanoid and humanoid.Health > 0 and rootPart then
                    local distance = (rootPart.Position - localRoot.Position).Magnitude
                    if distance <= ProfessionalAura.AttackRange then
                        table.insert(targets, {
                            Type = "PLAYER",
                            Object = char,
                            Humanoid = humanoid,
                            RootPart = rootPart,
                            Distance = distance,
                            Name = player.Name
                        })
                    end
                end
            end
        end
    end
    
    -- Ordenar por distância
    table.sort(targets, function(a, b)
        return a.Distance < b.Distance
    end)
    
    return targets
end

-- Sistema de mira avançado
local AimBot = {
    LastRotation = 0,
    Smoothness = 0.35,
    PredictMovement = true
}

local function AimAtTarget(targetRoot)
    if not targetRoot then return false end
    
    local localChar = localPlayer.Character
    if not localChar then return false end
    
    local localRoot = localChar:FindFirstChild("HumanoidRootPart") or 
                     localChar:FindFirstChild("Torso") or 
                     localChar:FindFirstChild("UpperTorso")
    if not localRoot then return false end
    
    local targetPos = targetRoot.Position
    
    -- Predição de movimento
    if AimBot.PredictMovement then
        local velocity = targetRoot.AssemblyLinearVelocity
        if velocity.Magnitude > 5 then
            local predictionTime = ProfessionalAura.AttackSpeed * 0.5
            targetPos = targetPos + (velocity * predictionTime)
        end
    end
    
    -- Adicionar jitter humano
    if ProfessionalAura.Humanize and ProfessionalAura.JitterAmount > 0 then
        targetPos = targetPos + Vector3.new(
            (math.random() - 0.5) * ProfessionalAura.JitterAmount,
            (math.random() - 0.5) * ProfessionalAura.JitterAmount * 0.5,
            (math.random() - 0.5) * ProfessionalAura.JitterAmount
        )
    end
    
    -- Calcular direção
    local direction = (targetPos - localRoot.Position).Unit
    local lookCFrame = CFrame.new(localRoot.Position, localRoot.Position + direction)
    
    -- Suavização
    local smoothFactor = AimBot.Smoothness
    if ProfessionalAura.Humanize then
        smoothFactor = smoothFactor + (math.random() * 0.2 - 0.1)
    end
    
    local newCFrame = localRoot.CFrame:Lerp(lookCFrame, smoothFactor)
    
    -- Aplicar rotação
    pcall(function()
        localRoot.CFrame = newCFrame
    end)
    
    return true
end

-- Sistema de dano avançado
local DamageSystem = {
    LastAttack = 0,
    AttackQueue = {},
    
    DamageTypes = {
        NORMAL = function(humanoid, baseDamage)
            local damage = baseDamage
            if math.random() < 0.15 then -- 15% crítico
                damage = baseDamage * 2
            end
            humanoid:TakeDamage(damage)
            return damage
        end,
        
        INSTANT = function(humanoid, baseDamage)
            humanoid.Health = 0
            return humanoid.MaxHealth
        end,
        
        DOT = function(humanoid, baseDamage)
            humanoid:TakeDamage(baseDamage)
            -- Aplicar dano over time
            spawn(function()
                for i = 1, 3 do
                    wait(0.3)
                    if humanoid and humanoid.Health > 0 then
                        humanoid:TakeDamage(baseDamage * 0.3)
                    end
                end
            end)
            return baseDamage
        end
    }
}

local function ExecuteAttack(target)
    if not target then return 0 end
    
    local currentTime = tick()
    
    -- Verificar cooldown
    if currentTime - DamageSystem.LastAttack < ProfessionalAura.AttackSpeed then
        return 0
    end
    
    -- Mira automática
    if ProfessionalAura.AutoTarget then
        AimAtTarget(target.RootPart)
    end
    
    -- Aplicar delay humano
    if ProfessionalAura.Humanize and ProfessionalAura.RandomDelay > 0 then
        local delay = ProfessionalAura.RandomDelay * math.random()
        wait(delay)
    end
    
    -- Selecionar tipo de dano
    local damageType = "NORMAL"
    if ProfessionalAura.InstantKill then
        damageType = "INSTANT"
    end
    
    -- Aplicar dano
    local damageDealt = 0
    local success, result = pcall(function()
        damageDealt = DamageSystem.DamageTypes[damageType](
            target.Humanoid, 
            ProfessionalAura.Damage
        )
        return damageDealt
    end)
    
    if success then
        DamageSystem.LastAttack = currentTime
        
        -- Atualizar estatísticas
        ProfessionalAura.TotalDamage = ProfessionalAura.TotalDamage + damageDealt
        
        -- Verificar se matou
        if target.Humanoid.Health <= 0 then
            ProfessionalAura.TotalKills = ProfessionalAura.TotalKills + 1
            ProfessionalAura.Efficiency = math.min(100, 
                (ProfessionalAura.TotalKills / ProfessionalAura.SessionTime) * 60
            )
        end
        
        -- Log do ataque
        print(string.format("[AURA] Atacou %s: %.0f dano | Kills: %d", 
              target.Name, damageDealt, ProfessionalAura.TotalKills))
        
        return damageDealt
    end
    
    return 0
end

-- Loop principal do Kill Aura
local AuraLoop
AuraLoop = RunService.Heartbeat:Connect(function(deltaTime)
    if not ProfessionalAura.Enabled then return end
    
    -- Atualizar tempo da sessão
    ProfessionalAura.SessionTime = ProfessionalAura.SessionTime + deltaTime
    
    -- Obter alvos
    local targets = GetActiveTargets()
    
    if #targets > 0 then
        if ProfessionalAura.MultiTarget then
            -- Ataque em área (todos os alvos)
            for _, target in pairs(targets) do
                ExecuteAttack(target)
                
                -- Pequeno delay entre ataques
                if ProfessionalAura.Humanize and #targets > 1 then
                    wait(0.05 + math.random() * 0.1)
                end
            end
        else
            -- Ataque único (alvo mais próximo)
            local closestTarget = targets[1]
            ExecuteAttack(closestTarget)
        end
    end
end)

--==============================================================================
-- SISTEMA DE UI AVANÇADA (ARRÁSTAVEL E PERSONALIZÁVEL)
--==============================================================================

-- Criar a interface principal
local function CreateAdvancedUI()
    -- Criar ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ProfessionalAuraUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    
    -- Janela principal
    local mainWindow = Instance.new("Frame")
    mainWindow.Name = "MainWindow"
    mainWindow.Size = UDim2.new(0, 350, 0, 500)
    mainWindow.Position = AdvancedUI.WindowPosition
    mainWindow.BackgroundColor3 = AdvancedUI.Theme.Primary
    mainWindow.BorderSizePixel = 0
    mainWindow.ClipsDescendants = true
    mainWindow.Active = true
    mainWindow.Selectable = true
    mainWindow.Draggable = false
    mainWindow.Parent = screenGui
    
    -- Efeito de sombra
    local shadow = Instance.new("UIStroke")
    shadow.Name = "Shadow"
    shadow.Color = Color3.fromRGB(0, 0, 0)
    shadow.Thickness = 2
    shadow.Transparency = 0.8
    shadow.Parent = mainWindow
    
    -- Cabeçalho arrastável
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = AdvancedUI.Theme.Secondary
    header.BorderSizePixel = 0
    header.Parent = mainWindow
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 200, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔥 PROFESSIONAL KILL AURA v5.0"
    title.TextColor3 = AdvancedUI.Theme.Accent
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Botão minimizar/maximizar
    local minButton = Instance.new("TextButton")
    minButton.Name = "MinimizeButton"
    minButton.Size = UDim2.new(0, 30, 0, 30)
    minButton.Position = UDim2.new(1, -40, 0.5, -15)
    minButton.BackgroundColor3 = AdvancedUI.Theme.Accent
    minButton.Text = "-"
    minButton.TextColor3 = Color3.new(1, 1, 1)
    minButton.TextSize = 18
    minButton.Font = Enum.Font.GothamBold
    minButton.Parent = header
    
    -- Botão fechar
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -80, 0.5, -15)
    closeButton.BackgroundColor3 = AdvancedUI.Theme.Danger
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 14
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = header
    
    -- Container de conteúdo
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -60)
    content.Position = UDim2.new(0, 10, 0, 50)
    content.BackgroundTransparency = 1
    content.Parent = mainWindow
    
    -- Categoria: Status
    local statusFrame = CreateCategoryFrame("SYSTEM STATUS", content, 0)
    
    -- Toggle principal
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = "ToggleFrame"
    toggleFrame.Size = UDim2.new(1, 0, 0, 50)
    toggleFrame.Position = UDim2.new(0, 0, 0, 30)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = statusFrame
    
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Name = "ToggleLabel"
    toggleLabel.Size = UDim2.new(0, 150, 1, 0)
    toggleLabel.Position = UDim2.new(0, 0, 0, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = "KILL AURA STATUS:"
    toggleLabel.TextColor3 = AdvancedUI.Theme.Text
    toggleLabel.TextSize = 14
    toggleLabel.Font = Enum.Font.Gotham
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.Parent = toggleFrame
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 60, 0, 30)
    toggleButton.Position = UDim2.new(1, -70, 0.5, -15)
    toggleButton.BackgroundColor3 = AdvancedUI.Theme.Danger
    toggleButton.Text = "OFF"
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.TextSize = 12
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Parent = toggleFrame
    
    -- Estatísticas em tempo real
    local statsFrame = CreateCategoryFrame("REAL-TIME STATS", content, 100)
    
    local killsLabel = CreateStatRow("Total Kills:", "0", statsFrame, 0)
    local damageLabel = CreateStatRow("Damage Dealt:", "0", statsFrame, 30)
    local timeLabel = CreateStatRow("Session Time:", "0s", statsFrame, 60)
    local effLabel = CreateStatRow("Efficiency:", "100%", statsFrame, 90)
    
    -- Categoria: Configurações
    local configFrame = CreateCategoryFrame("CONFIGURATION", content, 200)
    
    -- Slider de alcance
    local rangeFrame = CreateSliderFrame("Attack Range:", 5, 50, ProfessionalAura.AttackRange, configFrame, 0)
    local damageFrame = CreateSliderFrame("Damage:", 10, 100, ProfessionalAura.Damage, configFrame, 50)
    local speedFrame = CreateSliderFrame("Attack Speed:", 0.1, 1, ProfessionalAura.AttackSpeed, configFrame, 100)
    
    -- Toggles de configuração
    local instantKillToggle = CreateToggleRow("Instant Kill", ProfessionalAura.InstantKill, configFrame, 150)
    local multiTargetToggle = CreateToggleRow("Multi Target", ProfessionalAura.MultiTarget, configFrame, 180)
    local humanizeToggle = CreateToggleRow("Humanize", ProfessionalAura.Humanize, configFrame, 210)
    
    -- Botão de reset
    local resetButton = Instance.new("TextButton")
    resetButton.Name = "ResetButton"
    resetButton.Size = UDim2.new(1, 0, 0, 35)
    resetButton.Position = UDim2.new(0, 0, 1, -40)
    resetButton.BackgroundColor3 = AdvancedUI.Theme.Warning
    resetButton.Text = "RESET STATISTICS"
    resetButton.TextColor3 = Color3.new(1, 1, 1)
    resetButton.TextSize = 14
    resetButton.Font = Enum.Font.GothamBold
    resetButton.Parent = configFrame
    
    -- Salvar referências
    AdvancedUI.MainWindow = mainWindow
    AdvancedUI.Elements = {
        ToggleButton = toggleButton,
        KillsLabel = killsLabel.ValueLabel,
        DamageLabel = damageLabel.ValueLabel,
        TimeLabel = timeLabel.ValueLabel,
        EffLabel = effLabel.ValueLabel,
        RangeSlider = rangeFrame.Slider,
        DamageSlider = damageFrame.Slider,
        SpeedSlider = speedFrame.Slider,
        InstantKillToggle = instantKillToggle.Toggle,
        MultiTargetToggle = multiTargetToggle.Toggle,
        HumanizeToggle = humanizeToggle.Toggle,
        ResetButton = resetButton
    }
    
    -- Configurar interações
    SetupUIInteractions()
    
    return screenGui
end

-- Funções auxiliares da UI
function CreateCategoryFrame(title, parent, yOffset)
    local frame = Instance.new("Frame")
    frame.Name = title .. "Frame"
    frame.Size = UDim2.new(1, 0, 0, 150)
    frame.Position = UDim2.new(0, 0, 0, yOffset)
    frame.BackgroundColor3 = AdvancedUI.Theme.Secondary
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -10, 0, 25)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = AdvancedUI.Theme.Accent
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame
    
    return frame
end

function CreateStatRow(label, value, parent, yOffset)
    local frame = Instance.new("Frame")
    frame.Name = label .. "Frame"
    frame.Size = UDim2.new(1, -20, 0, 25)
    frame.Position = UDim2.new(0, 10, 0, yOffset + 25)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local labelPart = Instance.new("TextLabel")
    labelPart.Name = "Label"
    labelPart.Size = UDim2.new(0.6, 0, 1, 0)
    labelPart.Position = UDim2.new(0, 0, 0, 0)
    labelPart.BackgroundTransparency = 1
    labelPart.Text = label
    labelPart.TextColor3 = AdvancedUI.Theme.Text
    labelPart.TextSize = 13
    labelPart.Font = Enum.Font.Gotham
    labelPart.TextXAlignment = Enum.TextXAlignment.Left
    labelPart.Parent = frame
    
    local valuePart = Instance.new("TextLabel")
    valuePart.Name = "Value"
    valuePart.Size = UDim2.new(0.4, 0, 1, 0)
    valuePart.Position = UDim2.new(0.6, 0, 0, 0)
    valuePart.BackgroundTransparency = 1
    valuePart.Text = value
    valuePart.TextColor3 = AdvancedUI.Theme.Success
    valuePart.TextSize = 13
    valuePart.Font = Enum.Font.GothamBold
    valuePart.TextXAlignment = Enum.TextXAlignment.Right
    valuePart.Parent = frame
    
    return {
        Frame = frame,
        ValueLabel = valuePart
    }
end

function CreateSliderFrame(label, min, max, value, parent, yOffset)
    local frame = Instance.new("Frame")
    frame.Name = label .. "SliderFrame"
    frame.Size = UDim2.new(1, -20, 0, 50)
    frame.Position = UDim2.new(0, 10, 0, yOffset + 25)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local labelPart = Instance.new("TextLabel")
    labelPart.Name = "Label"
    labelPart.Size = UDim2.new(1, 0, 0, 20)
    labelPart.Position = UDim2.new(0, 0, 0, 0)
    labelPart.BackgroundTransparency = 1
    labelPart.Text = label
    labelPart.TextColor3 = AdvancedUI.Theme.Text
    labelPart.TextSize = 13
    labelPart.Font = Enum.Font.Gotham
    labelPart.TextXAlignment = Enum.TextXAlignment.Left
    labelPart.Parent = frame
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = "Slider"
    sliderFrame.Size = UDim2.new(1, 0, 0, 25)
    sliderFrame.Position = UDim2.new(0, 0, 0, 20)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = frame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = sliderFrame
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    fill.Position = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = AdvancedUI.Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = sliderFrame
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 12)
    fillCorner.Parent = fill
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(1, 0, 1, 0)
    valueLabel.Position = UDim2.new(0, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(value)
    valueLabel.TextColor3 = Color3.new(1, 1, 1)
    valueLabel.TextSize = 12
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Parent = sliderFrame
    
    -- Configurar interação do slider
    local isDragging = false
    
    local function updateSlider(input)
        local relativeX = (input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X
        relativeX = math.clamp(relativeX, 0, 1)
        
        local newValue = min + (relativeX * (max - min))
        newValue = math.floor(newValue * 10) / 10
        
        fill.Size = UDim2.new(relativeX, 0, 1, 0)
        valueLabel.Text = tostring(newValue)
        
        -- Atualizar configuração correspondente
        if label:find("Range") then
            ProfessionalAura.AttackRange = newValue
        elseif label:find("Damage") then
            ProfessionalAura.Damage = newValue
        elseif label:find("Speed") then
            ProfessionalAura.AttackSpeed = newValue
        end
    end
    
    sliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            updateSlider(input)
        end
    end)
    
    sliderFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
    
    frame.Slider = sliderFrame
    return frame
end

function CreateToggleRow(label, defaultValue, parent, yOffset)
    local frame = Instance.new("Frame")
    frame.Name = label .. "ToggleFrame"
    frame.Size = UDim2.new(1, -20, 0, 30)
    frame.Position = UDim2.new(0, 10, 0, yOffset + 25)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local labelPart = Instance.new("TextLabel")
    labelPart.Name = "Label"
    labelPart.Size = UDim2.new(0.7, 0, 1, 0)
    labelPart.Position = UDim2.new(0, 0, 0, 0)
    labelPart.BackgroundTransparency = 1
    labelPart.Text = label
    labelPart.TextColor3 = AdvancedUI.Theme.Text
    labelPart.TextSize = 13
    labelPart.Font = Enum.Font.Gotham
    labelPart.TextXAlignment = Enum.TextXAlignment.Left
    labelPart.Parent = frame
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "Toggle"
    toggleButton.Size = UDim2.new(0, 50, 0, 25)
    toggleButton.Position = UDim2.new(1, -50, 0.5, -12.5)
    toggleButton.BackgroundColor3 = defaultValue and AdvancedUI.Theme.Success or AdvancedUI.Theme.Danger
    toggleButton.Text = defaultValue and "ON" or "OFF"
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.TextSize = 12
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Parent = frame
    
    toggleButton.MouseButton1Click:Connect(function()
        local newValue = not (toggleButton.Text == "ON")
        toggleButton.BackgroundColor3 = newValue and AdvancedUI.Theme.Success or AdvancedUI.Theme.Danger
        toggleButton.Text = newValue and "ON" or "OFF"
        
        -- Atualizar configuração correspondente
        if label == "Instant Kill" then
            ProfessionalAura.InstantKill = newValue
        elseif label == "Multi Target" then
            ProfessionalAura.MultiTarget = newValue
        elseif label == "Humanize" then
            ProfessionalAura.Humanize = newValue
        end
    end)
    
    frame.Toggle = toggleButton
    return frame
end

-- Configurar interações da UI
function SetupUIInteractions()
    local header = AdvancedUI.MainWindow:WaitForChild("Header")
    local minButton = header:WaitForChild("MinimizeButton")
    local closeButton = header:WaitForChild("CloseButton")
    
    -- Arrastar janela
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            AdvancedUI.IsDragging = true
            AdvancedUI.DragStartPosition = Vector2.new(
                input.Position.X - AdvancedUI.MainWindow.AbsolutePosition.X,
                input.Position.Y - AdvancedUI.MainWindow.AbsolutePosition.Y
            )
        end
    end)
    
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            AdvancedUI.IsDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and AdvancedUI.IsDragging then
            local newPos = UDim2.new(
                0, input.Position.X - AdvancedUI.DragStartPosition.X,
                0, input.Position.Y - AdvancedUI.DragStartPosition.Y
            )
            AdvancedUI.MainWindow.Position = newPos
            AdvancedUI.WindowPosition = newPos
        end
    end)
    
    -- Minimizar/Maximizar
    minButton.MouseButton1Click:Connect(function()
        AdvancedUI.Minimized = not AdvancedUI.Minimized
        
        if AdvancedUI.Minimized then
            AdvancedUI.MainWindow.Size = UDim2.new(0, 350, 0, 40)
            minButton.Text = "+"
        else
            AdvancedUI.MainWindow.Size = UDim2.new(0, 350, 0, 500)
            minButton.Text = "-"
        end
    end)
    
    -- Fechar
    closeButton.MouseButton1Click:Connect(function()
        ProfessionalAura.Enabled = false
        AdvancedUI.MainWindow.Visible = false
    end)
    
    -- Toggle principal
    AdvancedUI.Elements.ToggleButton.MouseButton1Click:Connect(function()
        ProfessionalAura.Enabled = not ProfessionalAura.Enabled
        
        if ProfessionalAura.Enabled then
            AdvancedUI.Elements.ToggleButton.BackgroundColor3 = AdvancedUI.Theme.Success
            AdvancedUI.Elements.ToggleButton.Text = "ON"
            print("[AURA] Sistema ativado!")
        else
            AdvancedUI.Elements.ToggleButton.BackgroundColor3 = AdvancedUI.Theme.Danger
            AdvancedUI.Elements.ToggleButton.Text = "OFF"
            print("[AURA] Sistema desativado!")
        end
    end)
    
    -- Reset de estatísticas
    AdvancedUI.Elements.ResetButton.MouseButton1Click:Connect(function()
        ProfessionalAura.TotalKills = 0
        ProfessionalAura.TotalDamage = 0
        ProfessionalAura.SessionTime = 0
        ProfessionalAura.Efficiency = 100
        
        AdvancedUI.Elements.KillsLabel.Text = "0"
        AdvancedUI.Elements.DamageLabel.Text = "0"
        AdvancedUI.Elements.TimeLabel.Text = "0s"
        AdvancedUI.Elements.EffLabel.Text = "100%"
        
        print("[AURA] Estatísticas resetadas!")
    end)
end

-- Atualizar UI em tempo real
spawn(function()
    while wait(0.5) do
        if AdvancedUI.Elements then
            AdvancedUI.Elements.KillsLabel.Text = tostring(ProfessionalAura.TotalKills)
            AdvancedUI.Elements.DamageLabel.Text = string.format("%.0f", ProfessionalAura.TotalDamage)
            AdvancedUI.Elements.TimeLabel.Text = string.format("%.1fs", ProfessionalAura.SessionTime)
            AdvancedUI.Elements.EffLabel.Text = string.format("%.1f%%", ProfessionalAura.Efficiency)
        end
    end
end)

--==============================================================================
-- INICIALIZAÇÃO DO SISTEMA
--==============================================================================

-- Aguardar jogador carregar
localPlayer.CharacterAdded:Wait()
wait(2)

-- Criar UI
CreateAdvancedUI()

-- Mensagem de inicialização
print("\n========================================")
print("PROFESSIONAL KILL AURA v5.0 CARREGADO")
print("========================================")
print("Recursos:")
print("• UI Arr
