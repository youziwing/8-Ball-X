local ws = game:GetService("Workspace")
local rs = game:GetService("RunService")

local CFG = {
    extend = 400,
    pulseSpeed = 3, pulseMin = 0.2, pulseMax = 0.5,

    main = {
        thick = 2.5, color = Color3.fromRGB(0, 255, 255),
        glowThick = 8, glowColor = Color3.fromRGB(0, 180, 255), glowAlpha = 0.25,
        tipSize = 12, tipColor = Color3.fromRGB(100, 255, 255),
    },
    deflect = {
        thick = 2, color = Color3.fromRGB(255, 100, 100),
        glowThick = 6, glowColor = Color3.fromRGB(255, 50, 50), glowAlpha = 0.2,
        tipSize = 10, tipColor = Color3.fromRGB(255, 150, 150),
    },
}

local state = { pulsePhase = 0 }

-- Drawing helpers
local function newLine(props)
    local d = Drawing.new("Line")
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function makeSet(style)
    local glowAlpha = style.glowAlpha
    return {
        line = newLine({ Thickness = style.thick, Color = style.color }),
        glow1 = newLine({ Thickness = style.glowThick, Color = style.glowColor, Transparency = glowAlpha }),
        glow2 = newLine({ Thickness = style.glowThick * 0.6, Color = style.color, Transparency = glowAlpha * 1.5 }),
        tip = { newLine({ Thickness = 1.5, Color = style.tipColor }), newLine({ Thickness = 1.5, Color = style.tipColor }), newLine({ Thickness = 1.5, Color = style.tipColor }) },
        tipSize = style.tipSize,
    }
end

local draw = { main = makeSet(CFG.main), deflect = makeSet(CFG.deflect) }

-- Utils
local function lerp(a, b, t) return a + (b - a) * t end
local function round(v) return Vector2.new(math.floor(v.X + 0.5), math.floor(v.Y + 0.5)) end

local function getLineData(part)
    local pos, cf = part.Position, part.CFrame
    local right, halfW = cf.RightVector, part.Size.X / 2
    return { startPos = pos - right * halfW, endPos = pos + right * halfW, center = pos, right = right, halfW = halfW }
end

local function calcExtended(data, px)
    local s1, o1 = WorldToScreen(data.startPos)
    local s2, o2 = WorldToScreen(data.endPos)
    if not (s1 and s2) then return nil end

    local dx, dy = s2.X - s1.X, s2.Y - s1.Y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then return nil end

    local nx, ny = dx / len, dy / len
    return {
        from = round(Vector2.new(s2.X, s2.Y)),
        to = round(Vector2.new(s2.X + nx * px, s2.Y + ny * px)),
        dir = Vector2.new(nx, ny),
        len = len, on1 = o1, on2 = o2,
    }
end

local function updateTip(tipLines, ext, alpha, size)
    if not ext then
        for i = 1, 3 do tipLines[i].Visible = false end
        return
    end

    local tip, dir = ext.to, ext.dir
    local perp = Vector2.new(-dir.Y, dir.X)
    local sz = size or CFG.main.tipSize
    local c = tip + dir * sz * 0.5
    local l = tip - dir * sz * 0.3 + perp * sz * 0.4
    local r = tip - dir * sz * 0.3 - perp * sz * 0.4

    tipLines[1].From, tipLines[1].To = round(c), round(l)
    tipLines[2].From, tipLines[2].To = round(c), round(r)
    tipLines[3].From, tipLines[3].To = round(l), round(r)

    for i = 1, 3 do
        tipLines[i].Visible = true
        tipLines[i].Transparency = alpha
    end
end

-- Visibility
local function hide(set)
    set.line.Visible = false
    set.glow1.Visible = false
    set.glow2.Visible = false
    updateTip(set.tip, nil, 0)
end

local function show(set, ext, glowAlpha, pulse)
    set.line.From, set.line.To = ext.from, ext.to
    set.line.Visible = true

    set.glow1.From, set.glow1.To = ext.from, ext.to
    set.glow1.Transparency = glowAlpha
    set.glow1.Visible = true

    set.glow2.From, set.glow2.To = ext.from, ext.to
    set.glow2.Transparency = glowAlpha * 1.2
    set.glow2.Visible = true

    updateTip(set.tip, ext, lerp(0.4, 1.0, pulse), set.tipSize)
end

-- Cleanup
local function cleanup()
    for _, set in pairs(draw) do
        for _, d in pairs({ set.line, set.glow1, set.glow2 }) do d:Remove() end
        for i = 1, 3 do set.tip[i]:Remove() end
    end
end

_G._trajCleanup = cleanup

-- Render loop
rs.RenderStepped:Connect(function(dt)
    state.pulsePhase = state.pulsePhase + dt * CFG.pulseSpeed
    local pulse = (math.sin(state.pulsePhase) + 1) / 2
    local glowAlpha = lerp(CFG.pulseMin, CFG.pulseMax, pulse)

    local tv = ws:FindFirstChild("TrajectoryViz")
    if not tv then
        hide(draw.main)
        hide(draw.deflect)
        return
    end

    local hit = tv:FindFirstChild("TrajHitLine")
    if not hit then
        hide(draw.main)
    else
        local ext = calcExtended(getLineData(hit), CFG.extend)
        if not ext then hide(draw.main) else show(draw.main, ext, glowAlpha, pulse) end
    end

    local deflect = tv:FindFirstChild("TrajDeflectLine")
    if not deflect then
        hide(draw.deflect)
    else
        local ext = calcExtended(getLineData(deflect), CFG.extend)
        if not ext then hide(draw.deflect) else show(draw.deflect, ext, glowAlpha, pulse) end
    end
end)
