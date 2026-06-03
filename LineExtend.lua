local ws = game:GetService("Workspace")
local rs = game:GetService("RunService")
local plrs = game:GetService("Players")
local uis = game:GetService("UserInputService")

local extend = 400
local birdActive = false
local birdConn = nil

local hitLine = Drawing.new("Line")
hitLine.Thickness = 2.5
hitLine.Color = Color3.fromRGB(0, 255, 255)

local hitGlow = Drawing.new("Line")
hitGlow.Thickness = 6
hitGlow.Color = Color3.fromRGB(0, 200, 255)
hitGlow.Transparency = 0.3

function getLine(part)
	local pos = part.Position
	local cf = part.CFrame
	local right = cf.RightVector
	return {
		startPos = pos - right * part.Size.X/2,
		endPos = pos + right * part.Size.X/2
	}
end

function calcExt(data, px)
	local s1 = WorldToScreen(data.startPos)
	local s2 = WorldToScreen(data.endPos)
	local dx = s2.X - s1.X
	local dy = s2.Y - s1.Y
	local len = math.sqrt(dx*dx + dy*dy)
	local nx = dx/len
	local ny = dy/len
	return {
		from = Vector2.new(s2.X, s2.Y),
		to = Vector2.new(s2.X + nx*px, s2.Y + ny*px)
	}
end

function enableBird()
	if birdActive then return end
	local char = plrs.LocalPlayer.Character
	if not char then return end
	birdActive = true
	ws.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	birdConn = rs.RenderStepped:Connect(function()
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			local p = root.Position
			ws.CurrentCamera.CFrame = CFrame.new(p.X, p.Y + 80, p.Z + 40) * CFrame.Angles(-1.4, 0, 0)
		end
	end)
end

function disableBird()
	if not birdActive then return end
	birdActive = false
	if birdConn then birdConn:Disconnect() end
	ws.CurrentCamera.CameraType = Enum.CameraType.Custom
end

uis.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.B then
		if birdActive then
			disableBird()
		else
			enableBird()
		end
	end
end)

rs.RenderStepped:Connect(function()
	local tv = ws:FindFirstChild("TrajectoryViz")
	if not tv then
		hitLine.Visible = false
		hitGlow.Visible = false
		return
	end
	
	local hit = tv:FindFirstChild("TrajHitLine")
	if hit then
		local d = getLine(hit)
		local e = calcExt(d, extend)
		hitLine.From = e.from
		hitLine.To = e.to
		hitLine.Visible = true
		hitGlow.From = e.from
		hitGlow.To = e.to
		hitGlow.Visible = true
	end
end)
