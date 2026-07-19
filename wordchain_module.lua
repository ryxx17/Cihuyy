-- =====================================================================
-- MODUL: WORD CHAIN (Syndra) -- dijalankan oleh syndra_core.lua lewat
-- loadstring(...)(Core). Semua nama di bawah ini diambil dari Core supaya
-- tidak perlu membangun ulang GUI/utilitas yang sudah ada di core.
-- =====================================================================
return function(Core)
    Core.SendNotification("[MODUL] 0/8 - Modul mulai dijalankan", 2)
    local Players          = Core.Players
    local TweenService     = Core.TweenService
    local ContentProvider  = Core.ContentProvider
    local LocalPlayer      = Core.LocalPlayer
    local PlayerGui        = Core.PlayerGui

    local SG          = Core.SG
    local MainFrame    = Core.MainFrame
    local SidebarTabs  = Core.SidebarTabs

    local C          = Core.C
    local TWEEN_INFO = Core.TWEEN_INFO
    local ApplyPressAnimation = Core.ApplyPressAnimation

    local CreateToggle       = Core.CreateToggle
    local CreateDropdown     = Core.CreateDropdown
    local CreatePageContainer = Core.CreatePageContainer
    local CreateSidebarTab    = Core.CreateSidebarTab

    local SendNotification = Core.SendNotification
    local NotifyAfterMenu  = Core.NotifyAfterMenu
    local FormatRibuan     = Core.FormatRibuan

    local State = Core.State
    -- Field khusus game ini ditambahkan ke State bersama milik Core
    State.active         = false
    State.pushIndexMode  = false
    State.humanMode      = false
    State.autoJoinMode   = false
    State.currentLetter  = ""
    State.kbbiReady      = false
    State.kbbiFailed     = false
    State.wordCount      = 0
    State.pool2          = {}
    State.pool3          = {}
    State.isSpoofed      = false

    -- Pengaman: kalau salah satu ini kosong, mending berhenti sekarang dengan
    -- pesan jelas daripada lanjut bikin ratusan elemen UI yang nggak nempel
    -- ke mana-mana (parent-nya nil) tapi kelihatan "sukses" tanpa error.
    assert(MainFrame, "Core.MainFrame kosong -- modul tidak bisa nempelin UI apapun")
    assert(CreateToggle, "Core.CreateToggle kosong")
    assert(CreateDropdown, "Core.CreateDropdown kosong")
    assert(CreatePageContainer, "Core.CreatePageContainer kosong")
    assert(CreateSidebarTab, "Core.CreateSidebarTab kosong")
    assert(C, "Core.C (palet warna) kosong")
    Core.SendNotification("[MODUL] 0.5/8 - Semua elemen dari Core terverifikasi ada", 2)

    -- Data kata KBBI khusus modul ini (tidak dipakai game lain)
    local Prefix1, Prefix2, EndsWith = {}, {}, {}

-- FORWARD DECLARATION: elemen yang perlu diakses dari LUAR blok halaman
-- (supaya PAGE 1 & PAGE 2 bisa dibungkus do...end tanpa merusak akses ini)
-- =====================================================================
local LblAwalan, LblKBBI, LblIndex, LblStats

-- =====================================================================
-- PAGE 1: GAMEPLAY (dengan tab GAMEPLAY / SPEEDSETTING / AKHIRAN / KEAMANAN)
-- =====================================================================
do -- <== BUNGKUS MEMORI PAGE 1 (bebaskan slot local variable setelah page ini selesai dibuat)
local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size             = UDim2.new(1, -60, 1, -50)
ContentFrame.Position         = UDim2.new(0, 60, 0, 50)
ContentFrame.BackgroundColor3 = C.BG_DARKER
ContentFrame.BorderSizePixel  = 0
Instance.new("UICorner", ContentFrame).CornerRadius = UDim.new(0, 12)

-- Patch sudut kiri
local PatchTop = Instance.new("Frame", ContentFrame)
PatchTop.Size             = UDim2.new(1, 0, 0, 15)
PatchTop.BackgroundColor3 = C.BG_DARKER
PatchTop.BorderSizePixel  = 0

local PatchLeft = Instance.new("Frame", ContentFrame)
PatchLeft.Size             = UDim2.new(0, 15, 1, 0)
PatchLeft.BackgroundColor3 = C.BG_DARKER
PatchLeft.BorderSizePixel  = 0

-- Sub-halaman Gameplay
local GameplayContentPage = Instance.new("Frame", ContentFrame)
GameplayContentPage.Size               = UDim2.new(1, 0, 1, 0)
GameplayContentPage.BackgroundTransparency = 1
GameplayContentPage.Visible            = true

local SpeedsettingContentPage = Instance.new("Frame", ContentFrame)
SpeedsettingContentPage.Size               = UDim2.new(1, 0, 1, 0)
SpeedsettingContentPage.BackgroundTransparency = 1
SpeedsettingContentPage.Visible            = false

local AkhiranContentPage = Instance.new("Frame", ContentFrame)
AkhiranContentPage.Size               = UDim2.new(1, 0, 1, 0)
AkhiranContentPage.BackgroundTransparency = 1
AkhiranContentPage.Visible            = false

local KeamananContentPage = Instance.new("Frame", ContentFrame)
KeamananContentPage.Size               = UDim2.new(1, 0, 1, 0)
KeamananContentPage.BackgroundTransparency = 1
KeamananContentPage.Visible            = false

-- TOP NAV BAR (tab teks di atas)
local TopNav = Instance.new("Frame", MainFrame)
TopNav.Size               = UDim2.new(1, -60, 0, 50)
TopNav.Position           = UDim2.new(0, 60, 0, 0)
TopNav.BackgroundTransparency = 1

local NavLayout = Instance.new("UIListLayout", TopNav)
NavLayout.FillDirection      = Enum.FillDirection.Horizontal
NavLayout.SortOrder          = Enum.SortOrder.LayoutOrder
NavLayout.Padding            = UDim.new(0, 25)
NavLayout.VerticalAlignment  = Enum.VerticalAlignment.Center

local NavPadding = Instance.new("UIPadding", TopNav)
NavPadding.PaddingLeft = UDim.new(0, 30)

local Tabs = {}
local function MakeTab(text, isActive, contentPage)
    local btn = Instance.new("TextButton", TopNav)
    btn.Size               = UDim2.new(0, 0, 1, 0)
    btn.AutomaticSize      = Enum.AutomaticSize.X
    btn.BackgroundTransparency = 1
    btn.Text               = text
    btn.TextColor3         = C.WHITE
    btn.Font               = Enum.Font.GothamMedium
    btn.TextSize           = 13
    btn.AutoButtonColor    = false

    local line = Instance.new("Frame", btn)
    line.Size             = UDim2.new(1, 0, 0, 2)
    line.Position         = UDim2.new(0, 0, 0.5, 10)
    line.BackgroundColor3 = C.UNDERLINE
    line.BorderSizePixel  = 0
    line.Visible          = isActive

    Tabs[text] = {Button = btn, Line = line, Content = contentPage}

    btn.MouseButton1Click:Connect(function()
        for _, td in pairs(Tabs) do
            td.Line.Visible = false
            if td.Content then td.Content.Visible = false end
        end
        line.Visible = true
        if contentPage then contentPage.Visible = true end
    end)
end

MakeTab("GAMEPLAY",     true,  GameplayContentPage)
MakeTab("SPEEDSETTING", false, SpeedsettingContentPage)
MakeTab("AKHIRAN",      false, AkhiranContentPage)
MakeTab("KEAMANAN",     false, KeamananContentPage)

-- =====================================================================
-- ISI GAMEPLAY: MENU KIRI (TOGGLE) + PANEL KANAN (INFO)
-- =====================================================================
local MenuContainer = Instance.new("Frame", GameplayContentPage)
MenuContainer.Size               = UDim2.new(0, 180, 1, -30)
MenuContainer.Position           = UDim2.new(0, 12, 0, 12)
MenuContainer.BackgroundTransparency = 1
Instance.new("UIListLayout", MenuContainer).Padding = UDim.new(0, 8)

-- Menghubungkan Toggle langsung ke State
local DisableAkhiranFilters, IsAkhiranActive -- forward declaration, diisi di bagian AKHIRAN (bawah)

CreateToggle(MenuContainer, "Auto Sambung Kata", function(state) State.active = state end)
local _, _, _, _, SetPushIndex = CreateToggle(MenuContainer, "Push Index", function(state)
    State.pushIndexMode = state
    if state and DisableAkhiranFilters then
        local akhiranWasActive = IsAkhiranActive and IsAkhiranActive()
        DisableAkhiranFilters()
        if akhiranWasActive then
            SendNotification("Push Index aktif, filter Akhiran dimatikan", 3)
        end
    end
end)
CreateToggle(MenuContainer, "Human Mode", function(state) State.humanMode = state end)
CreateToggle(MenuContainer, "Auto Join Meja", function(state) State.autoJoinMode = state end)

local RightPanel = Instance.new("Frame", GameplayContentPage)
RightPanel.Size             = UDim2.new(1, -216, 1, -24)
RightPanel.Position         = UDim2.new(0, 204, 0, 12)
RightPanel.BackgroundColor3 = C.BG_DARK
RightPanel.BorderSizePixel  = 0
Instance.new("UICorner", RightPanel).CornerRadius = UDim.new(0, 6)

local RightPadding = Instance.new("UIPadding", RightPanel)
RightPadding.PaddingLeft = UDim.new(0, 15)
RightPadding.PaddingTop  = UDim.new(0, 15)

local RightLayout = Instance.new("UIListLayout", RightPanel)
RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
RightLayout.Padding   = UDim.new(0, 4)

-- Fungsi MakeInfoText sekarang me-return label agar teksnya bisa diubah dari script
local function MakeInfoText(text, size, font, height)
    local lbl = Instance.new("TextLabel", RightPanel)
    lbl.Size               = UDim2.new(1, 0, 0, height)
    lbl.BackgroundTransparency = 1
    lbl.Text               = text
    lbl.TextColor3         = C.WHITE
    lbl.Font               = font
    lbl.TextSize           = size
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.TextYAlignment     = Enum.TextYAlignment.Top
    return lbl
end

-- Variabel untuk menampung UI yang akan diupdate secara real-time
LblAwalan = MakeInfoText("Kata Awalan: -", 22, Enum.Font.GothamMedium, 28)
LblKBBI   = MakeInfoText("KBBI: Memuat...\nDevice: Mobile", 13, Enum.Font.Gotham, 38)

local function Spacer(parent, h)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, h); f.BackgroundTransparency = 1
end

Spacer(RightPanel, 8)
MakeInfoText("Penyimpanan Index", 16, Enum.Font.GothamMedium, 20)
LblIndex  = MakeInfoText("Sisa Kata: 0\nKata dipakai saat ini: 0\nKata Dipakai Sebelumnya: 0", 13, Enum.Font.Gotham, 55)

Spacer(RightPanel, 8)
MakeInfoText("Data Player", 16, Enum.Font.GothamMedium, 20)
LblStats  = MakeInfoText("Winrate: 0%\nMenang: 0\nKalah: 0\nUang: Rp0", 13, Enum.Font.Gotham, 75)


-- =====================================================================
-- ISI SPEEDSETTING: PRESET + KONTROL NILAI
-- =====================================================================
-- Membuat memori pengaturan kecepatan (CFG) di dalam State
State.CFG = State.CFG or {
    ANS_MIN = 0.50, ANS_MAX = 1.00, KEY_MIN = 0.20, KEY_MAX = 0.40, 
    HOLD_MIN = 0.05, HOLD_MAX = 0.10, ENTER_MIN = 0.30, ENTER_MAX = 0.50, 
    DEL_MIN = 0.05, DEL_MAX = 0.10
}

local SpeedPresets = {
    Slow   = { ANS_MIN = 0.80, ANS_MAX = 1.50, KEY_MIN = 0.35, KEY_MAX = 0.55, ENTER_MIN = 0.40, ENTER_MAX = 0.60, DEL_MIN = 0.08, DEL_MAX = 0.15 },
    Normal = { ANS_MIN = 0.50, ANS_MAX = 1.00, KEY_MIN = 0.20, KEY_MAX = 0.40, ENTER_MIN = 0.30, ENTER_MAX = 0.50, DEL_MIN = 0.05, DEL_MAX = 0.10 },
    Fast   = { ANS_MIN = 0.20, ANS_MAX = 0.45, KEY_MIN = 0.05, KEY_MAX = 0.10, ENTER_MIN = 0.10, ENTER_MAX = 0.20, DEL_MIN = 0.02, DEL_MAX = 0.05 },
    Turbo  = { ANS_MIN = 0.05, ANS_MAX = 0.12, KEY_MIN = 0.01, KEY_MAX = 0.02, ENTER_MIN = 0.00, ENTER_MAX = 0.01, DEL_MIN = 0.01, DEL_MAX = 0.02 }
}

-- === POPUP WARNING UI ===
local WarningOverlay = Instance.new("Frame", MainFrame)
WarningOverlay.Size = UDim2.new(1, 0, 1, 0)
WarningOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
WarningOverlay.BackgroundTransparency = 0.5
WarningOverlay.ZIndex = 1000
WarningOverlay.Visible = false
WarningOverlay.Active = true 
Instance.new("UICorner", WarningOverlay).CornerRadius = UDim.new(0, 12)

-- Logika geser manual dibungkus pcall agar TIDAK ERROR di executor HP
pcall(function()
    local dragToggle, dragInput, dragStart, dragPos
    WarningOverlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragToggle = true
            dragStart = input.Position
            dragPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)
    WarningOverlay.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragToggle then
            local Delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + Delta.X, dragPos.Y.Scale, dragPos.Y.Offset + Delta.Y)
        end
    end)
end)

local WarnText1 = Instance.new("TextLabel", WarningOverlay)
WarnText1.Size = UDim2.new(1, -40, 0, 40)
WarnText1.Position = UDim2.new(0, 20, 0.5, -60)
WarnText1.BackgroundTransparency = 1
WarnText1.Text = "Fitur Ini Bisa Menyebabkan Ban Jika\nGunakan Terlalu Sering"
WarnText1.TextColor3 = C.WHITE
WarnText1.Font = Enum.Font.GothamBold
WarnText1.TextSize = 14
WarnText1.ZIndex = 1001

local WarnText2 = Instance.new("TextLabel", WarningOverlay)
WarnText2.Size = UDim2.new(1, -40, 0, 20)
WarnText2.Position = UDim2.new(0, 20, 0.5, -10)
WarnText2.BackgroundTransparency = 1
WarnText2.Text = "Apakah Anda Yakin Ingin Menyalakan fitur ini"
WarnText2.TextColor3 = C.WHITE
WarnText2.Font = Enum.Font.GothamBold
WarnText2.TextSize = 12
WarnText2.ZIndex = 1001

local BtnYes = Instance.new("TextButton", WarningOverlay)
BtnYes.Size = UDim2.new(0, 120, 0, 35)
BtnYes.Position = UDim2.new(0.5, -130, 0.5, 30)
BtnYes.BackgroundColor3 = C.ACCENT
BtnYes.Text = "IYA"
BtnYes.TextColor3 = C.WHITE
BtnYes.Font = Enum.Font.GothamBold
BtnYes.TextSize = 14
BtnYes.ZIndex = 1001
Instance.new("UICorner", BtnYes).CornerRadius = UDim.new(0, 6)

local BtnNo = Instance.new("TextButton", WarningOverlay)
BtnNo.Size = UDim2.new(0, 120, 0, 35)
BtnNo.Position = UDim2.new(0.5, 10, 0.5, 30)
BtnNo.BackgroundColor3 = C.ACCENT
BtnNo.Text = "TIDAK"
BtnNo.TextColor3 = C.WHITE
BtnNo.Font = Enum.Font.GothamBold
BtnNo.TextSize = 14
BtnNo.ZIndex = 1001
Instance.new("UICorner", BtnNo).CornerRadius = UDim.new(0, 6)

local confirmCallback = nil
BtnYes.MouseButton1Click:Connect(function()
    WarningOverlay.Visible = false
    if confirmCallback then confirmCallback() end
end)
BtnNo.MouseButton1Click:Connect(function()
    WarningOverlay.Visible = false
end)
-- ========================

local SpeedLeftContainer = Instance.new("Frame", SpeedsettingContentPage)
SpeedLeftContainer.Size               = UDim2.new(0, 320, 1, -30)
SpeedLeftContainer.Position           = UDim2.new(0, 12, 0, 12)
SpeedLeftContainer.BackgroundTransparency = 1

local SpeedLayout = Instance.new("UIListLayout", SpeedLeftContainer)
SpeedLayout.SortOrder = Enum.SortOrder.LayoutOrder
SpeedLayout.Padding   = UDim.new(0, 12)

-- Kotak Preset Instan
local PresetBox = Instance.new("Frame", SpeedLeftContainer)
PresetBox.Size             = UDim2.new(1, 0, 0, 80)
PresetBox.BackgroundColor3 = C.BG_DARK
PresetBox.BorderSizePixel  = 0
Instance.new("UICorner", PresetBox).CornerRadius = UDim.new(0, 6)

local PresetPad = Instance.new("UIPadding", PresetBox)
PresetPad.PaddingLeft = UDim.new(0, 16)
PresetPad.PaddingTop  = UDim.new(0, 12)

local PresetTitle = Instance.new("TextLabel", PresetBox)
PresetTitle.Size               = UDim2.new(1, 0, 0, 16)
PresetTitle.BackgroundTransparency = 1
PresetTitle.Text               = "Preset Instan"
PresetTitle.TextColor3         = C.WHITE
PresetTitle.Font               = Enum.Font.Gotham
PresetTitle.TextSize           = 12
PresetTitle.TextXAlignment     = Enum.TextXAlignment.Left

local ButtonRow = Instance.new("Frame", PresetBox)
ButtonRow.Size               = UDim2.new(1, -16, 0, 28)
ButtonRow.Position           = UDim2.new(0, 0, 0, 26)
ButtonRow.BackgroundTransparency = 1

local RowLayout = Instance.new("UIListLayout", ButtonRow)
RowLayout.FillDirection = Enum.FillDirection.Horizontal
RowLayout.Padding       = UDim.new(0, 8)

local UIUpdaters = {}

local function CreatePresetBtn(name)
    local btn = Instance.new("TextButton", ButtonRow)
    btn.Size             = UDim2.new(0.25, -6, 1, 0)
    btn.BackgroundColor3 = C.ACCENT
    btn.Text             = name
    btn.TextColor3       = C.WHITE
    btn.Font             = Enum.Font.GothamMedium
    btn.TextSize         = 12
    btn.AutoButtonColor  = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    ApplyPressAnimation(btn)

    btn.MouseButton1Click:Connect(function()
        local data = SpeedPresets[name]
        if not data then return end
        
        local function applyPreset()
            for k, v in pairs(data) do
                State.CFG[k] = v
                if UIUpdaters[k] then UIUpdaters[k]() end
            end
        end
        
        if name == "Fast" or name == "Turbo" then
            confirmCallback = applyPreset
            WarningOverlay.Visible = true
        else
            applyPreset()
        end
    end)
end

for _, name in ipairs({"Slow","Normal","Fast","Turbo"}) do CreatePresetBtn(name) end

-- Kotak pengaturan nilai
local SpeedBottomBox = Instance.new("Frame", SpeedLeftContainer)
SpeedBottomBox.Size             = UDim2.new(1, 0, 1, -92)
SpeedBottomBox.BackgroundColor3 = C.BG_DARK
SpeedBottomBox.BorderSizePixel  = 0
Instance.new("UICorner", SpeedBottomBox).CornerRadius = UDim.new(0, 6)

local BBPad = Instance.new("UIPadding", SpeedBottomBox)
BBPad.PaddingLeft = UDim.new(0, 16)
BBPad.PaddingTop  = UDim.new(0, 12)

local BBLayout = Instance.new("UIListLayout", SpeedBottomBox)
BBLayout.SortOrder = Enum.SortOrder.LayoutOrder
BBLayout.Padding   = UDim.new(0, 12)

local BBTitle = Instance.new("TextLabel", SpeedBottomBox)
BBTitle.Size               = UDim2.new(1, 0, 0, 16)
BBTitle.BackgroundTransparency = 1
BBTitle.Text               = "Pengaturan Kecepatan"
BBTitle.TextColor3         = C.WHITE
BBTitle.Font               = Enum.Font.GothamMedium
BBTitle.TextSize           = 12
BBTitle.TextXAlignment     = Enum.TextXAlignment.Left
BBTitle.LayoutOrder        = 1

local function CreateSpeedRow(text, rowOrder, minKey, maxKey)
    local Row = Instance.new("Frame", SpeedBottomBox)
    Row.Size               = UDim2.new(1, -16, 0, 24)
    Row.BackgroundTransparency = 1
    Row.LayoutOrder        = rowOrder

    local RL = Instance.new("UIListLayout", Row)
    RL.FillDirection      = Enum.FillDirection.Horizontal
    RL.VerticalAlignment  = Enum.VerticalAlignment.Center
    RL.SortOrder          = Enum.SortOrder.LayoutOrder
    RL.Padding            = UDim.new(0, 10)

    local TL = Instance.new("TextLabel", Row)
    TL.Size               = UDim2.new(0, 56, 1, 0)
    TL.BackgroundTransparency = 1
    TL.Text               = text
    TL.TextColor3         = C.WHITE
    TL.Font               = Enum.Font.Gotham
    TL.TextSize           = 12
    TL.TextXAlignment     = Enum.TextXAlignment.Left
    TL.LayoutOrder        = 1

    local function CreateControlSet(orderIndex, cfgKey)
        local CC = Instance.new("Frame", Row)
        CC.Size               = UDim2.new(0, 88, 1, 0)
        CC.BackgroundTransparency = 1
        CC.LayoutOrder        = orderIndex

        local CL = Instance.new("UIListLayout", CC)
        CL.FillDirection = Enum.FillDirection.Horizontal
        CL.SortOrder     = Enum.SortOrder.LayoutOrder
        CL.Padding       = UDim.new(0, 4)

        local MinBtn = Instance.new("TextButton", CC)
        MinBtn.Size             = UDim2.new(0, 24, 1, 0)
        MinBtn.BackgroundColor3 = C.ACCENT
        MinBtn.Text             = "<"
        MinBtn.TextColor3       = C.WHITE
        MinBtn.Font             = Enum.Font.GothamBold
        MinBtn.TextSize         = 14
        MinBtn.AutoButtonColor  = false
        MinBtn.LayoutOrder      = 1
        Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 4)
        ApplyPressAnimation(MinBtn)

        local ValLbl = Instance.new("TextLabel", CC)
        ValLbl.Size             = UDim2.new(0, 32, 1, 0)
        ValLbl.BackgroundColor3 = C.ACCENT
        ValLbl.Text             = string.format("%.2f", State.CFG[cfgKey])
        ValLbl.TextColor3       = C.WHITE
        ValLbl.Font             = Enum.Font.GothamMedium
        ValLbl.TextSize         = 12
        ValLbl.LayoutOrder      = 2
        Instance.new("UICorner", ValLbl).CornerRadius = UDim.new(0, 4)

        local PlusBtn = Instance.new("TextButton", CC)
        PlusBtn.Size             = UDim2.new(0, 24, 1, 0)
        PlusBtn.BackgroundColor3 = C.ACCENT
        PlusBtn.Text             = ">"
        PlusBtn.TextColor3       = C.WHITE
        PlusBtn.Font             = Enum.Font.GothamBold
        PlusBtn.TextSize         = 14
        PlusBtn.AutoButtonColor  = false
        PlusBtn.LayoutOrder      = 3
        Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0, 4)
        ApplyPressAnimation(PlusBtn)

        MinBtn.MouseButton1Click:Connect(function()
            if State.CFG[cfgKey] > 0 then
                State.CFG[cfgKey] = math.floor((State.CFG[cfgKey] - 0.01) * 100 + 0.5) / 100
                ValLbl.Text = string.format("%.2f", State.CFG[cfgKey])
            end
        end)

        PlusBtn.MouseButton1Click:Connect(function()
            State.CFG[cfgKey] = math.floor((State.CFG[cfgKey] + 0.01) * 100 + 0.5) / 100
            ValLbl.Text = string.format("%.2f", State.CFG[cfgKey])
        end)

        UIUpdaters[cfgKey] = function()
            ValLbl.Text = string.format("%.2f", State.CFG[cfgKey])
        end
    end

    CreateControlSet(2, minKey)

    local Sep = Instance.new("TextLabel", Row)
    Sep.Size               = UDim2.new(0, 10, 1, 0)
    Sep.BackgroundTransparency = 1
    Sep.Text               = "-"
    Sep.TextColor3         = C.WHITE
    Sep.Font               = Enum.Font.GothamBold
    Sep.TextSize           = 14
    Sep.LayoutOrder        = 3

    CreateControlSet(4, maxKey)
end

CreateSpeedRow("DELAY",  2, "ANS_MIN", "ANS_MAX")
CreateSpeedRow("KETIK",  3, "KEY_MIN", "KEY_MAX")
CreateSpeedRow("ENTER",  4, "ENTER_MIN", "ENTER_MAX")
CreateSpeedRow("DELETE", 5, "DEL_MIN", "DEL_MAX")


-- =====================================================================
-- ISI AKHIRAN: DROPDOWN AKHIRAN 1/2 + TOGGLE PILIH SEMUA
-- =====================================================================
local AkhiranLeftContainer = Instance.new("Frame", AkhiranContentPage)
AkhiranLeftContainer.Size               = UDim2.new(0, 320, 1, -30)
AkhiranLeftContainer.Position           = UDim2.new(0, 12, 0, 12)
AkhiranLeftContainer.BackgroundTransparency = 1

local AkhiranLayout = Instance.new("UIListLayout", AkhiranLeftContainer)
AkhiranLayout.SortOrder = Enum.SortOrder.LayoutOrder
AkhiranLayout.Padding   = UDim.new(0, 12)

local function MakeAkhiranBox(zIndex, titleText)
    local Box = Instance.new("Frame", AkhiranLeftContainer)
    Box.Size             = UDim2.new(1, 0, 0, 50)
    Box.BackgroundColor3 = C.BG_DARK
    Box.BorderSizePixel  = 0
    Box.ZIndex           = zIndex
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)

    local Lbl = Instance.new("TextLabel", Box)
    Lbl.Size               = UDim2.new(1, -80, 1, 0)
    Lbl.Position           = UDim2.new(0, 15, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text               = titleText
    Lbl.TextColor3         = C.WHITE
    Lbl.Font               = Enum.Font.Gotham
    Lbl.TextSize           = 12
    Lbl.TextXAlignment     = Enum.TextXAlignment.Left
    Lbl.ZIndex             = zIndex

    local Btn = Instance.new("TextButton", Box)
    Btn.Size             = UDim2.new(0, 60, 0, 24)
    Btn.Position         = UDim2.new(1, -75, 0.5, -12)
    Btn.BackgroundColor3 = C.ACCENT
    Btn.Text             = "Off"
    Btn.TextColor3       = C.WHITE
    Btn.Font             = Enum.Font.GothamMedium
    Btn.TextSize         = 11
    Btn.AutoButtonColor  = true
    Btn.ZIndex           = zIndex
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)

    return Box, Btn
end

local AkhiranBox1, DropdownBtn1 = MakeAkhiranBox(10, "Akhiran 1 Kata")
local AkhiranBox2, DropdownBtn2 = MakeAkhiranBox(5,  "Akhiran 2 Kata")

-- Toggle Pilih Semua
local AkhiranBox3 = Instance.new("Frame", AkhiranLeftContainer)
AkhiranBox3.Size             = UDim2.new(0.55, 0, 0, 50)
AkhiranBox3.BackgroundColor3 = C.BG_DARK
AkhiranBox3.BorderSizePixel  = 0
Instance.new("UICorner", AkhiranBox3).CornerRadius = UDim.new(0, 6)

local Title3 = Instance.new("TextLabel", AkhiranBox3)
Title3.Size               = UDim2.new(1, -20, 0, 15)
Title3.Position           = UDim2.new(0, 15, 0, 8)
Title3.BackgroundTransparency = 1
Title3.Text               = "Pilih Semua"
Title3.TextColor3         = C.WHITE
Title3.Font               = Enum.Font.Gotham
Title3.TextSize           = 12
Title3.TextXAlignment     = Enum.TextXAlignment.Left

local ToggleBg3 = Instance.new("TextButton", AkhiranBox3)
ToggleBg3.Size             = UDim2.new(0, 36, 0, 16)
ToggleBg3.Position         = UDim2.new(0, 15, 0, 26)
ToggleBg3.BackgroundColor3 = C.WHITE
ToggleBg3.Text             = ""
ToggleBg3.AutoButtonColor  = false
Instance.new("UICorner", ToggleBg3).CornerRadius = UDim.new(1, 0)

local ToggleKnob3 = Instance.new("Frame", ToggleBg3)
ToggleKnob3.Size             = UDim2.new(0, 12, 0, 12)
ToggleKnob3.Position         = UDim2.new(0, 2, 0.5, -6)
ToggleKnob3.BackgroundColor3 = C.ACCENT
Instance.new("UICorner", ToggleKnob3).CornerRadius = UDim.new(1, 0)

local drop1, drop2
local val1, val2 = "Off", "Off"
local isAll = false

local function TurnOffToggle()
    if not isAll then return end
    isAll = false
    TweenService:Create(ToggleKnob3, TWEEN_INFO, {Position = UDim2.new(0, 2, 0.5, -6)}):Play()
    TweenService:Create(ToggleBg3,   TWEEN_INFO, {BackgroundColor3 = C.WHITE}):Play()
end

local function OnSelect1(v)
    if v ~= "Off" and State.pushIndexMode then
        SetPushIndex(false)
        SendNotification("Filter Akhiran aktif, Push Index dimatikan", 3)
    end
    val1 = v
    if v ~= "Off" then 
        val2 = "Off"
        if drop2 then drop2.SetSelected("Off") end 
        State.priorityEnd = v
    else
        State.priorityEnd = (val2 ~= "Off" and val2) or "OFF"
    end
    TurnOffToggle()
    if drop1 then drop1.SetSelected(val1); drop1.Container.Visible = false end
end

local function OnSelect2(v)
    if v ~= "Off" and State.pushIndexMode then
        SetPushIndex(false)
        SendNotification("Filter Akhiran aktif, Push Index dimatikan", 3)
    end
    val2 = v
    if v ~= "Off" then 
        val1 = "Off"
        if drop1 then drop1.SetSelected("Off") end 
        State.priorityEnd = v
    else
        State.priorityEnd = (val1 ~= "Off" and val1) or "OFF"
    end
    TurnOffToggle()
    if drop2 then drop2.SetSelected(val2); drop2.Container.Visible = false end
end

drop1 = CreateDropdown(DropdownBtn1, {"Off","a","b","c","f","v","x","z","y","i","u","n"}, OnSelect1)
drop1.SetSelected("Off")
drop2 = CreateDropdown(DropdownBtn2, {"Off","cy","if","ex","eh","ah","az","as"}, OnSelect2)
drop2.SetSelected("Off")

-- Cek apakah ada filter Akhiran yang sedang aktif (dipakai buat keputusan tampilkan notif atau tidak)
IsAkhiranActive = function()
    return val1 ~= "Off" or val2 ~= "Off" or isAll
end

-- Reset semua filter Akhiran ke Off (dipanggil saat Push Index dinyalakan)
DisableAkhiranFilters = function()
    val1, val2 = "Off", "Off"
    if drop1 then drop1.SetSelected("Off") end
    if drop2 then drop2.SetSelected("Off") end
    TurnOffToggle() -- isAll masih apa adanya di sini, jadi animasi toggle "Pilih Semua" ikut jalan kalau lagi ON
    State.priorityEnd = "OFF"
end

ToggleBg3.MouseButton1Click:Connect(function()
    if not isAll and State.pushIndexMode then
        SetPushIndex(false)
        SendNotification("Filter Akhiran aktif, Push Index dimatikan", 3)
    end
    isAll = not isAll
    if isAll then
        drop1.SetSelected(val1, "All")
        drop2.SetSelected(val2, "All")
        State.priorityEnd = "ALL"
    else
        drop1.SetSelected(val1)
        drop2.SetSelected(val2)
        State.priorityEnd = (val1 ~= "Off" and val1) or (val2 ~= "Off" and val2) or "OFF"
    end
    local pos   = isAll and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    local color = isAll and C.ACCENT_LT or C.WHITE
    TweenService:Create(ToggleKnob3, TWEEN_INFO, {Position = pos}):Play()
    TweenService:Create(ToggleBg3,   TWEEN_INFO, {BackgroundColor3 = color}):Play()
end)

-- =====================================================================
-- ISI KEAMANAN: TOGGLE & LOGIKA ANTI ADMIN
-- =====================================================================
local KeamananLeftContainer = Instance.new("Frame", KeamananContentPage)
KeamananLeftContainer.Size               = UDim2.new(0, 180, 1, -30)
KeamananLeftContainer.Position           = UDim2.new(0, 12, 0, 12)
KeamananLeftContainer.BackgroundTransparency = 1
Instance.new("UIListLayout", KeamananLeftContainer).Padding = UDim.new(0, 8)

State.antiAdminMode = false
State.isHopping = false

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local function ServerHop()
    if State.isHopping then return end
    State.isHopping = true
    
    task.spawn(function()
        pcall(function()
            local placeId = game.PlaceId
            local req = game:HttpGet("https://games.roblox.com/v1/games/"..tostring(placeId).."/servers/Public?sortOrder=Desc&limit=100")
            if req then
                local data = HttpService:JSONDecode(req)
                if data and data.data then
                    local validServers = {}
                    for _, v in ipairs(data.data) do
                        if type(v) == "table" and v.playing and v.maxPlayers and v.playing < v.maxPlayers and v.id ~= game.JobId then
                            table.insert(validServers, v.id)
                        end
                    end
                    if #validServers > 0 then
                        local randomServer = validServers[math.random(1, #validServers)]
                        TeleportService:TeleportToPlaceInstance(placeId, randomServer, LocalPlayer)
                        return
                    end
                end
            end
        end)
        task.wait(1.5)
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)
end

local function IsAdmin(player)
    local ok, res = pcall(function()
        if player.UserId == game.CreatorId then return true end
        if player:GetRankInGroup(1200769) > 0 then return true end
        if game.CreatorType == Enum.CreatorType.Group then
            local role = string.lower(player:GetRoleInGroup(game.CreatorId))
            if string.find(role, "admin") or string.find(role, "mod") or string.find(role, "dev") or string.find(role, "creator") or string.find(role, "owner") then
                return true
            end
        end
        return false
    end)
    return ok and res or false
end

local function CheckAdminInServer()
    if not State.antiAdminMode then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAdmin(plr) then
            ServerHop()
            break
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    if State.antiAdminMode then
        task.wait(1) 
        if IsAdmin(plr) then
            ServerHop()
        end
    end
end)

CreateToggle(KeamananLeftContainer, "Anti Admin & Mod", function(state)
    State.antiAdminMode = state
    if state then
        CheckAdminInServer()
    end
end)


-- =====================================================================
-- Daftarkan Page 1 ke Sidebar
-- =====================================================================
CreateSidebarTab("130969527465346", "105234598969049", true, {TopNav, ContentFrame})
end -- <== TUTUP BUNGKUS PAGE 1
SendNotification("[MODUL] 1/8 - Page 1 (Gameplay) selesai dibuat", 2)

-- =====================================================================
-- PAGE 2: VISUAL (FAKE + FAKE 2)
-- =====================================================================
do -- <== BUNGKUS MEMORI PAGE 2 (bebaskan slot local variable setelah page ini selesai dibuat)
local VisualPageContainer = Instance.new("Frame", MainFrame)
VisualPageContainer.Size               = UDim2.new(1, -60, 1, 0)
VisualPageContainer.Position           = UDim2.new(0, 60, 0, 0)
VisualPageContainer.BackgroundTransparency = 1
VisualPageContainer.Visible            = false

local VisualTopNav = Instance.new("Frame", VisualPageContainer)
VisualTopNav.Size               = UDim2.new(1, 0, 0, 50)
VisualTopNav.BackgroundTransparency = 1

local VisualNavLayout = Instance.new("UIListLayout", VisualTopNav)
VisualNavLayout.FillDirection     = Enum.FillDirection.Horizontal
VisualNavLayout.SortOrder         = Enum.SortOrder.LayoutOrder
VisualNavLayout.Padding           = UDim.new(0, 25)
VisualNavLayout.VerticalAlignment = Enum.VerticalAlignment.Center
Instance.new("UIPadding", VisualTopNav).PaddingLeft = UDim.new(0, 30)

local VisualBg = Instance.new("Frame", VisualPageContainer)
VisualBg.Size             = UDim2.new(1, 0, 1, -50)
VisualBg.Position         = UDim2.new(0, 0, 0, 50)
VisualBg.BackgroundColor3 = C.BG_DARKER
VisualBg.BorderSizePixel  = 0
Instance.new("UICorner", VisualBg).CornerRadius = UDim.new(0, 12)

local PatchLeftVisual = Instance.new("Frame", VisualBg)
PatchLeftVisual.Size             = UDim2.new(0, 15, 1, 0)
PatchLeftVisual.BackgroundColor3 = C.BG_DARKER
PatchLeftVisual.BorderSizePixel  = 0

local FakePage  = Instance.new("Frame", VisualBg)
FakePage.Size               = UDim2.new(1, 0, 1, 0)
FakePage.BackgroundTransparency = 1
FakePage.Visible            = true

local Fake2Page = Instance.new("Frame", VisualBg)
Fake2Page.Size               = UDim2.new(1, 0, 1, 0)
Fake2Page.BackgroundTransparency = 1
Fake2Page.Visible            = false

local VisualTabs = {}
local function MakeVisualTab(text, isActive, contentPage)
    local btn = Instance.new("TextButton", VisualTopNav)
    btn.Size               = UDim2.new(0, 0, 1, 0)
    btn.AutomaticSize      = Enum.AutomaticSize.X
    btn.BackgroundTransparency = 1
    btn.Text               = text
    btn.TextColor3         = C.WHITE
    btn.Font               = Enum.Font.GothamMedium
    btn.TextSize           = 13
    btn.AutoButtonColor    = false

    local line = Instance.new("Frame", btn)
    line.Size             = UDim2.new(1, 0, 0, 2)
    line.Position         = UDim2.new(0, 0, 0.5, 10)
    line.BackgroundColor3 = C.UNDERLINE
    line.BorderSizePixel  = 0
    line.Visible          = isActive

    VisualTabs[text] = {Line = line, Content = contentPage}
    btn.MouseButton1Click:Connect(function()
        for _, td in pairs(VisualTabs) do
            td.Line.Visible = false
            if td.Content then td.Content.Visible = false end
        end
        line.Visible = true
        if contentPage then contentPage.Visible = true end
    end)
end

MakeVisualTab("FAKE",   true,  FakePage)
MakeVisualTab("FAKE 2", false, Fake2Page)

-- --- TAB FAKE: Input Box + Device Icon + Dropdown Title/Flag + Reset ---
local FakeLeftContainer = Instance.new("Frame", FakePage)
FakeLeftContainer.Size               = UDim2.new(0, 230, 1, -24)
FakeLeftContainer.Position           = UDim2.new(0, 12, 0, 12)
FakeLeftContainer.BackgroundTransparency = 1
local FakeLeftLayout = Instance.new("UIListLayout", FakeLeftContainer)
FakeLeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
FakeLeftLayout.Padding   = UDim.new(0, 10)

-- STATE PENYIMPANAN DATA ORIGINAL (Ditambah isVip untuk tracking VIP)
local OrigFake = { TitleObj = nil, TitleVis = nil, Texts = {}, Images = {}, Colors = {}, isVip = false }
local OrigFakeSaved = { Title = false }

local function ApplyLocalStat(statName, val)
    pcall(function()
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls and ls:FindFirstChild(statName) then ls[statName].Value = val end
    end)
end

local function ApplyOverheadText(objName, val)
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Head") and char.Head:FindFirstChild("Overhead") then
            local frame = char.Head.Overhead:FindFirstChild("Frame")
            if frame and frame:FindFirstChild(objName) then
                if OrigFake.Texts[objName] == nil then OrigFake.Texts[objName] = frame[objName].Text end
                
                -- JAGA VIP: Jika toggle VIP menyala, selalu amankan kata [VIP] di depan teks!
                if OrigFake.isVip and (objName == "PlayerName" or objName == "NameLabel") then
                    frame[objName].Text = "[VIP] " .. val
                else
                    frame[objName].Text = val
                end
            end
        end
    end)
end


local function ApplyOverheadImage(objName, imgId)
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Head") and char.Head:FindFirstChild("Overhead") then
            local frame = char.Head.Overhead:FindFirstChild("Frame")
            if frame and frame:FindFirstChild(objName) then
                if OrigFake.Images[objName] == nil then OrigFake.Images[objName] = frame[objName].Image end
                frame[objName].Image = imgId
            end
        end
    end)
end

local function CreateInputBox(parent, titleText, placeholder, numberOnly, onApplyCb)
    local Box = Instance.new("Frame", parent)
    Box.Size             = UDim2.new(1, 0, 0, 64)
    Box.BackgroundColor3 = C.BG_DARK
    Box.BorderSizePixel  = 0
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)

    local Title = Instance.new("TextLabel", Box)
    Title.Size               = UDim2.new(1, -20, 0, 20)
    Title.Position           = UDim2.new(0, 10, 0, 6)
    Title.BackgroundTransparency = 1
    Title.Text               = titleText
    Title.TextColor3         = C.WHITE
    Title.Font               = Enum.Font.Gotham
    Title.TextSize           = 12
    Title.TextXAlignment     = Enum.TextXAlignment.Left

    local InputBg = Instance.new("Frame", Box)
    InputBg.Size             = UDim2.new(0, 130, 0, 24)
    InputBg.Position         = UDim2.new(0, 10, 0, 30)
    InputBg.BackgroundColor3 = C.WHITE
    Instance.new("UICorner", InputBg).CornerRadius = UDim.new(0, 4)

    local TB = Instance.new("TextBox", InputBg)
    TB.Size               = UDim2.new(1, -10, 1, 0)
    TB.Position           = UDim2.new(0, 5, 0, 0)
    TB.BackgroundTransparency = 1
    TB.Text               = ""
    TB.PlaceholderText    = placeholder
    TB.PlaceholderColor3  = Color3.fromHex("#888888")
    TB.TextColor3         = Color3.fromHex("#000000")
    TB.Font               = Enum.Font.Gotham
    TB.TextSize           = 11
    TB.TextXAlignment     = Enum.TextXAlignment.Left

    local ApplyBtn = Instance.new("TextButton", Box)
    ApplyBtn.Size             = UDim2.new(0, 60, 0, 24)
    ApplyBtn.Position         = UDim2.new(0, 150, 0, 30)
    ApplyBtn.BackgroundColor3 = C.ACCENT
    ApplyBtn.Text             = "Apply"
    ApplyBtn.TextColor3       = C.WHITE
    ApplyBtn.Font             = Enum.Font.Gotham
    ApplyBtn.TextSize         = 12
    ApplyBtn.AutoButtonColor  = false
    Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 4)
    ApplyPressAnimation(ApplyBtn)

    local function DoApply()
        local t = TB.Text
        if numberOnly and t ~= "" then
            local num = tonumber(t)
            if not num or num <= 0 then
                TB.Text = ""
                TB.PlaceholderText = not num and "Error: Angka!" or "Error: Jangan 0!"
                TB.PlaceholderColor3 = Color3.fromHex("#ff4444")
                task.delay(1.5, function()
                    TB.PlaceholderText = placeholder
                    TB.PlaceholderColor3 = Color3.fromHex("#888888")
                end)
                return
            end
        end
        if onApplyCb then onApplyCb(t) end
    end

    ApplyBtn.MouseButton1Click:Connect(DoApply)
    TB.FocusLost:Connect(function(enter) if enter then DoApply() end end)
    
    -- Mengembalikan TextBox agar bisa diakses fitur Reset
    return TB
end

-- Menyimpan referensi TextBox untuk dikosongkan nanti
local TxtName = CreateInputBox(FakeLeftContainer, "Fake Name", "enter the name", false, function(val)
    if val ~= "" then ApplyOverheadText("PlayerName", val); ApplyOverheadText("NameLabel", val) end
end)

local TxtRank = CreateInputBox(FakeLeftContainer, "Fake rank", "enter the number", true, function(val)
    if val ~= "" then 
        local num = tonumber(val)
        ApplyLocalStat("Rank", num)
        
        pcall(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Head") and char.Head:FindFirstChild("Overhead") then
                local frame = char.Head.Overhead:FindFirstChild("Frame")
                if frame and frame:FindFirstChild("RankLabel") then
                    local lbl = frame.RankLabel
                    if OrigFake.Texts["RankLabel"] == nil then 
                        OrigFake.Texts["RankLabel"] = lbl.Text 
                        OrigFake.Colors["RankLabel"] = lbl.TextColor3 
                    end
                    
                    local oldGrad = lbl:FindFirstChildOfClass("UIGradient")
                    
                    if num == 1 then
                        lbl.Text = "Teratas 1"
                        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                        if not oldGrad then oldGrad = Instance.new("UIGradient", lbl) end
                        oldGrad.Rotation = 90
                        oldGrad.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.new(1, 0.282353, 0)),
                            ColorSequenceKeypoint.new(0.5, Color3.new(1, 0.984314, 0)),
                            ColorSequenceKeypoint.new(0.55, Color3.new(1, 0.368627, 0.00392157)),
                            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 0))
                        })
                        
                    elseif num >= 2 and num <= 9 then
                        lbl.Text = "Teratas " .. num
                        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                        if not oldGrad then oldGrad = Instance.new("UIGradient", lbl) end
                        oldGrad.Rotation = 90
                        oldGrad.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.new(0.207843, 0, 0.027451)),
                            ColorSequenceKeypoint.new(0.5, Color3.new(1, 0.403922, 0.415686)),
                            ColorSequenceKeypoint.new(0.55, Color3.new(0.372549, 0, 0.054902)),
                            ColorSequenceKeypoint.new(1, Color3.new(1, 0.403922, 0.415686))
                        })
                        
                    elseif num >= 10 and num <= 98 then
                        lbl.Text = "Teratas " .. num
                        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                        if not oldGrad then oldGrad = Instance.new("UIGradient", lbl) end
                        oldGrad.Rotation = 90
                        oldGrad.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.new(0, 0.180392, 0.207843)),
                            ColorSequenceKeypoint.new(0.5, Color3.new(0.411765, 1, 0.933333)),
                            ColorSequenceKeypoint.new(0.55, Color3.new(0, 0.341176, 0.372549)),
                            ColorSequenceKeypoint.new(1, Color3.new(0.411765, 1, 0.933333))
                        })
                        
                    elseif num >= 99 then
                        lbl.Text = "Top 99+"
                        lbl.TextColor3 = Color3.fromRGB(165, 165, 165)
                        if oldGrad then oldGrad:Destroy() end
                    end
                end
            end
        end)
    end
end)

local TxtStreak
TxtStreak = CreateInputBox(FakeLeftContainer, "Fake Streak", "enter the number", true, function(val)
    if val ~= "" then 
        local char = LocalPlayer.Character
        
        -- VALIDASI: Cek apakah StreakBillboard sudah ada (syarat harus menang minimal 1x)
        if not char or not char:FindFirstChild("Head") or not char.Head:FindFirstChild("StreakBillboard") then
            if TxtStreak then
                TxtStreak.Text = ""
                TxtStreak.PlaceholderText = "Error: Menang 1x dulu!"
                TxtStreak.PlaceholderColor3 = Color3.fromHex("#ff4444")
                task.delay(1.5, function()
                    TxtStreak.PlaceholderText = "enter the number"
                    TxtStreak.PlaceholderColor3 = Color3.fromHex("#888888")
                end)
            end
            return -- Hentikan script di sini, jangan ubah stat/tampilan
        end
        
        local num = tonumber(val)
        ApplyLocalStat("Streak", num)
        ApplyLocalStat("Win Streak", num)
        
        pcall(function()
            local fireBG = char.Head.StreakBillboard:FindFirstChild("FireBG")
            if fireBG then
                local streakNum = fireBG:FindFirstChild("StreakNumber")
                if streakNum then
                    if OrigFake.Texts["StreakNumber"] == nil then OrigFake.Texts["StreakNumber"] = streakNum.Text end
                    streakNum.Text = tostring(num)
                end
                
                if OrigFake.Images["FireBG"] == nil then OrigFake.Images["FireBG"] = fireBG.Image end
                
                if num >= 100 then
                    fireBG.Image = "rbxassetid://135836679344581"
                elseif num >= 50 then
                    fireBG.Image = "rbxassetid://129825881918699"
                elseif num >= 25 then
                    fireBG.Image = "rbxassetid://117598829066059"
                else
                    fireBG.Image = "rbxassetid://124831674833103"
                end
            end
        end)
    end
end)

-- Device Icon Toggle
local DeviceIconBox = Instance.new("Frame", FakeLeftContainer)
DeviceIconBox.Size             = UDim2.new(1, 0, 0, 64)
DeviceIconBox.BackgroundColor3 = C.BG_DARK
DeviceIconBox.BorderSizePixel  = 0
Instance.new("UICorner", DeviceIconBox).CornerRadius = UDim.new(0, 6)

local DeviceTitle = Instance.new("TextLabel", DeviceIconBox)
DeviceTitle.Size               = UDim2.new(1, -20, 0, 20)
DeviceTitle.Position           = UDim2.new(0, 10, 0, 6)
DeviceTitle.BackgroundTransparency = 1
DeviceTitle.Text               = "Change Device Icon"
DeviceTitle.TextColor3         = C.WHITE
DeviceTitle.Font               = Enum.Font.Gotham
DeviceTitle.TextSize           = 12
DeviceTitle.TextXAlignment     = Enum.TextXAlignment.Left

local DeviceBtn = Instance.new("TextButton", DeviceIconBox)
DeviceBtn.Size             = UDim2.new(1, -20, 0, 24)
DeviceBtn.Position         = UDim2.new(0, 10, 0, 30)
DeviceBtn.BackgroundColor3 = C.ACCENT
-- Deteksi otomatis device asli
local origDev = game:GetService("UserInputService").TouchEnabled and "Mobile" or "Desktop"
DeviceBtn.Text             = origDev
DeviceBtn.TextColor3       = C.WHITE
DeviceBtn.Font             = Enum.Font.GothamMedium
DeviceBtn.TextSize         = 11
DeviceBtn.AutoButtonColor  = false
Instance.new("UICorner", DeviceBtn).CornerRadius = UDim.new(0, 4)
ApplyPressAnimation(DeviceBtn)

local DeviceAssets = {
    ["Mobile"] = "http://www.roblox.com/asset/?id=14040313879",
    ["Desktop"] = "http://www.roblox.com/asset/?id=12684119225"
}

DeviceBtn.MouseButton1Click:Connect(function()
    DeviceBtn.Text = DeviceBtn.Text == "Mobile" and "Desktop" or "Mobile"
    local imgId = DeviceAssets[DeviceBtn.Text]
    
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Head") and char.Head:FindFirstChild("Overhead") then
            local frame = char.Head.Overhead:FindFirstChild("Frame")
            if frame and frame:FindFirstChild("BadgeRow") and frame.BadgeRow:FindFirstChild("DeviceIcon") then
                local devIcon = frame.BadgeRow.DeviceIcon
                if OrigFake.Images["DeviceIcon"] == nil then OrigFake.Images["DeviceIcon"] = devIcon.Image end
                devIcon.Image = imgId
            end
        end
    end)
end)

-- Kolom kanan Fake: Title, Flag, Reset
local FakeRightContainer = Instance.new("Frame", FakePage)
FakeRightContainer.Size               = UDim2.new(0, 230, 1, -24)
FakeRightContainer.Position           = UDim2.new(0, 254, 0, 12)
FakeRightContainer.BackgroundTransparency = 1
local FakeRightLayout = Instance.new("UIListLayout", FakeRightContainer)
FakeRightLayout.SortOrder = Enum.SortOrder.LayoutOrder
FakeRightLayout.Padding   = UDim.new(0, 10)

local function MakeFakeDropdownBox(parent, zIdx, labelText, btnDefault)
    local Box = Instance.new("Frame", parent)
    Box.Size             = UDim2.new(1, 0, 0, 64)
    Box.BackgroundColor3 = C.BG_DARK
    Box.BorderSizePixel  = 0
    Box.ZIndex           = zIdx
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)

    local Lbl = Instance.new("TextLabel", Box)
    Lbl.Size               = UDim2.new(1, -20, 0, 20)
    Lbl.Position           = UDim2.new(0, 10, 0, 6)
    Lbl.BackgroundTransparency = 1
    Lbl.Text               = labelText
    Lbl.TextColor3         = C.WHITE
    Lbl.Font               = Enum.Font.Gotham
    Lbl.TextSize           = 12
    Lbl.TextXAlignment     = Enum.TextXAlignment.Left
    Lbl.ZIndex             = zIdx

    local Btn = Instance.new("TextButton", Box)
    Btn.Size             = UDim2.new(1, -20, 0, 24)
    Btn.Position         = UDim2.new(0, 10, 0, 30)
    Btn.BackgroundColor3 = C.ACCENT
    Btn.Text             = btnDefault
    Btn.TextColor3       = C.WHITE
    Btn.Font             = Enum.Font.Gotham
    Btn.TextSize         = 11
    Btn.AutoButtonColor  = false
    Btn.ZIndex           = zIdx
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    ApplyPressAnimation(Btn)

    return Box, Btn
end

local FakeTitleBox, FakeTitleBtn = MakeFakeDropdownBox(FakeRightContainer, 50, "Fake Title", "None")
local TitleOptions = {"Perintis Aksara","Cendekia sabda","Pemahami kata","Wiyata kata","Kata widayata","Cakrawala sabda","Mahakarya aksara","Adiwidya sabda","Adhiraja sabda","Parama aksara","Maharaja semesta kata","Sang hyang acara","Donatur teratas","None"}

local TitlePaths = {
    ["Perintis Aksara"] = {p = "IndexTitleFrame", f = "5000Kata"},
    ["Cendekia sabda"] = {p = "IndexTitleFrame", f = "10000Kata"},
    ["Pemahami kata"] = {p = "IndexTitleFrame", f = "15000Kata"},
    ["Wiyata kata"] = {p = "IndexTitleFrame", f = "20000Kata"},
    ["Kata widayata"] = {p = "IndexTitleFrame", f = "30000Kata"},
    ["Cakrawala sabda"] = {p = "IndexTitleFrame", f = "40000Kata"},
    ["Mahakarya aksara"] = {p = "IndexTitleFrame", f = "50000Kata"},
    ["Adiwidya sabda"] = {p = "IndexTitleFrame", f = "65000Kata"},
    ["Adhiraja sabda"] = {p = "IndexTitleFrame", f = "75000Kata"},
    ["Parama aksara"] = {p = "IndexTitleFrame", f = "85000Kata"},
    ["Maharaja semesta kata"] = {p = "IndexTitleFrame", f = "100000Kata"},
    ["Sang hyang acara"] = {p = "IndexTitleFrame", f = "125000Kata"},
    ["Donatur teratas"] = {p = "SpecialTitleFrame", f = "TopDonatur"},
    ["None"] = {p = "None", f = "None"}
}

local function ApplyFakeTitle(titleName)
    task.spawn(function()
        pcall(function()
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local head = char:FindFirstChild("Head")
            if not head then return end
            local overhead = head:FindFirstChild("Overhead")
            if not overhead then return end
            local frame = overhead:FindFirstChild("Frame")
            if not frame then return end
            
            local titleFrame = frame:FindFirstChild("TitleFrame")
            if not OrigFakeSaved.Title then
                if titleFrame then 
                    OrigFake.TitleVis = titleFrame.Visible
                    OrigFake.TitleObj = titleFrame:Clone() 
                else 
                    OrigFake.TitleVis = false 
                end
                OrigFakeSaved.Title = true
            end
            
            local oldFake = frame:FindFirstChild("FakeTitleFrame")
            if oldFake then oldFake:Destroy() end
            
            if titleName == "None" then
                if titleFrame then titleFrame.Visible = OrigFake.TitleVis end
                return
            end
            
            if titleFrame then titleFrame.Visible = false end
            
            local pD = TitlePaths[titleName]
            if not pD then return end
            
            local menu = PlayerGui:WaitForChild("MenuUI", 5)
            if not menu then return end
            local tf = menu:WaitForChild("TitleFrame", 5)
            if not tf then return end
            local tc = tf:WaitForChild("TitleContent", 5)
            if not tc then return end
            local dp = tc:WaitForChild(pD.p, 5)
            if not dp then return end
            local df = dp:WaitForChild(pD.f, 5)
            if not df then return end
            local inside = df:WaitForChild("InsideFrame", 5)
            if not inside then return end
            local action = inside:WaitForChild("ActionFrame", 5)
            if not action then return end
            local sourceFrame = action:WaitForChild("TitleFrame", 5)
            
            if sourceFrame then
                local newFakeTitle = sourceFrame:Clone()
                newFakeTitle.Name = "FakeTitleFrame"
                newFakeTitle.Parent = frame
                newFakeTitle.Visible = true
            end
        end)
    end)
end

local TitleDrop
TitleDrop = CreateDropdown(FakeTitleBtn, TitleOptions, function(sel)
    ApplyFakeTitle(sel)
    if TitleDrop then TitleDrop.SetSelected(sel); TitleDrop.Container.Visible=false end
end)
TitleDrop.SetSelected("None")

-- Deteksi lokasi untuk Flag asli (ANTI-FREEZE)
local detectedEmoji = "🇮🇩"
local FakeFlagBox, FakeFlagBtn = MakeFakeDropdownBox(FakeRightContainer, 40, "Fake Flag", detectedEmoji)
FakeFlagBtn.Size = UDim2.new(0, 60, 0, 24) 
FakeFlagBtn.TextSize = 14

-- Menjalankan sistem deteksi negara di background tanpa membekukan script utama
task.spawn(function()
    pcall(function()
        local LocalizationService = game:GetService("LocalizationService")
        local code = LocalizationService:GetCountryRegionForPlayerAsync(LocalPlayer)
        local CountryToEmoji = { ["ID"]="🇮🇩", ["US"]="🇺🇸", ["JP"]="🇯🇵", ["SG"]="🇸🇬", ["MY"]="🇲🇾", ["TH"]="🇹🇭", ["GB"]="🇬🇧", ["AU"]="🇦🇺" }
        if CountryToEmoji[code] then
            detectedEmoji = CountryToEmoji[code]
            FakeFlagBtn.Text = detectedEmoji
        end
    end)
end)


local FlagOptions = {"🇦🇨","🇦🇩","🇦🇪","🇦🇫","🇦🇬","🇦🇮","🇦🇱","🇦🇲","🇦🇴","🇦🇶","🇦🇷","🇦🇸","🇦🇹","🇦🇺","🇦🇼","🇦🇽","🇦🇿","🇧🇦","🇧🇧","🇧🇩","🇧🇪","🇧🇫","🇧🇬","🇧🇭","🇧🇮","🇧🇯","🇧🇱","🇧🇲","🇧🇳","🇧🇴","🇧🇶","🇧🇷","🇧🇸","🇧🇹","🇧🇻","🇧🇼","🇧🇾","🇧🇿","🇨🇦","🇨🇨","🇨🇩","🇨🇫","🇨🇬","🇨🇭","🇨🇮","🇨🇰","🇨🇱","🇨🇲","🇨🇳","🇨🇴","🇨🇵","🇨🇷","🇨🇺","🇨🇻","🇨🇼","🇨🇽","🇨🇾","🇨🇿","🇩🇪","🇩🇬","🇩🇯","🇩🇰","🇩🇲","🇩🇴","🇩🇿","🇪🇦","🇪🇨","🇪🇪","🇪🇬","🇪🇭","🇪🇷","🇪🇸","🇪🇹","🇪🇺","🇫🇮","🇫🇯","🇫🇰","🇫🇲","🇫🇴","🇫🇷","🇬🇦","🇬🇧","🇬🇩","🇬🇪","🇬🇫","🇬🇬","🇬🇭","🇬🇮","🇬🇱","🇬🇲","🇬🇳","🇬🇵","🇬🇶","🇬🇷","🇬🇸","🇬🇹","🇬🇺","🇬🇼","🇬🇾","🇭🇰","🇭🇲","🇭🇳","🇭🇷","🇭🇹","🇭🇺","🇮🇨","🇮🇩","🇮🇪","🇮🇲","🇮🇳","🇮🇴","🇮🇶","🇮🇷","🇮🇸","🇮🇹","🇯🇪","🇯🇲","🇯🇴","🇯🇵","🇰🇪","🇰🇬","🇰🇭","🇰🇮","🇰🇲","🇰🇳","🇰🇵","🇰🇷","🇰🇼","🇰🇾","🇰🇿","🇱🇦","🇱🇧","🇱🇨","🇱🇮","🇱🇰","🇱🇷","🇱🇸","🇱🇹","🇱🇺","🇱🇻","🇱🇾","🇲🇦","🇲🇨","🇲🇩","🇲🇪","🇲🇫","🇲🇬","🇲🇭","🇲🇰","🇲🇱","🇲🇲","🇲🇳","🇲🇴","🇲🇵","🇲🇶","🇲🇷","🇲🇸","🇲🇹","🇲🇺","🇲🇻","🇲🇼","🇲🇽","🇲🇾","🇲🇿","🇳🇦","🇳🇨","🇳🇪","🇳🇫","🇳🇬","🇳🇮","🇳🇱","🇳🇴","🇳🇵","🇳🇷","🇳🇺","🇳🇿","🇴🇲","🇵🇦","🇵🇪","🇵🇫","🇵🇬","🇵🇭","🇵🇰","🇵🇱","🇵🇲","🇵🇳","🇵🇷","🇵🇸","🇵🇹","🇵🇼","🇵🇾","🇶🇦","🇷🇪","🇷🇴","🇷🇸","🇷🇺","🇷🇼","🇸🇦","🇸🇧","🇸🇨","🇸🇩","🇸🇪","🇸🇬","🇸🇭","🇸🇮","🇸🇯","🇸🇰","🇸🇱","🇸🇲","🇸🇳","🇸🇴","🇸🇷","🇸🇸","🇸🇹","🇸🇻","🇸🇽","🇸🇾","🇸🇿","🇹🇦","🇹🇨","🇹🇩","🇹🇫","🇹🇬","🇹🇭","🇹🇯","🇹🇰","🇹🇱","🇹🇲","🇹🇳","🇹🇴","🇹🇷","🇹🇹","🇹🇻","🇹🇼","🇹🇿","🇺🇦","🇺🇬","🇺🇲","🇺🇳","🇺🇸","🇺🇾","🇺🇿","🇻🇦","🇻🇨","🇻🇪","🇻🇬","🇻🇮","🇻🇳","🇻🇺","🇼🇫","🇼🇸","🇽🇰","🇾🇪","🇾🇹","🇿🇦","🇿🇲","🇿🇼","🏴󠁧󠁢󠁥󠁮󠁧󠁿","🏴󠁧󠁢󠁳󠁣󠁴󠁿","🏴󠁧󠁢󠁷󠁬󠁳󠁿"}
local FlagDrop
FlagDrop = CreateDropdown(FakeFlagBtn, FlagOptions, function(sel)
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Head") and char.Head:FindFirstChild("Overhead") then
            local frame = char.Head.Overhead:FindFirstChild("Frame")
            if frame and frame:FindFirstChild("BadgeRow") and frame.BadgeRow:FindFirstChild("FlagLabel") then
                local flagLbl = frame.BadgeRow.FlagLabel
                if OrigFake.Texts["FlagLabel"] == nil then OrigFake.Texts["FlagLabel"] = flagLbl.Text end
                flagLbl.Text = sel
            end
        end
    end)
    if FlagDrop then FlagDrop.SetSelected(sel); FlagDrop.Container.Visible=false end
end)
FlagDrop.SetSelected(detectedEmoji)

-- Reset Box
local ResetBox = Instance.new("Frame", FakeRightContainer)
ResetBox.Size             = UDim2.new(1, 0, 0, 126)
ResetBox.BackgroundColor3 = C.BG_DARK
ResetBox.BorderSizePixel  = 0
Instance.new("UICorner", ResetBox).CornerRadius = UDim.new(0, 6)

local ResetTitle = Instance.new("TextLabel", ResetBox)
ResetTitle.Size               = UDim2.new(1, -20, 0, 20)
ResetTitle.Position           = UDim2.new(0, 10, 0, 6)
ResetTitle.BackgroundTransparency = 1
ResetTitle.Text               = "Reset to Original"
ResetTitle.TextColor3         = C.WHITE
ResetTitle.Font               = Enum.Font.Gotham
ResetTitle.TextSize           = 12
ResetTitle.TextXAlignment     = Enum.TextXAlignment.Left

local function CreateResetBtn(label, pos, size, funcCb)
    local btn = Instance.new("TextButton", ResetBox)
    btn.Size             = size
    btn.Position         = pos
    btn.BackgroundColor3 = C.ACCENT
    btn.Text             = label
    btn.TextColor3       = C.WHITE
    btn.Font             = Enum.Font.GothamMedium
    btn.TextSize         = 11
    btn.AutoButtonColor  = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    ApplyPressAnimation(btn)
    btn.MouseButton1Click:Connect(funcCb)
end

CreateResetBtn("Reset Name",   UDim2.new(0,  10, 0, 32), UDim2.new(0.5,-15, 0, 24), function()
    TxtName.Text = ""
    if OrigFake.Texts["PlayerName"] then ApplyOverheadText("PlayerName", OrigFake.Texts["PlayerName"]) end
    if OrigFake.Texts["NameLabel"] then ApplyOverheadText("NameLabel", OrigFake.Texts["NameLabel"]) end
end)

CreateResetBtn("Reset Rank",   UDim2.new(0.5,  5, 0, 32), UDim2.new(0.5,-15, 0, 24), function() 
    TxtRank.Text = ""
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Head") and char.Head:FindFirstChild("Overhead") then
            local lbl = char.Head.Overhead.Frame:FindFirstChild("RankLabel")
            if lbl then
                if OrigFake.Texts["RankLabel"] then lbl.Text = OrigFake.Texts["RankLabel"] end
                if OrigFake.Colors["RankLabel"] then lbl.TextColor3 = OrigFake.Colors["RankLabel"] end
                local grad = lbl:FindFirstChildOfClass("UIGradient")
                if grad then grad:Destroy() end
            end
        end
    end)
end) 

CreateResetBtn("Reset Streak", UDim2.new(0,  10, 0, 64), UDim2.new(0.5,-15, 0, 24), function() 
    TxtStreak.Text = ""
    if OrigFake.Texts["StreakNumber"] then
        pcall(function() LocalPlayer.Character.Head.StreakBillboard.FireBG.StreakNumber.Text = OrigFake.Texts["StreakNumber"] end)
    end
    if OrigFake.Images["FireBG"] then
        pcall(function() LocalPlayer.Character.Head.StreakBillboard.FireBG.Image = OrigFake.Images["FireBG"] end)
    end
end) 

CreateResetBtn("Reset Flag",   UDim2.new(0.5,  5, 0, 64), UDim2.new(0.5,-15, 0, 24), function()
    if FlagDrop then FlagDrop.SetSelected(detectedEmoji) end
    -- FIX: Arahkan path langsung ke dalam BadgeRow
    if OrigFake.Texts["FlagLabel"] then 
        pcall(function() LocalPlayer.Character.Head.Overhead.Frame.BadgeRow.FlagLabel.Text = OrigFake.Texts["FlagLabel"] end)
    end
end)

CreateResetBtn("Reset All",    UDim2.new(0,  10, 0, 96), UDim2.new(1,  -20, 0, 24), function()
    -- 1. Kosongkan teks di Input UI
    TxtName.Text = ""
    TxtRank.Text = ""
    TxtStreak.Text = ""
    
    -- 2. Reset Name
    if OrigFake.Texts["PlayerName"] then ApplyOverheadText("PlayerName", OrigFake.Texts["PlayerName"]) end
    if OrigFake.Texts["NameLabel"] then ApplyOverheadText("NameLabel", OrigFake.Texts["NameLabel"]) end
    
    -- 3. Reset Rank (Teks, Warna, & Hapus Gradient)
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Head") and char.Head:FindFirstChild("Overhead") then
            local lbl = char.Head.Overhead.Frame:FindFirstChild("RankLabel")
            if lbl then
                if OrigFake.Texts["RankLabel"] then lbl.Text = OrigFake.Texts["RankLabel"] end
                if OrigFake.Colors["RankLabel"] then lbl.TextColor3 = OrigFake.Colors["RankLabel"] end
                local grad = lbl:FindFirstChildOfClass("UIGradient")
                if grad then grad:Destroy() end
            end
        end
    end)
    
    -- 4. Reset Streak
    if OrigFake.Texts["StreakNumber"] then
        pcall(function() LocalPlayer.Character.Head.StreakBillboard.FireBG.StreakNumber.Text = OrigFake.Texts["StreakNumber"] end)
    end
    if OrigFake.Images["FireBG"] then
        pcall(function() LocalPlayer.Character.Head.StreakBillboard.FireBG.Image = OrigFake.Images["FireBG"] end)
    end
    
    -- 5. Reset Dropdown & Title
    if TitleDrop then TitleDrop.SetSelected("None") end
    ApplyFakeTitle("None")
    
    -- 6. Reset Flag & Dropdown (FIX: Arahkan path langsung ke dalam BadgeRow)
    if FlagDrop then FlagDrop.SetSelected(detectedEmoji) end
    if OrigFake.Texts["FlagLabel"] then 
        pcall(function() LocalPlayer.Character.Head.Overhead.Frame.BadgeRow.FlagLabel.Text = OrigFake.Texts["FlagLabel"] end)
    end
    
    -- 7. Reset Device & Text Button (FIX: Arahkan path langsung ke dalam BadgeRow)
    DeviceBtn.Text = origDev
    if OrigFake.Images["DeviceIcon"] then 
        pcall(function() LocalPlayer.Character.Head.Overhead.Frame.BadgeRow.DeviceIcon.Image = OrigFake.Images["DeviceIcon"] end)
    end
end)


-- --- TAB FAKE 2: Toggle badge, icon, dll ---
local Fake2LeftContainer = Instance.new("Frame", Fake2Page)
Fake2LeftContainer.Size               = UDim2.new(0, 180, 1, -24)
Fake2LeftContainer.Position           = UDim2.new(0, 12, 0, 12)
Fake2LeftContainer.BackgroundTransparency = 1

local Fake2Layout = Instance.new("UIListLayout", Fake2LeftContainer)
Fake2Layout.SortOrder = Enum.SortOrder.LayoutOrder
Fake2Layout.Padding   = UDim.new(0, 8)

-- Fungsi untuk mengatur visibilitas icon di dalam BadgeRow
local function ApplyBadgeRowIcon(iconName, isVisible)
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Head") and char.Head:FindFirstChild("Overhead") then
            local frame = char.Head.Overhead:FindFirstChild("Frame")
            if frame and frame:FindFirstChild("BadgeRow") then
                local icon = frame.BadgeRow:FindFirstChild(iconName)
                if icon then
                    icon.Visible = isVisible
                end
            end
        end
    end)
end

-- Fungsi khusus untuk VIP (Ubah nama dan warna teks)
local function ApplyVipEffect(isVip)
    -- 1. SIMPAN STATUS VIP KE MEMORI (Ini yang bikin teks [VIP] kebal dari Reset)
    OrigFake.isVip = isVip
    
    pcall(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Head") and char.Head:FindFirstChild("Overhead") then
            local frame = char.Head.Overhead:FindFirstChild("Frame")
            
            -- Daftar label nama yang biasa digunakan di Overhead
            local nameLabels = {"PlayerName", "NameLabel"}
            
            for _, lblName in ipairs(nameLabels) do
                local lbl = frame:FindFirstChild(lblName)
                if lbl then
                    -- Simpan nama dan warna asli untuk sistem Reset & Toggle Off
                    if OrigFake.Texts[lblName] == nil then OrigFake.Texts[lblName] = lbl.Text end
                    if OrigFake.Colors[lblName] == nil then OrigFake.Colors[lblName] = lbl.TextColor3 end
                    
                    local oldGrad = lbl:FindFirstChildOfClass("UIGradient")
                    
                    if isVip then
                        -- Ambil teks saat ini, bersihkan [VIP] ganda kalau sebelumnya sudah ada
                        local currentText = lbl.Text
                        if string.sub(currentText, 1, 6) == "[VIP] " then
                            currentText = string.sub(currentText, 7)
                        end
                        
                        lbl.Text = "[VIP] " .. currentText
                        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                        
                        if not oldGrad then oldGrad = Instance.new("UIGradient", lbl) end
                        oldGrad.Rotation = 90
                        oldGrad.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.new(1, 0.784314, 0)),
                            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 0.588235)),
                            ColorSequenceKeypoint.new(0.55, Color3.new(1, 0.705882, 0)),
                            ColorSequenceKeypoint.new(1, Color3.new(1, 0.509804, 0))
                        })
                    else
                        -- Hapus kata [VIP] secara bersih saat toggle dimatikan
                        local currentText = lbl.Text
                        if string.sub(currentText, 1, 6) == "[VIP] " then
                            lbl.Text = string.sub(currentText, 7)
                        else
                            lbl.Text = currentText
                        end
                        
                        lbl.TextColor3 = OrigFake.Colors[lblName]
                        if oldGrad then oldGrad:Destroy() end
                    end
                end
            end
        end
    end)
end



CreateToggle(Fake2LeftContainer, "Hof Badge", function(state) ApplyBadgeRowIcon("HOFBadge", state) end)
CreateToggle(Fake2LeftContainer, "Verified Icon", function(state) ApplyBadgeRowIcon("VerifiedIcon", state) end)
CreateToggle(Fake2LeftContainer, "Premium", function(state) ApplyBadgeRowIcon("PremiumIcon", state) end)
CreateToggle(Fake2LeftContainer, "Vip", function(state) ApplyVipEffect(state) end)


CreateSidebarTab("104010825913281", "71219341119919", false, {VisualPageContainer})
end -- <== TUTUP BUNGKUS PAGE 2
SendNotification("[MODUL] 2/8 - Page 2 (Visual) selesai dibuat", 2)

-- =====================================================================
-- PAGE 3: ESP
-- =====================================================================
local EspPageContainer, EspInner = CreatePageContainer("ESP")
EspPageContainer.Parent = MainFrame

do -- <== BUNGKUS MEMORI ESP
    State.espMejaMode = false
    State.espStatMode = false

    -- Toggle ESP Meja Kosong
    CreateToggle(EspInner, "Esp Empty Table", function(state)
        State.espMejaMode = state
        if not state then
            pcall(function()
                local tablesFolder = workspace:FindFirstChild("Tables")
                if tablesFolder then
                    for _, tableModel in ipairs(tablesFolder:GetChildren()) do
                        local tablePart = tableModel:FindFirstChild("TablePart")
                        if tablePart then
                            local esp = tablePart:FindFirstChild("ASK_ESP")
                            if esp then esp:Destroy() end
                        end
                    end
                end
            end)
        end
    end)

    -- Toggle ESP Player Statistik
    CreateToggle(EspInner, "Esp Players Statistics", function(state)
        State.espStatMode = state
        if not state then
            pcall(function()
                for _, plr in ipairs(Players:GetPlayers()) do
                    local char = plr.Character
                    if char and char:FindFirstChild("Head") then
                        local esp = char.Head:FindFirstChild("ASK_StatESP")
                        if esp then esp:Destroy() end
                    end
                end
            end)
        end
    end)

    local function updateESP()
        local tablesFolder = workspace:FindFirstChild("Tables")
        if not tablesFolder then return end
        for _, tableModel in ipairs(tablesFolder:GetChildren()) do
            local seatsFolder = tableModel:FindFirstChild("Seats")
            local tablePart = tableModel:FindFirstChild("TablePart")
            if seatsFolder and tablePart then
                local totalSeats, occupiedSeats = 0, 0
                for _, seat in ipairs(seatsFolder:GetChildren()) do
                    if seat:IsA("Seat") then
                        totalSeats = totalSeats + 1
                        if seat:FindFirstChild("SeatWeld") then occupiedSeats = occupiedSeats + 1 end
                    end
                end
                if State.espMejaMode and totalSeats > 0 and occupiedSeats < totalSeats then
                    local esp = tablePart:FindFirstChild("ASK_ESP")
                    if not esp then
                        esp = Instance.new("BillboardGui")
                        esp.Name = "ASK_ESP"
                        esp.Size = UDim2.new(0, 200, 0, 50)
                        esp.StudsOffset = Vector3.new(0, 7.5, 0)
                        esp.AlwaysOnTop = true
                        esp.Parent = tablePart
                        local txt = Instance.new("TextLabel", esp)
                        txt.Name = "Text"
                        txt.Size = UDim2.new(1, 0, 1, 0)
                        txt.BackgroundTransparency = 1
                        txt.Font = Enum.Font.GothamBold
                        txt.TextSize = 14
                        txt.TextColor3 = Color3.fromRGB(150, 255, 150)
                        txt.TextStrokeTransparency = 0.3
                    end
                    local tName = string.gsub(tableModel.Name, "Table_", "")
                    esp.Text.Text = "[ " .. tName .. " ]\n" .. occupiedSeats .. "/" .. totalSeats .. " Ready"
                else
                    local esp = tablePart:FindFirstChild("ASK_ESP")
                    if esp then esp:Destroy() end
                end
            end
        end
    end

    local function updateESPStats()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end 
            local char = plr.Character
            if char and char:FindFirstChild("Head") then
                local head = char.Head
                local espName = "ASK_StatESP"
                local esp = head:FindFirstChild(espName)
                if State.espStatMode then
                    if not esp then
                        esp = Instance.new("BillboardGui")
                        esp.Name = espName
                        esp.Size = UDim2.new(0, 110, 0, 70)
                        esp.StudsOffset = Vector3.new(3, -1.5, 0)
                        esp.AlwaysOnTop = true
                        esp.Parent = head
                        local txt = Instance.new("TextLabel", esp)
                        txt.Name = "Text"
                        txt.Size = UDim2.new(1, 0, 1, 0)
                        txt.BackgroundTransparency = 1
                        txt.Font = Enum.Font.GothamBold
                        txt.TextSize = 12
                        txt.TextColor3 = Color3.fromRGB(255, 255, 255)
                        txt.TextStrokeTransparency = 0.3
                        txt.TextXAlignment = Enum.TextXAlignment.Left
                        txt.TextYAlignment = Enum.TextYAlignment.Top
                    end
                    local ls = plr:FindFirstChild("leaderstats")
                    local wins, losses, money = 0, 0, 0
                    if ls then
                        local wObj = ls:FindFirstChild("Wins") or ls:FindFirstChild("Win") or ls:FindFirstChild("Menang")
                        if wObj then wins = tonumber(wObj.Value) or 0 end
                        local lObj = ls:FindFirstChild("Losses") or ls:FindFirstChild("Kalah")
                        if lObj then losses = tonumber(lObj.Value) or 0 end
                        local mObj = ls:FindFirstChild("Money") or ls:FindFirstChild("Uang")
                        if mObj then money = tonumber(mObj.Value) or 0 end
                    end
                    local total = wins + losses
                    local wr = total > 0 and math.floor((wins / total) * 100) or 0
                    local txtChild = esp:FindFirstChild("Text")
                    if txtChild then
                        txtChild.Text = string.format("📊 WR: %d%%\n🏆 Menang: %d\n💀 Kalah: %d\n💵 Uang: %s", wr, wins, losses, FormatRibuan(money))
                    end
                else
                    if esp then esp:Destroy() end
                end
            end
        end
    end

    task.spawn(function()
        while true do
            task.wait(0.25)
            if State.espMejaMode then pcall(updateESP) end
            if State.espStatMode then pcall(updateESPStats) end
        end
    end)
end -- <== TUTUP BUNGKUS MEMORI ESP
SendNotification("[MODUL] 3/8 - Page ESP selesai dibuat", 2)

CreateSidebarTab("98861278425029", "78012648056733", false, {EspPageContainer})

-- =====================================================================
-- PAGE 4: OPTIMIZE
-- =====================================================================
local OptimizePageContainer, OptInner = CreatePageContainer("OPTIMIZED")
OptimizePageContainer.Parent = MainFrame

do -- <== BUNGKUS MEMORI OPTIMIZE
    local OriginalMap = {}
    local OriginalParticles = {}
    local reduceConn = nil
    local particleConn = nil

    local function IsCharacter(obj)
        local model = obj:FindFirstAncestorOfClass("Model")
        return model and model:FindFirstChild("Humanoid") ~= nil
    end

    local function ReduceObject(obj)
        if IsCharacter(obj) then return end
        if obj:IsA("BasePart") then
            if not OriginalMap[obj] then OriginalMap[obj] = {Material = obj.Material, CastShadow = obj.CastShadow} end
            obj.Material = Enum.Material.SmoothPlastic
            obj.CastShadow = false
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            if not OriginalMap[obj] then OriginalMap[obj] = {Transparency = obj.Transparency} end
            obj.Transparency = 1
        end
    end

    local function HideParticle(obj)
        if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("Sparkles") or obj:IsA("Fire") or obj:IsA("Smoke") then
            if OriginalParticles[obj] == nil then OriginalParticles[obj] = obj.Enabled end
            obj.Enabled = false
            if obj:IsA("ParticleEmitter") then obj:Clear() end
        end
    end

    CreateToggle(OptInner, "Reduce Map", function(state)
        if state then
            for _, obj in ipairs(workspace:GetDescendants()) do ReduceObject(obj) end
            reduceConn = workspace.DescendantAdded:Connect(function(obj) task.wait(); ReduceObject(obj) end)
        else
            if reduceConn then reduceConn:Disconnect(); reduceConn = nil end
            for obj, props in pairs(OriginalMap) do
                if obj and obj.Parent then
                    for k, v in pairs(props) do pcall(function() obj[k] = v end) end
                end
            end
            OriginalMap = {}
        end
    end)

    CreateToggle(OptInner, "Delete Particles", function(state)
        if state then
            for _, obj in ipairs(workspace:GetDescendants()) do HideParticle(obj) end
            particleConn = workspace.DescendantAdded:Connect(function(obj) task.wait(); HideParticle(obj) end)
        else
            if particleConn then particleConn:Disconnect(); particleConn = nil end
            for obj, wasEnabled in pairs(OriginalParticles) do
                if obj and obj.Parent then pcall(function() obj.Enabled = wasEnabled end) end
            end
            OriginalParticles = {}
        end
    end)
end -- <== TUTUP BUNGKUS MEMORI OPTIMIZE
SendNotification("[MODUL] 4/8 - Page Optimize selesai dibuat", 2)

CreateSidebarTab("71744475953983", "124929807761049", false, {OptimizePageContainer})

-- =====================================================================
-- PAGE 5: SETTINGS (Font)
-- =====================================================================
local SettingPageContainer = Instance.new("Frame", MainFrame)
SettingPageContainer.Size               = UDim2.new(1, -60, 1, 0)
SettingPageContainer.Position           = UDim2.new(0, 60, 0, 0)
SettingPageContainer.BackgroundTransparency = 1
SettingPageContainer.Visible            = false

do -- <== BUNGKUS MEMORI SETTINGS
    local SetTopNav = Instance.new("Frame", SettingPageContainer)
    SetTopNav.Size               = UDim2.new(1, 0, 0, 50)
    SetTopNav.BackgroundTransparency = 1
    Instance.new("UIPadding", SetTopNav).PaddingLeft = UDim.new(0, 30)

    local SetCatLbl = Instance.new("TextLabel", SetTopNav)
    SetCatLbl.Size               = UDim2.new(0, 0, 1, 0)
    SetCatLbl.AutomaticSize      = Enum.AutomaticSize.X
    SetCatLbl.BackgroundTransparency = 1
    SetCatLbl.Text               = "SCRIPT SETTINGS"
    SetCatLbl.TextColor3         = C.WHITE
    SetCatLbl.Font               = Enum.Font.GothamMedium
    SetCatLbl.TextSize           = 13

    local SetCatLine = Instance.new("Frame", SetCatLbl)
    SetCatLine.Size             = UDim2.new(1, 0, 0, 2)
    SetCatLine.Position         = UDim2.new(0, 0, 0.5, 10)
    SetCatLine.BackgroundColor3 = C.UNDERLINE
    SetCatLine.BorderSizePixel  = 0

    local SetBg = Instance.new("Frame", SettingPageContainer)
    SetBg.Size             = UDim2.new(1, 0, 1, -50)
    SetBg.Position         = UDim2.new(0, 0, 0, 50)
    SetBg.BackgroundColor3 = C.BG_DARKER
    SetBg.BorderSizePixel  = 0
    Instance.new("UICorner", SetBg).CornerRadius = UDim.new(0, 12)

    local PatchLeftSet = Instance.new("Frame", SetBg)
    PatchLeftSet.Size             = UDim2.new(0, 15, 1, 0)
    PatchLeftSet.BackgroundColor3 = C.BG_DARKER
    PatchLeftSet.BorderSizePixel  = 0

    local SetLeftContainer = Instance.new("Frame", SetBg)
    SetLeftContainer.Size               = UDim2.new(0, 320, 1, -30)
    SetLeftContainer.Position           = UDim2.new(0, 12, 0, 12)
    SetLeftContainer.BackgroundTransparency = 1
    local SetLayout = Instance.new("UIListLayout", SetLeftContainer)
    SetLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SetLayout.Padding   = UDim.new(0, 12)

    local function MakeSettingDropdownBox(parent, zIdx, labelText, btnDefault, btnWidth)
        local Box = Instance.new("Frame", parent)
        Box.Size             = UDim2.new(1, 0, 0, 50)
        Box.BackgroundColor3 = C.BG_DARK
        Box.BorderSizePixel  = 0
        Box.ZIndex           = zIdx
        Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)

        local Lbl = Instance.new("TextLabel", Box)
        Lbl.Size               = UDim2.new(1, -80, 1, 0)
        Lbl.Position           = UDim2.new(0, 15, 0, 0)
        Lbl.BackgroundTransparency = 1
        Lbl.Text               = labelText
        Lbl.TextColor3         = C.WHITE
        Lbl.Font               = Enum.Font.Gotham
        Lbl.TextSize           = 12
        Lbl.TextXAlignment     = Enum.TextXAlignment.Left
        Lbl.ZIndex             = zIdx

        local Btn = Instance.new("TextButton", Box)
        Btn.Size             = UDim2.new(0, btnWidth or 80, 0, 24)
        Btn.Position         = UDim2.new(1, -(btnWidth or 80) - 15, 0.5, -12)
        Btn.BackgroundColor3 = C.ACCENT
        Btn.Text             = btnDefault
        Btn.TextColor3       = C.WHITE
        Btn.Font             = Enum.Font.GothamMedium
        Btn.TextSize         = 11
        Btn.AutoButtonColor  = false
        Btn.ZIndex           = zIdx
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
        ApplyPressAnimation(Btn)

        return Box, Btn
    end

    local FontBox, FontBtn = MakeSettingDropdownBox(SetLeftContainer, 40, "Font", "Gotham")
    local FontOptions = {"Gotham","SourceSans","Arial","Roboto","Cartoon","Code","SciFi","Arcade","Bodoni"}
    local FontDict = {
        Gotham="Gotham", SourceSans="SourceSans", Arial="Arial", Roboto="Roboto",
        Cartoon="Cartoon", Code="Code", SciFi="SciFi", Arcade="Arcade", Bodoni="Bodoni"
    }
    for k, v in pairs(FontDict) do FontDict[k] = Enum.Font[v] end

    local FontDrop
    FontDrop = CreateDropdown(FontBtn, FontOptions, function(sel)
        if FontDrop then
            FontDrop.SetSelected(sel)
            FontDrop.Container.Visible = false
            local chosenFont = FontDict[sel]
            if chosenFont then
                for _, obj in pairs(MainFrame:GetDescendants()) do
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                        pcall(function() obj.Font = chosenFont end)
                    end
                end
            end
        end
    end)
    FontDrop.SetSelected("Gotham")
end -- <== TUTUP BUNGKUS MEMORI SETTINGS
SendNotification("[MODUL] 5/8 - Page Settings selesai dibuat", 2)

CreateSidebarTab("121289652987098", "80809761456188", false, {SettingPageContainer})



-- =====================================================================
-- PAGE 6: PROFILE (Avatar + Info + Discord + Notes)
-- =====================================================================
do -- <== BUNGKUS MEMORI PAGE 6
local ProfilePageContainer = Instance.new("Frame", MainFrame)
ProfilePageContainer.Size               = UDim2.new(1, -60, 1, 0)
ProfilePageContainer.Position           = UDim2.new(0, 60, 0, 0)
ProfilePageContainer.BackgroundTransparency = 1
ProfilePageContainer.Visible            = false

local ProfileBg = Instance.new("Frame", ProfilePageContainer)
ProfileBg.Size             = UDim2.new(1, 0, 1, 0)
ProfileBg.BackgroundColor3 = C.BG_DARKER
ProfileBg.BorderSizePixel  = 0
Instance.new("UICorner", ProfileBg).CornerRadius = UDim.new(0, 12)

local PatchLeftProfile = Instance.new("Frame", ProfileBg)
PatchLeftProfile.Size             = UDim2.new(0, 15, 1, 0)
PatchLeftProfile.BackgroundColor3 = C.BG_DARKER
PatchLeftProfile.BorderSizePixel  = 0

-- Avatar besar
local BigAvatarBg = Instance.new("Frame", ProfileBg)
BigAvatarBg.Size             = UDim2.new(0, 80, 0, 80)
BigAvatarBg.Position         = UDim2.new(0.5, 0, 0, 20)
BigAvatarBg.AnchorPoint      = Vector2.new(0.5, 0)
BigAvatarBg.BackgroundColor3 = C.WHITE
Instance.new("UICorner", BigAvatarBg).CornerRadius = UDim.new(1, 0)

local BigAvatar = Instance.new("ImageLabel", BigAvatarBg)
BigAvatar.Size                 = UDim2.new(1, -4, 1, -4)
BigAvatar.Position             = UDim2.new(0.5, 0, 0.5, 0)
BigAvatar.AnchorPoint          = Vector2.new(0.5, 0.5)
BigAvatar.BackgroundTransparency = 1
BigAvatar.Image                = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150"
Instance.new("UICorner", BigAvatar).CornerRadius = UDim.new(1, 0)

-- Nama & Username
local ProfileDisplayName = Instance.new("TextLabel", ProfileBg)
ProfileDisplayName.Size               = UDim2.new(1, 0, 0, 25)
ProfileDisplayName.Position           = UDim2.new(0, 0, 0, 105)
ProfileDisplayName.BackgroundTransparency = 1
ProfileDisplayName.Text               = LocalPlayer.DisplayName
ProfileDisplayName.TextColor3         = C.WHITE
ProfileDisplayName.Font               = Enum.Font.GothamMedium
ProfileDisplayName.TextSize           = 22

local ProfileUsername = Instance.new("TextLabel", ProfileBg)
ProfileUsername.Size               = UDim2.new(1, 0, 0, 20)
ProfileUsername.Position           = UDim2.new(0, 0, 0, 128)
ProfileUsername.BackgroundTransparency = 1
ProfileUsername.Text               = "@" .. LocalPlayer.Name
ProfileUsername.TextColor3         = C.WHITE
ProfileUsername.Font               = Enum.Font.Gotham
ProfileUsername.TextSize           = 14

-- Kolom Info (Didesain ulang agar mendukung multi-baris)
local ColW, ColGap = 150, 10

local function MakeInfoCol(parent, xPos, yPos, titleText)
    local Col = Instance.new("Frame", parent)
    Col.Size               = UDim2.new(0, ColW, 0, 45)
    Col.Position           = UDim2.new(0.5, xPos, 0, yPos)
    Col.BackgroundTransparency = 1

    local T = Instance.new("TextLabel", Col)
    T.Size               = UDim2.new(1, 0, 0, 16)
    T.BackgroundTransparency = 1
    T.Text               = titleText
    T.TextColor3         = C.WHITE
    T.Font               = Enum.Font.GothamMedium
    T.TextSize           = 12
    T.TextXAlignment     = Enum.TextXAlignment.Center

    return Col
end

-- BARIS 1 INFO (Status, Discord, Game)
local row1Y = 155

local colStatus = MakeInfoCol(ProfileBg, -(ColW + ColGap + ColW/2), row1Y, "Status Script")
local statusVal = Instance.new("TextLabel", colStatus)
statusVal.Size               = UDim2.new(1, 0, 0, 18)
statusVal.Position           = UDim2.new(0, 0, 0, 18)
statusVal.BackgroundTransparency = 1
statusVal.Text               = "Premium"
statusVal.TextColor3         = C.ACCENT
statusVal.Font               = Enum.Font.Gotham
statusVal.TextSize           = 11
statusVal.TextXAlignment     = Enum.TextXAlignment.Center

local colDiscord = MakeInfoCol(ProfileBg, -ColW/2, row1Y, "Discord Server")
local CopyDiscordBtn = Instance.new("TextButton", colDiscord)
CopyDiscordBtn.Size             = UDim2.new(1, 0, 0, 22)
CopyDiscordBtn.Position         = UDim2.new(0, 0, 0, 18)
CopyDiscordBtn.BackgroundColor3 = C.ACCENT
CopyDiscordBtn.Text             = "Salin Link"
CopyDiscordBtn.TextColor3       = C.WHITE
CopyDiscordBtn.Font             = Enum.Font.GothamMedium
CopyDiscordBtn.TextSize         = 11
CopyDiscordBtn.AutoButtonColor  = false
Instance.new("UICorner", CopyDiscordBtn).CornerRadius = UDim.new(0, 5)

CopyDiscordBtn.MouseButton1Click:Connect(function()
    local link = "https://discord.gg/GTYXzxsKE"
    if setclipboard then setclipboard(link)
    elseif toclipboard then toclipboard(link) end
    local orig = CopyDiscordBtn.Text
    CopyDiscordBtn.Text             = "✅ Tersalin!"
    CopyDiscordBtn.BackgroundColor3 = C.GREEN
    task.delay(1.5, function()
        CopyDiscordBtn.Text             = orig
        CopyDiscordBtn.BackgroundColor3 = C.ACCENT
    end)
end)

local colGame = MakeInfoCol(ProfileBg, ColGap + ColW/2, row1Y, "Game Name")
local gameVal = Instance.new("TextLabel", colGame)
gameVal.Size               = UDim2.new(1, 0, 0, 18)
gameVal.Position           = UDim2.new(0, 0, 0, 18)
gameVal.BackgroundTransparency = 1
gameVal.Text               = "Sambung Kata"
gameVal.TextColor3         = C.TEXT_DIM
gameVal.Font               = Enum.Font.Gotham
gameVal.TextSize           = 11
gameVal.TextXAlignment     = Enum.TextXAlignment.Center

-- BARIS 2 INFO (Update Terakhir, Durasi Key & Executor)
local row2Y = 205

local colUpdate = MakeInfoCol(ProfileBg, -(ColW + ColGap + ColW/2), row2Y, "Update Terakhir")
local updateVal = Instance.new("TextLabel", colUpdate)
updateVal.Size               = UDim2.new(1, 0, 0, 18)
updateVal.Position           = UDim2.new(0, 0, 0, 18)
updateVal.BackgroundTransparency = 1
updateVal.Text               = "03/07/26"
updateVal.TextColor3         = C.TEXT_DIM
updateVal.Font               = Enum.Font.Gotham
updateVal.TextSize           = 11
updateVal.TextXAlignment     = Enum.TextXAlignment.Center

local colDurasi = MakeInfoCol(ProfileBg, -ColW/2, row2Y, "Durasi Key")
local durasiVal = Instance.new("TextLabel", colDurasi)
durasiVal.Size               = UDim2.new(1, 0, 0, 18)
durasiVal.Position           = UDim2.new(0, 0, 0, 18)
durasiVal.BackgroundTransparency = 1
durasiVal.Text               = "Permanen"
durasiVal.TextColor3         = C.GREEN
durasiVal.Font               = Enum.Font.GothamBold
durasiVal.TextSize           = 11
durasiVal.TextXAlignment     = Enum.TextXAlignment.Center

local colExecutor = MakeInfoCol(ProfileBg, ColGap + ColW/2, row2Y, "Executor")
local execVal = Instance.new("TextLabel", colExecutor)
execVal.Size               = UDim2.new(1, 0, 0, 18)
execVal.Position           = UDim2.new(0, 0, 0, 18)
execVal.BackgroundTransparency = 1

-- Deteksi otomatis nama executor
local execName = "Unknown"
pcall(function()
    if identifyexecutor then
        execName = identifyexecutor()
    end
end)

execVal.Text               = execName
execVal.TextColor3         = C.ACCENT_LT
execVal.Font               = Enum.Font.GothamBold
execVal.TextSize           = 11
execVal.TextXAlignment     = Enum.TextXAlignment.Center

-- CATATAN / NOTE BOX
local NoteBox = Instance.new("Frame", ProfileBg)
NoteBox.Size = UDim2.new(1, -40, 0, 42)
NoteBox.Position = UDim2.new(0, 20, 0, 255)
NoteBox.BackgroundColor3 = C.BG_DARK
NoteBox.BorderSizePixel = 0
Instance.new("UICorner", NoteBox).CornerRadius = UDim.new(0, 6)

local NoteTitle = Instance.new("TextLabel", NoteBox)
NoteTitle.Size = UDim2.new(0, 60, 1, 0)
NoteTitle.Position = UDim2.new(0, 10, 0, 0)
NoteTitle.BackgroundTransparency = 1
NoteTitle.Text = "📌 NOTE:"
NoteTitle.TextColor3 = C.ACCENT
NoteTitle.Font = Enum.Font.GothamBold
NoteTitle.TextSize = 11
NoteTitle.TextXAlignment = Enum.TextXAlignment.Left

local NoteDesc = Instance.new("TextLabel", NoteBox)
NoteDesc.Size = UDim2.new(1, -75, 1, 0)
NoteDesc.Position = UDim2.new(0, 65, 0, 0)
NoteDesc.BackgroundTransparency = 1
NoteDesc.Text = "Dengan menggunakan script ini, Anda menyadari dan menerima segala risiko yang mungkin terjadi (termasuk sanksi pemblokiran akun). Gunakan dengan bijak."
NoteDesc.TextColor3 = C.TEXT_DIM
NoteDesc.Font = Enum.Font.Gotham
NoteDesc.TextSize = 10
NoteDesc.TextXAlignment = Enum.TextXAlignment.Left
NoteDesc.TextWrapped = true

-- Tombol avatar kiri bawah (Profile Tab)
local ProfileTabBtn = Instance.new("TextButton", MainFrame)
ProfileTabBtn.Size             = UDim2.new(0, 38, 0, 38)
ProfileTabBtn.Position         = UDim2.new(0, 11, 1, -11)
ProfileTabBtn.AnchorPoint      = Vector2.new(0, 1)
ProfileTabBtn.BackgroundColor3 = C.ACCENT
ProfileTabBtn.Text             = ""
ProfileTabBtn.AutoButtonColor  = false
Instance.new("UICorner", ProfileTabBtn).CornerRadius = UDim.new(1, 0)

local ProfileTabIcon = Instance.new("ImageLabel", ProfileTabBtn)
ProfileTabIcon.Size                 = UDim2.new(1, -4, 1, -4)
ProfileTabIcon.Position             = UDim2.new(0.5, 0, 0.5, 0)
ProfileTabIcon.AnchorPoint          = Vector2.new(0.5, 0.5)
ProfileTabIcon.BackgroundTransparency = 1
ProfileTabIcon.Image                = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150"
Instance.new("UICorner", ProfileTabIcon).CornerRadius = UDim.new(1, 0)

SidebarTabs[ProfileTabBtn] = {Icon = ProfileTabIcon, Elements = {ProfilePageContainer}}

ProfileTabBtn.MouseButton1Click:Connect(function()
    for tBtn, data in pairs(SidebarTabs) do
        tBtn.BackgroundColor3 = C.ACCENT
        if data.IdInactive and data.Icon then
            data.Icon.Image = "rbxthumb://type=Asset&id=" .. data.IdInactive .. "&w=150&h=150"
        end
        if data.Elements then
            for _, el in ipairs(data.Elements) do el.Visible = false end
        end
    end
    ProfileTabBtn.BackgroundColor3 = C.WHITE
    ProfilePageContainer.Visible   = true
end)
end -- <== TUTUP BUNGKUS PAGE 6
SendNotification("[MODUL] 6/8 - Page 6 (Profile) selesai, semua halaman UI sudah dibuat", 2)


-- =====================================================================
-- CORE LOGIC GAMEPLAY (AUTO KETIK, PUSH INDEX, HUMAN MODE, AUTO JOIN)
-- =====================================================================
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local CFG = State.CFG

State.priorityEnd = "OFF"
State.pushTarget = "a"
State.lastAnswer = ""
State.currentMistakes = 0

local _mt, _mtIndex = nil, nil

local function GaussWait(min, max)
    local u1 = math.max(1e-10, math.random())
    local u2 = math.random()
    local z  = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    local mean = (min + max) / 2
    local stddev = (max - min) / 4
    task.wait(math.clamp(mean + stddev * z, min * 0.5, max * 1.8))
end

local function GetMistakeCount()
    local attr = LocalPlayer:GetAttribute("Mistake")
    if attr ~= nil then return tonumber(attr) or 0 end
    local obj = LocalPlayer:FindFirstChild("Mistake")
    if obj then return obj.Value end
    return 0
end

local function GetTableState()
    local attr = LocalPlayer:GetAttribute("TableState")
    if attr ~= nil then return tostring(attr) end
    local obj = LocalPlayer:FindFirstChild("TableState")
    if obj then return obj.Value end
    return ""
end

local function IsMyTurn()
    local attr = LocalPlayer:GetAttribute("IsTurn")
    if attr ~= nil then return attr == true end
    local obj = LocalPlayer:FindFirstChild("IsTurn")
    if obj then return obj.Value == true end
    return false
end

local function GetWrongLetter(correct)
    local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local wrong = correct
    while wrong == correct do
        local r = math.random(1, 26)
        wrong = letters:sub(r, r)
    end
    return wrong
end

local function SpoofToPC()
    if State.isSpoofed then return end
    pcall(function()
        _mt = getrawmetatable(UIS); _mtIndex = _mt.__index; setreadonly(_mt, false)
        _mt.__index = function(self, key)
            if key == "MouseEnabled" then return true end 
            if type(_mtIndex) == "function" then return _mtIndex(self, key) end
            return rawget(self, key)
        end
        setreadonly(_mt, true)
    end)
    pcall(function() LocalPlayer.DevTouchMovementMode = Enum.DevTouchMovementMode.ClickToMove end)
    State.isSpoofed = true
end

local function RestoreToMobile()
    if not State.isSpoofed then return end
    pcall(function() if _mt and _mtIndex then setreadonly(_mt, false); _mt.__index = _mtIndex; setreadonly(_mt, true) end end)
    pcall(function() LocalPlayer.DevTouchMovementMode = Enum.DevTouchMovementMode.DynamicThumbstick end)
    State.isSpoofed = false
end

local EasyEnd = { a=1,e=1,i=1,o=1,u=1,n=1,r=1,s=1,t=1,l=1,m=1,k=1,p=1,d=1,g=1,b=1,h=1,c=1 }
local function Score(w)
    return (EasyEnd[w:sub(-1)] and 0 or 2) + ((#w<4) and 3 or (#w<=7) and 0 or (#w<=9) and 1 or 2)
end

local function UpdatePushTarget()
    if not State.pushIndexMode then return end
    local alphabets = "abcdefghijklmnopqrstuvwxyz"
    local idx = alphabets:find(State.pushTarget) or 1
    while idx <= 26 do
        local curLetter = alphabets:sub(idx, idx)
        local hasWords = false
        if EndsWith[curLetter] then
            for _, w in ipairs(EndsWith[curLetter]) do
                if not State.pool2[w] and not State.pool3[w] then hasWords = true; break end
            end
        end
        if hasWords then State.pushTarget = curLetter; break end
        idx = idx + 1
    end
end

local function FindWords(prefix)
    prefix = prefix:lower():gsub("[^a-z]","")
    if #prefix == 0 then return {} end
    local list = (#prefix >= 2 and Prefix2[prefix:sub(1,2)]) or Prefix1[prefix:sub(1,1)]
    if not list then return {} end
    
    UpdatePushTarget()
    local p1, p2, p3, p4 = {}, {}, {}, {}
    local seen = {}
    
    for _, w in ipairs(list) do
        if w:sub(1,#prefix) == prefix and #w > #prefix and not seen[w] and not State.pool2[w] then
            seen[w]=true
            local inPool3 = State.pushIndexMode and State.pool3[w] or false
            if State.pushIndexMode then
                local isTarget = (w:sub(-1) == State.pushTarget)
                if not inPool3 and isTarget then table.insert(p1, w)
                elseif inPool3 and isTarget then table.insert(p2, w)
                elseif not inPool3 then table.insert(p3, w)
                else table.insert(p4, w) end
            else
                local isPrio = false
                if State.priorityEnd == "ALL" then
                    local end1, end2 = w:sub(-1), w:sub(-2)
                    local bad = {a=1,b=1,c=1,f=1,v=1,x=1,z=1,y=1,i=1,u=1,n=1, cy=1,["if"]=1,ex=1,eh=1,ah=1,az=1,as=1}
                    if bad[end1] or bad[end2] then isPrio = true end
                elseif State.priorityEnd ~= "OFF" then
                    isPrio = (w:sub(-#State.priorityEnd) == State.priorityEnd)
                end

                if not inPool3 then
                    if isPrio then table.insert(p1, w) else table.insert(p3, w) end
                else
                    if isPrio then table.insert(p2, w) else table.insert(p4, w) end
                end
            end
        end
    end
    local function sortReturn(tbl) if #tbl>0 then table.sort(tbl, function(a,b) return Score(a)<Score(b) end); return tbl end return nil end
    return sortReturn(p1) or sortReturn(p2) or sortReturn(p3) or sortReturn(p4) or {}
end

local function SetupKeyboard()
    task.spawn(function()
        local kb = PlayerGui:WaitForChild("MatchUI", 10) and PlayerGui.MatchUI:WaitForChild("BottomUI", 10) and PlayerGui.MatchUI.BottomUI:WaitForChild("Keyboard", 10)
        if not kb then return end
        State.keyMap, State.enterBtn = {}, nil
        for i = 1, 4 do
            local row = kb:FindFirstChild("Row"..i)
            if row then
                for _, btn in pairs(row:GetChildren()) do
                    if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                        local text = btn:IsA("TextButton") and btn.Text:lower():gsub("%s", "") or ""
                        local name = btn.Name:lower():gsub("%s", "")
                        if name == "enter" or name == "masuk" or text == "enter" or text == "masuk" then 
                            State.enterBtn = btn
                        else
                            if #text == 1 and text:match("[a-z]") then State.keyMap[text] = btn
                            elseif #name == 1 and name:match("[a-z]") and not State.keyMap[name] then State.keyMap[name] = btn end
                        end
                    end
                end
            end
        end
        local kc = 0; for _ in pairs(State.keyMap) do kc=kc+1 end
        State.keyboardReady = kc > 0 and State.enterBtn ~= nil
        kb.AncestryChanged:Connect(function(_, p) if not p then State.keyboardReady=false; task.wait(2); SetupKeyboard() end end)
    end)
end

local function SetupWordServer()
    task.spawn(function()
        local label = nil
        while not label do
            for _, v in ipairs(PlayerGui:GetDescendants()) do if v:IsA("TextLabel") and v.Name == "WordServer" then label = v; break end end
            if not label then task.wait(0.5) end
        end
        State.wordServerRef, State.wordServerReady = label, true
        label:GetPropertyChangedSignal("Text"):Connect(function()
            if not State.isTyping then local n = label.Text:lower():gsub("[^a-z]",""); if n ~= "" then State.currentLetter = n end end
        end)
        label.AncestryChanged:Connect(function(_, p) if not p then State.wordServerReady=false; task.wait(2); SetupWordServer() end end)
    end)
end

local function TypeWord(word)
    if not State.keyboardReady then return false end
    State.isTyping = true 
    
    if State.humanMode then task.wait(0.1) end
    
    local typoIdx = -1
    if State.humanMode and #word >= 1 and math.random(1, 100) <= 35 then
        local maxOffset = math.min(3, #word) 
        typoIdx = #word - math.random(0, maxOffset - 1)
    end
    
    local function PressKey(chStr)
        local kc = Enum.KeyCode[chStr]
        if kc then
            pcall(function() 
                VIM:SendKeyEvent(true, kc, false, game)
                task.wait(CFG.HOLD_MIN + math.random()*(CFG.HOLD_MAX-CFG.HOLD_MIN))
                VIM:SendKeyEvent(false, kc, false, game) 
            end)
        end
    end
    
    for i = 1, #word do
        if not State.active then State.isTyping = false; return false end 
        
        local ch = word:sub(i, i):upper()
        if State.humanMode and i == typoIdx then
            local typoCount = math.random(1, 3)
            
            for _ = 1, typoCount do
                local wrongCh = GetWrongLetter(ch)
                PressKey(wrongCh)
                GaussWait(CFG.KEY_MIN, CFG.KEY_MAX)
            end
            
            task.wait(0.5 + (math.random() ^ 3) * 0.5)
            
            for _ = 1, typoCount do
                pcall(function() 
                    VIM:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
                    task.wait(0.02)
                    VIM:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game) 
                end)
                GaussWait(CFG.DEL_MIN, CFG.DEL_MAX)
            end
        end
        
        PressKey(ch)
        GaussWait(CFG.KEY_MIN, CFG.KEY_MAX)
    end
    
    GaussWait(CFG.ENTER_MIN, CFG.ENTER_MAX)
    
    pcall(function() 
        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.02)
        VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game) 
    end)
    
    State.isTyping = false 
    return true
end



local function ProcessLetter(letter)
    State.isProcessing = true
    task.spawn(function()
        local options = FindWords(letter)
        local answer = nil
        if #options > 0 then
            answer = options[math.random(1, math.min(#options, 20))]
        end
        
        if State.isRetrying then State.isRetrying = false else GaussWait(CFG.ANS_MIN, CFG.ANS_MAX) end
        
        if not State.active or not IsMyTurn() then State.isProcessing = false; return end
        
        if answer then
            State.hasAnsweredThisTurn = true
            State.lastAnswer = answer
            local ok = TypeWord(answer:sub(#letter + 1))
            if ok then 
                State.pool2[answer] = true 
            else
                State.hasAnsweredThisTurn = false 
            end
        else
            State.hasAnsweredThisTurn = true
        end
        task.wait(0.5)
        State.isProcessing = false
    end)
end

-- =====================================================================
-- LOOP UTAMA & UPDATE UI
-- =====================================================================
task.spawn(function()
    SetupKeyboard()
    SetupWordServer()
    while true do
        task.wait(0.25)
        local curTurn = IsMyTurn()
        local curMistake = GetMistakeCount()
        local curTableState = GetTableState()

        -- Update UI Panel Kanan
        pcall(function()
            local ltr = State.currentLetter ~= "" and State.currentLetter:upper() or "-"
            LblAwalan.Text = "Kata Awalan: " .. ltr

            local devInfo = State.isSpoofed and "PC (Spoofed)" or "Mobile"
            local kbbiInfo = State.kbbiReady and tostring(State.wordCount) .. " Kata" or (State.kbbiFailed and "Gagal Memuat (cek koneksi)" or "Memuat...")
            LblKBBI.Text = "KBBI: " .. kbbiInfo .. "\nDevice: " .. devInfo

            local p2C, p3C = 0, 0
            for _ in pairs(State.pool2) do p2C = p2C + 1 end
            for _ in pairs(State.pool3) do p3C = p3C + 1 end
            local p1C = State.wordCount - p2C - p3C
            if p1C < 0 then p1C = 0 end
            LblIndex.Text = "Sisa Kata: " .. p1C .. "\nKata dipakai saat ini: " .. p2C .. "\nKata Dipakai Sebelumnya: " .. p3C

            local wins, losses, money = 0, 0, 0
            local ls = LocalPlayer:FindFirstChild("leaderstats")
            if ls then
                local wObj = ls:FindFirstChild("Wins") or ls:FindFirstChild("Win") or ls:FindFirstChild("Menang")
                if wObj then wins = tonumber(wObj.Value) or 0 end
                local lObj = ls:FindFirstChild("Losses") or ls:FindFirstChild("Kalah")
                if lObj then losses = tonumber(lObj.Value) or 0 end
                local mObj = ls:FindFirstChild("Money") or ls:FindFirstChild("Uang")
                if mObj then money = tonumber(mObj.Value) or 0 end
            end
            local total = wins + losses
            local wr = total > 0 and math.floor((wins / total) * 100) or 0
            LblStats.Text = string.format("Winrate: %d%%\nMenang: %d\nKalah: %d\nUang: Rp%s", wr, wins, losses, FormatRibuan(money))
        end)

        -- Logika Auto Join
        if State.autoJoinMode and (curTableState == "" or curTableState == "None") then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Parent and prompt.Parent:IsA("BasePart") then
                        if (prompt.Parent.Position - hrp.Position).Magnitude <= (prompt.MaxActivationDistance + 2) then
                            pcall(function() if fireproximityprompt then fireproximityprompt(prompt) else prompt:InputHoldBegin(); task.wait(prompt.HoldDuration + 0.05); prompt:InputHoldEnd() end end)
                            task.wait(1.5); break
                        end
                    end
                end
            end
        end

        -- Logika Reset Tabel & Spoof
        if curTableState ~= State.lastTableState then
            if curTableState == "Playing" or State.lastTableState == "Playing" then
                if State.pushIndexMode then for k, v in pairs(State.pool2) do State.pool3[k] = true end end
                State.pool2 = {}
            end
            if curTableState ~= "" and curTableState ~= "None" then if State.active then SpoofToPC() end else RestoreToMobile() end
            State.lastTableState = curTableState
        end

        -- Logika Giliran
        if curTurn ~= State.lastTurnState then
            State.lastTurnState = curTurn
            if not curTurn then 
                State.hasAnsweredThisTurn = false
                State.isProcessing = false
                State.isTyping = false
                State.isRetrying = false 
            else 
                State.currentMistakes = curMistake 
            end
        end

        -- Logika Pengetikan
        if State.active then
            if curTurn and curMistake > State.currentMistakes then
                State.currentMistakes = curMistake
                State.hasAnsweredThisTurn = false
                State.isProcessing = false
                State.isTyping = true
                State.isRetrying = true
                
                local deleteCount = 10
                if State.lastAnswer ~= "" then
                    deleteCount = #State.lastAnswer + 3
                    State.pool2[State.lastAnswer] = true
                end
                
                for i = 1, deleteCount do
                    pcall(function()
                        VIM:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
                        task.wait(0.02)
                        VIM:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
                    end)
                    GaussWait(CFG.DEL_MIN, CFG.DEL_MAX)
                end
                
                State.isTyping = false
                task.wait(0.05)
                
                if curMistake >= 5 then
                    State.hasAnsweredThisTurn = true
                    State.isRetrying = false
                end
            end
            
            if curTurn and not State.hasAnsweredThisTurn and not State.isProcessing and not State.isTyping and State.wordServerRef and State.wordServerRef.Parent then
                local txt = State.wordServerRef.Text:lower():gsub("[^a-z]","")
                if txt ~= "" then 
                    State.currentLetter = txt
                    ProcessLetter(txt) 
                end
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    if State.active and GetTableState() ~= "" and GetTableState() ~= "None" then SpoofToPC() end
    if not State.keyboardReady then SetupKeyboard() end
    if not State.wordServerReady then SetupWordServer() end
end)

-- Load KBBI (Menggunakan CDN JSDelivr & Statically untuk Bypass Rate-Limit GitHub)
task.spawn(function()
    -- Kita gunakan 2 CDN terbaik sebagai jalur utama dan cadangan
    local KBBI_URLS = {
        "https://cdn.jsdelivr.net/gh/ryxx17/Sambungkata@main/sb.txt",
        "https://cdn.statically.io/gh/ryxx17/Sambungkata/main/sb.txt"
    }
    
    local MAX_ATTEMPT = 3 -- Coba 3 kali dengan jalur berbeda
    local loaded = false

    for attempt = 1, MAX_ATTEMPT do
        local url = KBBI_URLS[((attempt - 1) % #KBBI_URLS) + 1]
        local ok, res = pcall(function() return game:HttpGet(url) end)
        
        -- Validasi: Pastikan sukses, berupa teks, ukurannya besar, dan bukan halaman error
        if ok and type(res) == "string" and #res > 5000 and not res:match("Rate limit") and not res:match("404") then
            local words, wc = {}, 0
            for word in res:gmatch("[^\r\n]+") do
                local w = word:lower():gsub("%s","")
                if w:match("^[a-z]+$") and #w >= 3 then
                    wc = wc + 1
                    words[wc] = w
                end
            end
            
            -- Jika berhasil mengekstrak lebih dari 100 kata, berarti file valid
            if wc >= 100 then
                for _, w in ipairs(words) do
                    local p1, p2 = w:sub(1,1), w:sub(1,2)
                    Prefix1[p1] = Prefix1[p1] or {}; table.insert(Prefix1[p1], w)
                    Prefix2[p2] = Prefix2[p2] or {}; table.insert(Prefix2[p2], w)
                    local lastChar = w:sub(-1)
                    EndsWith[lastChar] = EndsWith[lastChar] or {}
                    table.insert(EndsWith[lastChar], w)
                end
                State.kbbiReady = true
                State.wordCount = wc
                loaded = true
                NotifyAfterMenu("KBBI berhasil dimuat: " .. tostring(wc) .. " kata", 3)
                break
            end
        end
        
        -- Jika gagal, tunggu 1 detik lalu coba link CDN cadangan
        if attempt < MAX_ATTEMPT then 
            task.wait(1) 
        end
    end

    -- Jika semua CDN gagal (misal tidak ada internet)
    if not loaded then 
        State.kbbiFailed = true 
        NotifyAfterMenu("Gagal memuat KBBI: cek koneksi internet", 4)
    end
end)

SendNotification("[MODUL] 7/8 - Semua logic (auto ketik, loop utama, KBBI) selesai di-setup", 2)
end -- <== TUTUP return function(Core) -- akhir dari modul wordchain


