-- 节拍检测音频可视化器
-- 将此脚本放在ServerScriptService中

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- 等待玩家加载
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")

-- 设置
local SQUARE_SIZE = 50 -- 小方块大小
local BEAT_SENSITIVITY = 1.3 -- 节拍灵敏度（1.2-1.5较好）
local FLASH_DURATION = 0.15 -- 闪黄持续时间（秒）
local COOLDOWN_TIME = 0.1 -- 冷却时间，防止过于频繁触发

-- 创建主GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BeatDetector"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- 创建小方块
local square = Instance.new("Frame")
square.Name = "Square"
square.Size = UDim2.new(0, SQUARE_SIZE, 0, SQUARE_SIZE)
square.Position = UDim2.new(0.5, -SQUARE_SIZE/2, 0.5, -SQUARE_SIZE/2)
square.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- 默认灰色
square.BorderSizePixel = 0
square.Parent = screenGui

-- 添加圆角
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = square

-- 创建音频对象
local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://121968966333601" -- 你的音频ID
sound.Volume = 0.5
sound.Looped = true
sound.Parent = screenGui

-- 节拍检测变量
local volumeHistory = {}
local historySize = 43 -- 保存约43帧的历史（约0.7秒）
local averageVolume = 0
local lastBeatTime = 0
local flashEndTime = 0
local isFlashing = false

-- 初始化历史数据
for i = 1, historySize do
	volumeHistory[i] = 0
end

-- 节拍检测函数
local function detectBeat()
	local currentTime = tick()
	local currentVolume = sound.PlaybackLoudness or 0

	-- 更新音量历史
	table.insert(volumeHistory, 1, currentVolume)
	if #volumeHistory > historySize then
		table.remove(volumeHistory, historySize + 1)
	end

	-- 计算平均音量
	local sum = 0
	for i = 1, #volumeHistory do
		sum = sum + volumeHistory[i]
	end
	averageVolume = sum / #volumeHistory

	-- 检测节拍：当前音量明显高于平均音量
	local isBeat = false
	if currentTime - lastBeatTime > COOLDOWN_TIME then
		if currentVolume > averageVolume * BEAT_SENSITIVITY and currentVolume > 50 then
			isBeat = true
			lastBeatTime = currentTime
			flashEndTime = currentTime + FLASH_DURATION
			isFlashing = true
		end
	end

	-- 更新方块颜色
	if isFlashing then
		if currentTime < flashEndTime then
			-- 闪黄色
			square.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
		else
			-- 恢复灰色
			square.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			isFlashing = false
		end
	end
end

-- 自动播放音频
sound:Play()

-- 连接渲染循环
local connection = RunService.Heartbeat:Connect(detectBeat)

-- 清理函数
local function cleanup()
	if connection then
		connection:Disconnect()
	end
	if sound then
		sound:Stop()
	end
	if screenGui then
		screenGui:Destroy()
	end
end

-- 当游戏关闭时清理
game:BindToClose(cleanup)

print("节拍检测器已启动！")
print("方块会随着音乐的鼓点/节拍闪黄色")