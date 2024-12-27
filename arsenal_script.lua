-- Biblioteca para criar o menu
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/AikaV3rm/UiLib/master/Lib.lua"))()

-- Criar a janela do menu
local w = library:CreateWindow("Arsenal Script")
local b = w:CreateFolder("ESP & Aimbot")

-- Variáveis para armazenar o estado das funcionalidades
local espEnabled = false
local aimbotEnabled = false

-- Função para ativar/desativar ESP
b:Toggle("ESP", function(bool)
    espEnabled = bool
    if espEnabled then
        -- Código para ativar ESP
        for _, player in pairs(game.Players:GetPlayers()) do
            if player.Team ~= game.Players.LocalPlayer.Team then
                -- Marcar inimigos em vermelho
                player.Character.Head.BrickColor = BrickColor.new("Bright red")
            else
                -- Marcar aliados em azul
                player.Character.Head.BrickColor = BrickColor.new("Bright blue")
            end
        end
    else
        -- Código para desativar ESP
        for _, player in pairs(game.Players:GetPlayers()) do
            player.Character.Head.BrickColor = BrickColor.new("Medium stone grey")
        end
    end
end)

-- Função para ativar/desativar Aimbot
b:Toggle("Aimbot", function(bool)
    aimbotEnabled = bool
    if aimbotEnabled then
        -- Código para ativar Aimbot
        game:GetService("RunService").RenderStepped:Connect(function()
            local closestEnemy = nil
            local shortestDistance = math.huge
            for _, player in pairs(game.Players:GetPlayers()) do
                if player.Team ~= game.Players.LocalPlayer.Team and player.Character and player.Character:FindFirstChild("Head") then
                    local distance = (player.Character.Head.Position - game.Players.LocalPlayer.Character.Head.Position).magnitude
                    if distance < shortestDistance then
                        closestEnemy = player
                        shortestDistance = distance
                    end
                end
            end
            if closestEnemy then
                game.Players.LocalPlayer.Character.Head.CFrame = CFrame.new(game.Players.LocalPlayer.Character.Head.Position, closestEnemy.Character.Head.Position)
            end
        end)
    end
end)

-- Criar um ícone na tela para acessar o menu
local ScreenGui = Instance.new("ScreenGui")
local OpenMenuButton = Instance.new("TextButton")

ScreenGui.Parent = game.CoreGui
OpenMenuButton.Parent = ScreenGui
OpenMenuButton.Text = "Abrir Menu"
OpenMenuButton.Size = UDim2.new(0, 100, 0, 50)
OpenMenuButton.Position = UDim2.new(0, 10, 0, 10)
OpenMenuButton.MouseButton1Click:Connect(function()
    w:Toggle()
end)
