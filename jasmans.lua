--[[
    HackSense UI Library v1.0.0
    Modern, clean Roblox UI library with theme support and smooth animations.

    Quick Start:
        local HS = loadstring(game:HttpGet("YOUR_URL"))()

        local gui = HS:New({ Name = "My Client", Theme = "Blue" })

        local combat = gui:AddTab("Combat", "rbxassetid://SWORD_ID")
        combat:AddToggle("Aimbot", false, function(v) print("Aimbot:", v) end)
        combat:AddSlider("FOV", 10, 360, 90, function(v) print("FOV:", v) end)
        combat:AddDropdown("Target", {"Head", "Body", "Nearest"}, 1, function(v) print("Target:", v) end)
        combat:AddKeybind("Menu Key", Enum.KeyCode.RightShift, function(k) print("Key:", k.Name) end)

        local visuals = gui:AddTab("Visuals", "rbxassetid://EYE_ID")
        visuals:AddToggle("Box ESP", false, function(v) end)

        gui:BindToggle(Enum.KeyCode.RightShift)

    Themes: "Blue", "Red", "Green", "Purple"

    Tab Methods:
        AddToggle(label, default, callback) -> {Get, Set}
        AddSlider(label, min, max, default, callback) -> {Get, Set}
        AddDropdown(label, options, defaultIndex, callback) -> {Get, Set}
        AddKeybind(label, defaultKey, callback) -> {Get, Set}
        AddButton(label, callback)
        AddSectionLabel(text)

    GUI Methods:
        SetTheme(themeName)
        Toggle()
        Destroy()
        BindToggle(keyCode)
]]

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================
-- COLOR THEMES
-- ============================================
local Themes = {
    Blue = {
        Accent = Color3.fromRGB(70, 130, 255),
        AccentHover = Color3.fromRGB(95, 155, 255),
        AccentDark = Color3.fromRGB(45, 90, 180),
        Background = Color3.fromRGB(18, 18, 28),
        Sidebar = Color3.fromRGB(14, 14, 22),
        Content = Color3.fromRGB(20, 20, 32),
        Element = Color3.fromRGB(28, 28, 42),
        ElementHover = Color3.fromRGB(35, 35, 52),
        TextPrimary = Color3.fromRGB(225, 225, 240),
        TextSecondary = Color3.fromRGB(120, 120, 150),
        ToggleOff = Color3.fromRGB(45, 45, 60),
        ToggleCircle = Color3.fromRGB(240, 240, 250),
        SliderTrack = Color3.fromRGB(35, 35, 50),
        Border = Color3.fromRGB(30, 30, 45),
    },
    Red = {
        Accent = Color3.fromRGB(255, 75, 75),
        AccentHover = Color3.fromRGB(255, 105, 105),
        AccentDark = Color3.fromRGB(180, 45, 45),
        Background = Color3.fromRGB(28, 18, 18),
        Sidebar = Color3.fromRGB(22, 14, 14),
        Content = Color3.fromRGB(32, 20, 20),
        Element = Color3.fromRGB(42, 28, 28),
        ElementHover = Color3.fromRGB(55, 38, 38),
        TextPrimary = Color3.fromRGB(240, 225, 225),
        TextSecondary = Color3.fromRGB(150, 120, 120),
        ToggleOff = Color3.fromRGB(60, 45, 45),
        ToggleCircle = Color3.fromRGB(250, 240, 240),
        SliderTrack = Color3.fromRGB(50, 35, 35),
        Border = Color3.fromRGB(45, 30, 30),
    },
    Green = {
        Accent = Color3.fromRGB(75, 220, 120),
        AccentHover = Color3.fromRGB(100, 235, 145),
        AccentDark = Color3.fromRGB(45, 160, 80),
        Background = Color3.fromRGB(18, 28, 20),
        Sidebar = Color3.fromRGB(14, 22, 16),
        Content = Color3.fromRGB(20, 32, 24),
        Element = Color3.fromRGB(28, 42, 32),
        ElementHover = Color3.fromRGB(38, 55, 42),
        TextPrimary = Color3.fromRGB(225, 240, 230),
        TextSecondary = Color3.fromRGB(120, 150, 130),
        ToggleOff = Color3.fromRGB(45, 60, 50),
        ToggleCircle = Color3.fromRGB(240, 250, 245),
        SliderTrack = Color3.fromRGB(35, 50, 40),
        Border = Color3.fromRGB(30, 45, 35),
    },
    Purple = {
        Accent = Color3.fromRGB(170, 100, 255),
        AccentHover = Color3.fromRGB(190, 125, 255),
        AccentDark = Color3.fromRGB(120, 60, 200),
        Background = Color3.fromRGB(24, 18, 32),
        Sidebar = Color3.fromRGB(18, 14, 26),
        Content = Color3.fromRGB(28, 20, 38),
        Element = Color3.fromRGB(36, 28, 48),
        ElementHover = Color3.fromRGB(48, 38, 62),
        TextPrimary = Color3.fromRGB(235, 225, 245),
        TextSecondary = Color3.fromRGB(140, 120, 160),
        ToggleOff = Color3.fromRGB(50, 42, 65),
        ToggleCircle = Color3.fromRGB(245, 240, 252),
        SliderTrack = Color3.fromRGB(42, 35, 55),
        Border = Color3.fromRGB(38, 30, 50),
    },
}

-- ============================================
-- UTILITIES
-- ============================================
local function tw(instance, props, duration, style, direction)
    return TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
        props
    )
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

-- ============================================
-- TAB CLASS
-- ============================================
local Tab = {}
Tab.__index = Tab

function Tab.new(gui, name, iconId, index)
    local self = setmetatable({}, Tab)
    self._gui = gui
    self._name = name
    self._iconId = iconId
    self._index = index
    self._elements = {}
    self._layoutIdx = 0

    -- Sidebar button
    self._btn = Instance.new("TextButton")
    self._btn.Name = name .. "_Tab"
    self._btn.Size = UDim2.new(0, 36, 0, 36)
    self._btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self._btn.BackgroundTransparency = 1
    self._btn.BorderSizePixel = 0
    self._btn.AutoButtonColor = false
    self._btn.LayoutOrder = index
    self._btn.Text = ""
    self._btn.Parent = gui._sidebar

    corner(self._btn, 8)

    -- Icon or text fallback
    if iconId and iconId ~= "" then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(1, -10, 1, -10)
        icon.Position = UDim2.new(0, 5, 0, 5)
        icon.BackgroundTransparency = 1
        icon.Image = iconId
        icon.ImageColor3 = Color3.fromRGB(180, 180, 200)
        icon.Parent = self._btn
        self._iconLabel = icon
    else
        local lbl = Instance.new("TextLabel")
        lbl.Name = "Label"
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name:sub(1, 2):upper()
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextColor3 = gui.T.TextSecondary
        lbl.Parent = self._btn
        self._iconLabel = lbl
    end

    -- Hover
    self._btn.MouseEnter:Connect(function()
        if gui._activeTab ~= self then
            tw(self._btn, {BackgroundTransparency = 0.75}):Play()
            self:_setIconColor(gui.T.TextPrimary)
        end
    end)
    self._btn.MouseLeave:Connect(function()
        if gui._activeTab ~= self then
            tw(self._btn, {BackgroundTransparency = 1}):Play()
            self:_setIconColor(gui.T.TextSecondary)
        end
    end)

    -- Click
    self._btn.MouseButton1Click:Connect(function()
        gui:_switchTab(self)
    end)

    -- Content page (ScrollingFrame)
    self._page = Instance.new("ScrollingFrame")
    self._page.Name = name .. "_Page"
    self._page.Size = UDim2.new(1, 0, 1, 0)
    self._page.BackgroundTransparency = 1
    self._page.ScrollBarThickness = 3
    self._page.ScrollBarImageColor3 = gui.T.Accent
    self._page.BorderSizePixel = 0
    self._page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self._page.CanvasSize = UDim2.new(0, 0, 0, 0)
    self._page.Visible = false
    self._page.ScrollingEnabled = true
    self._page.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
    self._page.Parent = gui._contentArea

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = self._page

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent = self._page

    return self
end

function Tab:_setIconColor(color)
    if not self._iconLabel then return end
    if self._iconLabel:IsA("ImageLabel") then
        tw(self._iconLabel, {ImageColor3 = color}, 0.2):Play()
    else
        tw(self._iconLabel, {TextColor3 = color}, 0.2):Play()
    end
end

function Tab:_activate()
    tw(self._btn, {BackgroundColor3 = self._gui.T.Accent, BackgroundTransparency = 0.15}, 0.2):Play()
    self:_setIconColor(Color3.fromRGB(255, 255, 255))
end

function Tab:_deactivate()
    tw(self._btn, {BackgroundTransparency = 1}, 0.2):Play()
    self:_setIconColor(self._gui.T.TextSecondary)
end

-- ============================================
-- COMPONENT: TOGGLE
-- ============================================
function Tab:AddToggle(label, default, callback)
    self._layoutIdx = self._layoutIdx + 1
    local idx = self._layoutIdx
    local T = self._gui.T

    local container = Instance.new("Frame")
    container.Name = "Toggle_" .. label
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = T.Element
    container.BorderSizePixel = 0
    container.LayoutOrder = idx
    container.Parent = self._page
    corner(container, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -55, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = T.TextPrimary
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container

    -- Toggle switch background
    local tBg = Instance.new("Frame")
    tBg.Size = UDim2.new(0, 40, 0, 20)
    tBg.Position = UDim2.new(1, -48, 0.5, -10)
    tBg.BackgroundColor3 = default and T.Accent or T.ToggleOff
    tBg.BorderSizePixel = 0
    tBg.Parent = container
    corner(tBg, 10)

    -- Toggle circle
    local tCircle = Instance.new("Frame")
    tCircle.Size = UDim2.new(0, 16, 0, 16)
    tCircle.Position = default and UDim2.new(0, 22, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    tCircle.BackgroundColor3 = T.ToggleCircle
    tCircle.BorderSizePixel = 0
    tCircle.Parent = tBg
    corner(tCircle, 8)

    local state = default == true

    local function toggle()
        state = not state
        if state then
            tw(tBg, {BackgroundColor3 = T.Accent}, 0.2):Play()
            tw(tCircle, {Position = UDim2.new(0, 22, 0.5, -8)}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
        else
            tw(tBg, {BackgroundColor3 = T.ToggleOff}, 0.2):Play()
            tw(tCircle, {Position = UDim2.new(0, 2, 0.5, -8)}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
        end
        if callback then callback(state) end
    end

    tBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            toggle()
        end
    end)

    table.insert(self._elements, {
        type = "toggle", container = container, tBg = tBg, tCircle = tCircle,
        label = lbl, _state = function() return state end,
    })

    return {
        Get = function() return state end,
        Set = function(v) if state ~= v then toggle() end end,
    }
end

-- ============================================
-- COMPONENT: SLIDER
-- ============================================
function Tab:AddSlider(label, min, max, default, callback)
    self._layoutIdx = self._layoutIdx + 1
    local idx = self._layoutIdx
    local T = self._gui.T

    local value = default or min
    local sliding = false

    local container = Instance.new("Frame")
    container.Name = "Slider_" .. label
    container.Size = UDim2.new(1, 0, 0, 52)
    container.BackgroundColor3 = T.Element
    container.BorderSizePixel = 0
    container.LayoutOrder = idx
    container.Parent = self._page
    corner(container, 6)

    -- Label + value
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 0, 24)
    lbl.Position = UDim2.new(0, 12, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = T.TextPrimary
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 45, 0, 24)
    valLbl.Position = UDim2.new(1, -52, 0, 4)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(math.floor(value))
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12
    valLbl.TextColor3 = T.Accent
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = container

    -- Track
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, -24, 0, 8)
    track.Position = UDim2.new(0, 12, 0, 32)
    track.BackgroundColor3 = T.SliderTrack
    track.BorderSizePixel = 0
    track.Parent = container
    corner(track, 4)

    -- Fill
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = T.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 4)

    -- Handle
    local handle = Instance.new("Frame")
    handle.Name = "Handle"
    handle.Size = UDim2.new(0, 16, 0, 16)
    handle.Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8)
    handle.BackgroundColor3 = T.Accent
    handle.BorderSizePixel = 0
    handle.Parent = track
    corner(handle, 8)

    local function updateFromPosition(inputPos)
        local relX = (inputPos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
        relX = math.clamp(relX, 0, 1)
        local newVal = min + (max - min) * relX
        -- Snap to integer if range is integer-like
        if max == math.floor(max) and min == math.floor(min) then
            newVal = math.floor(newVal + 0.5)
        end
        value = newVal
        local ratio = (value - min) / (max - min)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        handle.Position = UDim2.new(ratio, -8, 0.5, -8)
        valLbl.Text = tostring(math.floor(value))
        if callback then callback(value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateFromPosition(input.Position)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromPosition(input.Position)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            sliding = false
        end
    end)

    table.insert(self._elements, {
        type = "slider", container = container, track = track, fill = fill,
        handle = handle, valLbl = valLbl, label = lbl,
    })

    return {
        Get = function() return value end,
        Set = function(v)
            value = math.clamp(v, min, max)
            local ratio = (value - min) / (max - min)
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            handle.Position = UDim2.new(ratio, -8, 0.5, -8)
            valLbl.Text = tostring(math.floor(value))
        end,
    }
end

-- ============================================
-- COMPONENT: DROPDOWN
-- ============================================
function Tab:AddDropdown(label, options, defaultIdx, callback)
    self._layoutIdx = self._layoutIdx + 1
    local idx = self._layoutIdx
    local T = self._gui.T

    local selected = defaultIdx or 1
    local isOpen = false

    local container = Instance.new("Frame")
    container.Name = "Dropdown_" .. label
    container.BackgroundColor3 = T.Element
    container.BorderSizePixel = 0
    container.LayoutOrder = idx
    container.ClipsDescendants = true
    container.Parent = self._page
    corner(container, 6)

    -- Label
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.Position = UDim2.new(0, 0, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = T.TextSecondary
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container

    -- Selected button
    local selBtn = Instance.new("TextButton")
    selBtn.Name = "Selected"
    selBtn.Size = UDim2.new(1, 0, 0, 30)
    selBtn.Position = UDim2.new(0, 0, 0, 22)
    selBtn.BackgroundColor3 = T.SliderTrack
    selBtn.BorderSizePixel = 0
    selBtn.Text = options[selected] or "..."
    selBtn.Font = Enum.Font.Gotham
    selBtn.TextSize = 13
    selBtn.TextColor3 = T.TextPrimary
    selBtn.TextXAlignment = Enum.TextXAlignment.Left
    selBtn.AutoButtonColor = false
    selBtn.Parent = container
    corner(selBtn, 4)

    local selPad = Instance.new("UIPadding")
    selPad.PaddingLeft = UDim.new(0, 10)
    selPad.Parent = selBtn

    -- Arrow
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -24, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "v"
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 11
    arrow.TextColor3 = T.TextSecondary
    arrow.Rotation = isOpen and 180 or 0
    arrow.Parent = selBtn

    -- Options container
    local optFrame = Instance.new("Frame")
    optFrame.Name = "Options"
    optFrame.Size = UDim2.new(1, 0, 0, 0)
    optFrame.Position = UDim2.new(0, 0, 1, 2)
    optFrame.BackgroundTransparency = 1
    optFrame.ClipsDescendants = true
    optFrame.Parent = selBtn

    local optLayout = Instance.new("UIListLayout")
    optLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optLayout.Parent = optFrame

    local optButtons = {}

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Name = "Opt_" .. i
        optBtn.Size = UDim2.new(1, 0, 0, 28)
        optBtn.BackgroundColor3 = i == selected and T.Accent or T.SliderTrack
        optBtn.BorderSizePixel = 0
        optBtn.Text = opt
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 13
        optBtn.TextColor3 = i == selected and Color3.fromRGB(255, 255, 255) or T.TextPrimary
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.AutoButtonColor = false
        optBtn.LayoutOrder = i
        optBtn.Visible = false
        optBtn.Parent = optFrame
        corner(optBtn, 4)

        local oPad = Instance.new("UIPadding")
        oPad.PaddingLeft = UDim.new(0, 10)
        oPad.Parent = optBtn

        optBtn.MouseEnter:Connect(function()
            if selected ~= i then
                tw(optBtn, {BackgroundColor3 = T.ElementHover}, 0.15):Play()
            end
        end)
        optBtn.MouseLeave:Connect(function()
            if selected ~= i then
                tw(optBtn, {BackgroundColor3 = T.SliderTrack}, 0.15):Play()
            end
        end)

        optBtn.MouseButton1Click:Connect(function()
            -- Deselect old
            if optButtons[selected] then
                tw(optButtons[selected], {BackgroundColor3 = T.SliderTrack, TextColor3 = T.TextPrimary}, 0.15):Play()
            end
            selected = i
            selBtn.Text = opt
            tw(optBtn, {BackgroundColor3 = T.Accent, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.15):Play()
            if callback then callback(opt, i) end
            -- Close dropdown
            isOpen = false
            tw(container, {Size = UDim2.new(1, 0, 0, 52)}, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
            tw(arrow, {Rotation = 0}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
            for _, b in ipairs(optButtons) do b.Visible = false end
        end)

        table.insert(optButtons, optBtn)
    end

    container.Size = UDim2.new(1, 0, 0, 52)

    selBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            local optHeight = #options * 28 + 4
            tw(container, {Size = UDim2.new(1, 0, 0, 52 + optHeight)}, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
            tw(arrow, {Rotation = 180}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
            for i, b in ipairs(optButtons) do
                b.Visible = true
            end
        else
            tw(container, {Size = UDim2.new(1, 0, 0, 52)}, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
            tw(arrow, {Rotation = 0}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
            for _, b in ipairs(optButtons) do b.Visible = false end
        end
    end)

    table.insert(self._elements, {
        type = "dropdown", container = container, selBtn = selBtn,
        optFrame = optFrame, optButtons = optButtons, label = lbl,
        arrow = arrow, _getSelected = function() return selected end,
    })

    return {
        Get = function() return options[selected], selected end,
        Set = function(v)
            local newIdx = type(v) == "number" and v or nil
            if not newIdx then
                for i, opt in ipairs(options) do
                    if opt == v then newIdx = i break end
                end
            end
            if newIdx and optButtons[newIdx] then
                if optButtons[selected] then
                    optButtons[selected].BackgroundColor3 = T.SliderTrack
                    optButtons[selected].TextColor3 = T.TextPrimary
                end
                selected = newIdx
                selBtn.Text = options[selected]
                optButtons[selected].BackgroundColor3 = T.Accent
                optButtons[selected].TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end,
    }
end

-- ============================================
-- COMPONENT: KEYBIND
-- ============================================
function Tab:AddKeybind(label, defaultKey, callback)
    self._layoutIdx = self._layoutIdx + 1
    local idx = self._layoutIdx
    local T = self._gui.T

    local boundKey = defaultKey or Enum.KeyCode.None
    local listening = false

    local container = Instance.new("Frame")
    container.Name = "Keybind_" .. label
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = T.Element
    container.BorderSizePixel = 0
    container.LayoutOrder = idx
    container.Parent = self._page
    corner(container, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -100, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = T.TextPrimary
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container

    local keyBtn = Instance.new("TextButton")
    keyBtn.Name = "KeyButton"
    keyBtn.Size = UDim2.new(0, 80, 0, 24)
    keyBtn.Position = UDim2.new(1, -88, 0.5, -12)
    keyBtn.BackgroundColor3 = T.SliderTrack
    keyBtn.BorderSizePixel = 0
    keyBtn.Text = boundKey ~= Enum.KeyCode.None and boundKey.Name or "None"
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 11
    keyBtn.TextColor3 = T.TextSecondary
    keyBtn.AutoButtonColor = false
    keyBtn.Parent = container
    corner(keyBtn, 4)

    local keyConn = nil

    local function startListening()
        listening = true
        keyBtn.Text = "..."
        tw(keyBtn, {BackgroundColor3 = T.Accent, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.15):Play()

        keyConn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
                    boundKey = Enum.KeyCode.None
                    keyBtn.Text = "None"
                elseif input.UserInputType == Enum.UserInputType.Keyboard then
                    boundKey = input.KeyCode
                    keyBtn.Text = boundKey.Name
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                    boundKey = Enum.KeyCode.ButtonR1 -- Placeholder for mouse
                    keyBtn.Text = "MB1"
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                    boundKey = Enum.KeyCode.ButtonR2
                    keyBtn.Text = "MB2"
                end

                listening = false
                tw(keyBtn, {BackgroundColor3 = T.SliderTrack, TextColor3 = T.TextSecondary}, 0.15):Play()
                if keyConn then keyConn:Disconnect() keyConn = nil end
                if callback then callback(boundKey) end
            end
        end)
    end

    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        startListening()
    end)

    table.insert(self._elements, {
        type = "keybind", container = container, keyBtn = keyBtn, label = lbl,
    })

    return {
        Get = function() return boundKey end,
        Set = function(k) boundKey = k keyBtn.Text = k ~= Enum.KeyCode.None and k.Name or "None" end,
    }
end

-- ============================================
-- COMPONENT: BUTTON
-- ============================================
function Tab:AddButton(label, callback)
    self._layoutIdx = self._layoutIdx + 1
    local idx = self._layoutIdx
    local T = self._gui.T

    local btn = Instance.new("TextButton")
    btn.Name = "Button_" .. label
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = T.Accent
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.AutoButtonColor = false
    btn.LayoutOrder = idx
    btn.Parent = self._page
    corner(btn, 6)

    btn.MouseEnter:Connect(function()
        tw(btn, {BackgroundColor3 = T.AccentHover}, 0.15):Play()
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, {BackgroundColor3 = T.Accent}, 0.15):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)

    table.insert(self._elements, {
        type = "button", container = btn, label = nil,
    })

    return btn
end

-- ============================================
-- COMPONENT: SECTION LABEL
-- ============================================
function Tab:AddSectionLabel(text)
    self._layoutIdx = self._layoutIdx + 1
    local idx = self._layoutIdx
    local T = self._gui.T

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Section_" .. text
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = text:upper()
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = T.TextSecondary
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = idx
    lbl.Parent = self._page

    table.insert(self._elements, {
        type = "section", container = lbl, label = lbl,
    })

    return lbl
end

-- ============================================
-- THEME UPDATE PER TAB
-- ============================================
function Tab:_updateTheme()
    local T = self._gui.T
    for _, el in ipairs(self._elements) do
        if el.type == "toggle" then
            el.container.BackgroundColor3 = T.Element
            el.label.TextColor3 = T.TextPrimary
            if el._state() then
                el.tBg.BackgroundColor3 = T.Accent
            else
                el.tBg.BackgroundColor3 = T.ToggleOff
            end
            el.tCircle.BackgroundColor3 = T.ToggleCircle
        elseif el.type == "slider" then
            el.container.BackgroundColor3 = T.Element
            el.label.TextColor3 = T.TextPrimary
            el.valLbl.TextColor3 = T.Accent
            el.track.BackgroundColor3 = T.SliderTrack
            el.fill.BackgroundColor3 = T.Accent
            el.handle.BackgroundColor3 = T.Accent
        elseif el.type == "dropdown" then
            el.container.BackgroundColor3 = T.Element
            el.label.TextColor3 = T.TextSecondary
            el.selBtn.BackgroundColor3 = T.SliderTrack
            el.selBtn.TextColor3 = T.TextPrimary
            el.arrow.TextColor3 = T.TextSecondary
            for _, ob in ipairs(el.optButtons) do
                if ob.BackgroundColor3 ~= T.Accent then
                    ob.BackgroundColor3 = T.SliderTrack
                end
                if ob.TextColor3 ~= Color3.fromRGB(255, 255, 255) then
                    ob.TextColor3 = T.TextPrimary
                end
            end
        elseif el.type == "keybind" then
            el.container.BackgroundColor3 = T.Element
            el.label.TextColor3 = T.TextPrimary
            el.keyBtn.BackgroundColor3 = T.SliderTrack
            el.keyBtn.TextColor3 = T.TextSecondary
        elseif el.type == "button" then
            el.container.BackgroundColor3 = T.Accent
        elseif el.type == "section" then
            el.label.TextColor3 = T.TextSecondary
        end
    end
    -- Update page scrollbar
    self._page.ScrollBarImageColor3 = T.Accent
end

-- ============================================
-- MAIN HACKSENSE CLASS
-- ============================================
local HackSense = {}
HackSense.__index = HackSense

function HackSense:New(config)
    config = config or {}
    local self = setmetatable({}, HackSense)

    self.Name = config.Name or "HackSense"
    self._themeName = config.Theme or "Blue"
    self.T = Themes[self._themeName] or Themes.Blue
    self._tabs = {}
    self._activeTab = nil
    self._open = true
    self._tabIndex = 0
    self._destroyed = false

    -- ScreenGui
    self._screenGui = Instance.new("ScreenGui")
    self._screenGui.Name = "HackSense_" .. self.Name
    self._screenGui.ResetOnSpawn = false
    self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self._screenGui.DisplayOrder = 99
    self._screenGui.Parent = playerGui

    -- Main Frame
    self.Frame = Instance.new("Frame")
    self.Frame.Name = "Main"
    self.Frame.Size = UDim2.new(0, 420, 0, 280)
    self.Frame.Position = UDim2.new(0.5, -210, 0.5, -140)
    self.Frame.BackgroundColor3 = self.T.Background
    self.Frame.BorderSizePixel = 0
    self.Frame.ClipsDescendants = true
    self.Frame.Parent = self._screenGui
    corner(self.Frame, 8)

    -- Top Bar
    self._topBar = Instance.new("Frame")
    self._topBar.Name = "TopBar"
    self._topBar.Size = UDim2.new(1, 0, 0, 32)
    self._topBar.BackgroundColor3 = self.T.Sidebar
    self._topBar.BorderSizePixel = 0
    self._topBar.ZIndex = 5
    self._topBar.Parent = self.Frame
    corner(self._topBar, 8)

    -- Cover bottom corners of topbar
    local topFix = Instance.new("Frame")
    topFix.Size = UDim2.new(1, 0, 0, 12)
    topFix.Position = UDim2.new(0, 0, 1, -12)
    topFix.BackgroundColor3 = self.T.Sidebar
    topFix.BorderSizePixel = 0
    topFix.ZIndex = 4
    topFix.Parent = self._topBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = self.Name
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextColor3 = self.T.TextPrimary
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 6
    titleLabel.Parent = self._topBar

    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 14, 0, 14)
    minBtn.Position = UDim2.new(1, -42, 0.5, -7)
    minBtn.BackgroundColor3 = Color3.fromRGB(220, 180, 50)
    minBtn.Text = ""
    minBtn.BorderSizePixel = 0
    minBtn.AutoButtonColor = false
    minBtn.ZIndex = 6
    minBtn.Parent = self._topBar
    corner(minBtn, 7)

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 14, 0, 14)
    closeBtn.Position = UDim2.new(1, -22, 0.5, -7)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeBtn.Text = ""
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 6
    closeBtn.Parent = self._topBar
    corner(closeBtn, 7)

    minBtn.MouseButton1Click:Connect(function() self:Toggle() end)
    closeBtn.MouseButton1Click:Connect(function() self:Destroy() end)

    -- Hover effects for buttons
    minBtn.MouseEnter:Connect(function() tw(minBtn, {BackgroundColor3 = Color3.fromRGB(240, 200, 60)}, 0.12):Play() end)
    minBtn.MouseLeave:Connect(function() tw(minBtn, {BackgroundColor3 = Color3.fromRGB(220, 180, 50)}, 0.12):Play() end)
    closeBtn.MouseEnter:Connect(function() tw(closeBtn, {BackgroundColor3 = Color3.fromRGB(240, 70, 70)}, 0.12):Play() end)
    closeBtn.MouseLeave:Connect(function() tw(closeBtn, {BackgroundColor3 = Color3.fromRGB(220, 50, 50)}, 0.12):Play() end)

    -- Sidebar
    self._sidebar = Instance.new("Frame")
    self._sidebar.Name = "Sidebar"
    self._sidebar.Size = UDim2.new(0, 44, 1, -32)
    self._sidebar.Position = UDim2.new(0, 0, 0, 32)
    self._sidebar.BackgroundColor3 = self.T.Sidebar
    self._sidebar.BorderSizePixel = 0
    self._sidebar.Parent = self.Frame

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 2)
    sidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    sidebarLayout.Parent = self._sidebar

    local sidebarPad = Instance.new("UIPadding")
    sidebarPad.PaddingTop = UDim.new(0, 8)
    sidebarPad.PaddingLeft = UDim.new(0, 4)
    sidebarPad.PaddingRight = UDim.new(0, 4)
    sidebarPad.Parent = self._sidebar

    -- Content Area
    self._contentArea = Instance.new("Frame")
    self._contentArea.Name = "Content"
    self._contentArea.Size = UDim2.new(1, -44, 1, -32)
    self._contentArea.Position = UDim2.new(0, 44, 0, 32)
    self._contentArea.BackgroundTransparency = 1
    self._contentArea.ClipsDescendants = true
    self._contentArea.Parent = self.Frame

    -- ============================================
    -- SMOOTH DRAG SYSTEM (Lerp-based)
    -- ============================================
    self._dragging = false
    self._dragStart = nil
    self._startPos = nil
    self._dragTarget = nil

    self._topBar.InputBegan:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._dragging = true
            self._dragStart = input.Position
            self._startPos = self.Frame.Position
            self._dragTarget = self._startPos

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    self._dragging = false
                end
            end)
        end
    end)

    self._topBar.InputChanged:Connect(function(input)
        if self._dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - self._dragStart
            self._dragTarget = UDim2.new(
                self._startPos.X.Scale,
                self._startPos.X.Offset + delta.X,
                self._startPos.Y.Scale,
                self._startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Lerp loop for smooth drag
    self._renderConn = RunService.RenderStepped:Connect(function()
        if self._destroyed then return end
        if self._dragTarget and self._dragging then
            local cf = self.Frame.Position
            local tg = self._dragTarget
            local s = 0.18
            self.Frame.Position = UDim2.new(
                cf.X.Scale + (tg.X.Scale - cf.X.Scale) * s,
                cf.X.Offset + (tg.X.Offset - cf.X.Offset) * s,
                cf.Y.Scale + (tg.Y.Scale - cf.Y.Scale) * s,
                cf.Y.Offset + (tg.Y.Offset - cf.Y.Offset) * s
            )
        end
    end)

    -- Load notification
    self:_notify(self.Name .. " loaded.")

    return self
end

-- ============================================
-- TAB SWITCHING
-- ============================================
function HackSense:_switchTab(newTab)
    if self._activeTab == newTab then return end

    -- Deactivate old
    if self._activeTab then
        self._activeTab:_deactivate()
        -- Slide out old page
        local oldPage = self._activeTab._page
        tw(oldPage, {Position = UDim2.new(-0.3, 0, 0, 0)}, 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.In):Play()
        task.delay(0.15, function()
            oldPage.Visible = false
            oldPage.Position = UDim2.new(0, 0, 0, 0)
        end)
    end

    -- Activate new
    self._activeTab = newTab
    newTab:_activate()
    newTab._page.Visible = true
    newTab._page.Position = UDim2.new(0.3, 0, 0, 0)
    newTab._page.CanvasPosition = Vector2.new(0, 0)
    tw(newTab._page, {Position = UDim2.new(0, 0, 0, 0)}, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
end

-- ============================================
-- ADD TAB
-- ============================================
function HackSense:AddTab(name, iconId)
    self._tabIndex = self._tabIndex + 1
    local tab = Tab.new(self, name, iconId or "", self._tabIndex)
    table.insert(self._tabs, tab)

    -- Auto-select first tab
    if #self._tabs == 1 then
        self:_switchTab(tab)
    end

    return tab
end

-- ============================================
-- SET THEME
-- ============================================
function HackSense:SetTheme(themeName)
    local newTheme = Themes[themeName]
    if not newTheme then return end

    self._themeName = themeName
    self.T = newTheme

    -- Update main GUI
    self.Frame.BackgroundColor3 = newTheme.Background
    self._topBar.BackgroundColor3 = newTheme.Sidebar
    self._topBar:FindFirstChild("Frame").BackgroundColor3 = newTheme.Sidebar
    self._sidebar.BackgroundColor3 = newTheme.Sidebar
    self._topBar:FindFirstChildOfClass("TextLabel").TextColor3 = newTheme.TextPrimary

    -- Update tabs
    for _, tab in ipairs(self._tabs) do
        tab:_updateTheme()
        -- Update active tab highlight
        if self._activeTab == tab then
            tab:_activate()
        else
            tab:_deactivate()
        end
    end
end

-- ============================================
-- TOGGLE VISIBILITY
-- ============================================
function HackSense:Toggle()
    self._open = not self._open
    if self._open then
        self.Frame.Visible = true
        self.Frame.Size = UDim2.new(0, 420, 0, 0)
        tw(self.Frame, {Size = UDim2.new(0, 420, 0, 280)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
    else
        tw(self.Frame, {Size = UDim2.new(0, 420, 0, 32)}, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In):Play()
        task.delay(0.2, function()
            if not self._open then
                self.Frame.Size = UDim2.new(0, 420, 0, 280)
                self.Frame.Visible = false
            end
        end)
    end
end

-- ============================================
-- DESTROY
-- ============================================
function HackSense:Destroy()
    self._destroyed = true
    if self._renderConn then
        self._renderConn:Disconnect()
        self._renderConn = nil
    end
    if self._screenGui then
        self._screenGui:Destroy()
        self._screenGui = nil
    end
end

-- ============================================
-- BIND TOGGLE KEY
-- ============================================
function HackSense:BindToggle(keyCode)
    UserInputService.InputBegan:Connect(function(input, processed)
        if self._destroyed then return end
        if processed then return end
        if input.KeyCode == keyCode then
            self:Toggle()
        end
    end)
end

-- ============================================
-- NOTIFICATION TOAST
-- ============================================
function HackSense:_notify(text)
    local toast = Instance.new("TextLabel")
    toast.Size = UDim2.new(0, 180, 0, 36)
    toast.Position = UDim2.new(0.5, -90, 0, -50)
    toast.BackgroundColor3 = self.T.Sidebar
    toast.TextColor3 = self.T.TextPrimary
    toast.Text = text
    toast.Font = Enum.Font.GothamSemibold
    toast.TextSize = 12
    toast.BorderSizePixel = 0
    toast.BackgroundTransparency = 0
    toast.ZIndex = 100
    toast.Parent = self._screenGui
    corner(toast, 6)

    tw(toast, {Position = UDim2.new(0.5, -90, 0, 12)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
    task.delay(2, function()
        if not toast or not toast.Parent then return end
        tw(toast, {Position = UDim2.new(0.5, -90, 0, -50), BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In):Play()
        task.delay(0.3, function()
            if toast and toast.Parent then toast:Destroy() end
        end)
    end)
end

-- ============================================
-- RETURN MODULE
-- ============================================
return HackSense