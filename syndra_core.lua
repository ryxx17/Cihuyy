-- =====================================================================
-- SYNDRA V2 - TAHAP 1 (REFACTORED & CLEAN)
-- =====================================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local ContentProvider  = game:GetService("ContentProvider")

-- Tunggu LocalPlayer siap (mencegah error saat auto-execute)
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)


-- =====================================================================
-- STATE BERSAMA (field khusus tiap game ditambahkan oleh modulnya sendiri
-- saat dijalankan -- lihat Core.State di bagian dispatcher di bawah)
-- =====================================================================
local State = {
    IsAuthenticated     = false
}

local Core, GameModules -- forward declaration, diisi setelah semua utilitas & GUI core selesai dibangun

-- Validasi key sekarang lewat server (bukan hardcode) -- GANTI URL ini
-- ke URL hosting key-server kamu (lihat README di proyek syndra-keysystem)
local API_BASE_URL = "syndra-ks-production.up.railway.app"

-- Coba beberapa nama fungsi HWID yang umum dipakai berbagai executor.
-- Kalau tidak ketemu, key tetap bisa dipakai tapi TANPA device-lock.
local function GetHWID()
    local candidates = { "gethwid", "get_hwid", "getidentifier", "get_identifier" }
    for _, name in ipairs(candidates) do
        local fn = getgenv and getgenv()[name] or _G[name]
        if type(fn) == "function" then
            local ok, id = pcall(fn)
            if ok and id and id ~= "" then return tostring(id) end
        end
    end
    return nil
end

-- Panggil key-server buat validasi. Return: valid (bool), reason (string)
local function ValidateKeyOnServer(keyInput)
    local HttpService = game:GetService("HttpService")
    local hwid = GetHWID()
    local url = API_BASE_URL .. "/validate?key=" .. HttpService:UrlEncode(keyInput)
    if hwid then url = url .. "&hwid=" .. HttpService:UrlEncode(hwid) end

    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok or not res then
        return false, "Tidak bisa terhubung ke server key (cek koneksi)"
    end

    local decodeOk, data = pcall(function() return HttpService:JSONDecode(res) end)
    if not decodeOk or type(data) ~= "table" then
        return false, "Respons server tidak valid"
    end

    return data.valid == true, data.reason or "Tidak diketahui"
end
local GET_KEY_LINK = "https://discord.gg/GTYXzxsKE"

local function FormatRibuan(n)
    local s = tostring(math.floor(n))
    local result = ""
    local len = #s
    for i = 1, len do
        if i > 1 and (len - i + 1) % 3 == 0 then result = result .. "," end
        result = result .. s:sub(i, i)
    end
    return result
end


-- =====================================================================
-- BYPASS COREGUII (aman untuk mobile executor)
-- =====================================================================
local SafeGuiParent
local ok = pcall(function()
    SafeGuiParent = gethui and gethui() or game:GetService("CoreGui")
end)
if not ok or not SafeGuiParent then SafeGuiParent = PlayerGui end

-- Hapus instance lama jika ada
local existing = SafeGuiParent:FindFirstChild("Syndra_V2_Preview")
if existing then existing:Destroy() end

-- =====================================================================
-- KONSTANTA WARNA
-- =====================================================================
local C = {
    BG_DARK   = Color3.fromHex("#19203c"),
    BG_DARKER = Color3.fromHex("#141b35"),
    ACCENT    = Color3.fromHex("#4ec9e4"),
    ACCENT_LT = Color3.fromHex("#9de1ee"),
    WHITE     = Color3.fromHex("#ffffff"),
    TEXT_DIM  = Color3.fromHex("#a0a8c8"),
    UNDERLINE  = Color3.fromHex("#58c1ff"),
    GREEN     = Color3.fromHex("#2ecc71"),
    RED       = Color3.fromHex("#e74c3c"),
    DROP_TEXT = Color3.fromHex("#01a7e1"),
    SEP_LINE  = Color3.fromHex("#e0e0e0"),
    LOGIN_BG  = Color3.fromHex("#151a2e"),
    INPUT_BG  = Color3.fromHex("#1e2338"),
}


-- =====================================================================
-- FUNGSI UTILITAS BERSAMA
-- =====================================================================

-- Animasi tekan tombol (dipakai di mana saja)
local function ApplyPressAnimation(btn)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            btn.BackgroundColor3 = C.WHITE
            btn.TextColor3       = C.ACCENT
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            btn.BackgroundColor3 = C.ACCENT
            btn.TextColor3       = C.WHITE
        end
    end)
end

-- Toggle switch (knob + background) — satu fungsi untuk semua halaman
local TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function CreateToggle(parent, titleText, onToggle)
    local Box = Instance.new("Frame", parent)
    Box.Size             = UDim2.new(1, 0, 0, 50)
    Box.BackgroundColor3 = C.BG_DARK
    Box.BorderSizePixel  = 0
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel", Box)
    Label.Size               = UDim2.new(1, -20, 0, 15)
    Label.Position           = UDim2.new(0, 10, 0, 8)
    Label.BackgroundTransparency = 1
    Label.Text               = titleText
    Label.TextColor3         = C.WHITE
    Label.Font               = Enum.Font.Gotham
    Label.TextSize           = 12
    Label.TextXAlignment     = Enum.TextXAlignment.Left

    local Bg = Instance.new("TextButton", Box)
    Bg.Size             = UDim2.new(0, 36, 0, 16)
    Bg.Position         = UDim2.new(0, 10, 0, 26)
    Bg.BackgroundColor3 = C.WHITE
    Bg.Text             = ""
    Bg.AutoButtonColor  = false
    Instance.new("UICorner", Bg).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame", Bg)
    Knob.Size             = UDim2.new(0, 12, 0, 12)
    Knob.Position         = UDim2.new(0, 2, 0.5, -6)
    Knob.BackgroundColor3 = C.ACCENT
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local isOn = false
    local function setState(newState, fireCallback)
        if isOn == newState then return end
        isOn = newState
        local pos   = isOn and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        local color = isOn and C.ACCENT_LT or C.WHITE
        TweenService:Create(Knob, TWEEN_INFO, {Position = pos}):Play()
        TweenService:Create(Bg,   TWEEN_INFO, {BackgroundColor3 = color}):Play()
        if fireCallback ~= false and onToggle then onToggle(isOn) end
    end
    Bg.MouseButton1Click:Connect(function()
        setState(not isOn)
    end)

    return Box, Bg, Knob, function() return isOn end, setState
end

-- =====================================================================
-- FUNGSI PEMBUAT DROPDOWN MENU
-- =====================================================================
local AllDropdowns = {}

local function CreateDropdown(btn, options, onSelect)
    local totalH = #options * 24
    local dropH  = math.min(totalH, 115)

    local Wrapper = Instance.new("Frame", btn)
    Wrapper.Size             = UDim2.new(1, 0, 0, dropH)
    Wrapper.Position         = UDim2.new(0, 0, 1, 4)
    Wrapper.BackgroundColor3 = C.WHITE
    Wrapper.BorderSizePixel  = 0
    Wrapper.ZIndex           = btn.ZIndex + 1
    Wrapper.Visible          = false
    table.insert(AllDropdowns, Wrapper)

    local Scroll = Instance.new("ScrollingFrame", Wrapper)
    Scroll.Size                  = UDim2.new(1, 0, 1, 0)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel       = 0
    Scroll.ZIndex                = Wrapper.ZIndex
    Scroll.ScrollBarThickness    = 0
    Scroll.CanvasSize            = UDim2.new(0, 0, 0, totalH)

    Instance.new("UIListLayout", Scroll).SortOrder = Enum.SortOrder.LayoutOrder

    local itemBtns = {}
    for i, option in ipairs(options) do
        local item = Instance.new("TextButton", Scroll)
        item.Size                = UDim2.new(1, 0, 0, 24)
        item.BackgroundTransparency = 1
        item.BorderSizePixel     = 0
        item.Text                = option
        item.TextColor3          = C.DROP_TEXT
        item.Font                = Enum.Font.GothamMedium
        item.TextSize            = 11
        item.ZIndex              = Scroll.ZIndex
        itemBtns[option]         = item

        if i < #options then
            local line = Instance.new("Frame", item)
            line.Size             = UDim2.new(1, -12, 0, 1)
            line.Position         = UDim2.new(0, 6, 1, -1)
            line.BackgroundColor3 = C.SEP_LINE
            line.BorderSizePixel  = 0
            line.ZIndex           = Scroll.ZIndex
        end

        item.MouseButton1Click:Connect(function()
            if onSelect then onSelect(option) end
        end)
    end

    local function SetSelected(val, displayText)
        btn.Text = displayText or val
        for opt, ib in pairs(itemBtns) do
            if opt == val then
                ib.BackgroundTransparency = 0
                ib.BackgroundColor3       = C.ACCENT
                ib.TextColor3             = C.WHITE
            else
                ib.BackgroundTransparency = 1
                ib.TextColor3             = C.DROP_TEXT
            end
        end
    end

    btn.MouseButton1Click:Connect(function()
        local wasOpen = Wrapper.Visible
        for _, d in ipairs(AllDropdowns) do d.Visible = false end
        if not wasOpen then Wrapper.Visible = true end
    end)

    return { SetSelected = SetSelected, Container = Wrapper }
end

-- =====================================================================
-- FUNGSI PEMBUAT HALAMAN SIDEBAR (menghindari duplikasi struktur page)
-- =====================================================================
local function CreatePageContainer(label)
    local Container = Instance.new("Frame", nil) -- parent diset nanti
    Container.Size                 = UDim2.new(1, -60, 1, 0)
    Container.Position             = UDim2.new(0, 60, 0, 0)
    Container.BackgroundTransparency = 1
    Container.Visible              = false

    -- Top nav bar dengan label kategori
    local TopNav = Instance.new("Frame", Container)
    TopNav.Size                  = UDim2.new(1, 0, 0, 50)
    TopNav.BackgroundTransparency = 1

    local NavPad = Instance.new("UIPadding", TopNav)
    NavPad.PaddingLeft = UDim.new(0, 30)

    local CatLabel = Instance.new("TextLabel", TopNav)
    CatLabel.Size               = UDim2.new(0, 0, 1, 0)
    CatLabel.AutomaticSize      = Enum.AutomaticSize.X
    CatLabel.BackgroundTransparency = 1
    CatLabel.Text               = label
    CatLabel.TextColor3         = C.WHITE
    CatLabel.Font               = Enum.Font.GothamMedium
    CatLabel.TextSize           = 13

    local CatLine = Instance.new("Frame", CatLabel)
    CatLine.Size             = UDim2.new(1, 0, 0, 2)
    CatLine.Position         = UDim2.new(0, 0, 0.5, 10)
    CatLine.BackgroundColor3 = C.UNDERLINE
    CatLine.BorderSizePixel  = 0


    -- Background konten
    local Bg = Instance.new("Frame", Container)
    Bg.Size             = UDim2.new(1, 0, 1, -50)
    Bg.Position         = UDim2.new(0, 0, 0, 50)
    Bg.BackgroundColor3 = C.BG_DARKER
    Bg.BorderSizePixel  = 0
    Instance.new("UICorner", Bg).CornerRadius = UDim.new(0, 12)

    -- Patch sudut kiri agar mepet sidebar
    local PatchLeft = Instance.new("Frame", Bg)
    PatchLeft.Size             = UDim2.new(0, 15, 1, 0)
    PatchLeft.BackgroundColor3 = C.BG_DARKER
    PatchLeft.BorderSizePixel  = 0

    -- Container isi
    local Inner = Instance.new("Frame", Bg)
    Inner.Size               = UDim2.new(0, 180, 1, -24)
    Inner.Position           = UDim2.new(0, 12, 0, 12)
    Inner.BackgroundTransparency = 1

    local Layout = Instance.new("UIListLayout", Inner)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding   = UDim.new(0, 8)

    return Container, Inner
end

-- =====================================================================
-- GUI UTAMA
-- =====================================================================
local SG = Instance.new("ScreenGui")
SG.Name          = "Syndra_V2_Preview"
SG.ResetOnSpawn  = false
SG.DisplayOrder  = 9999
SG.IgnoreGuiInset = true
SG.ZIndexBehavior = Enum.ZIndexBehavior.Global
SG.Parent        = SafeGuiParent


local LoginFrame = Instance.new("Frame", SG)
local MainFrame = Instance.new("Frame", SG)

MainFrame.Size             = UDim2.new(0, 580, 0, 360)
MainFrame.AnchorPoint      = Vector2.new(0.5, 0.5)
MainFrame.Position         = UDim2.new(0.5, 0, 0.5, -25)
MainFrame.BackgroundColor3 = C.BG_DARK
MainFrame.BorderSizePixel  = 0
MainFrame.Active           = true
MainFrame.Draggable        = true
MainFrame.ClipsDescendants = false
MainFrame.Visible          = false -- DISEMBUNYIKAN KARENA BELUM LOGIN
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

-- =====================================================================
-- PRELOAD GAMBAR (blocking — dijalankan duluan sebelum apapun ditampilkan,
-- termasuk sebelum layar login muncul)
-- =====================================================================
local DaftarGambar = {
    "rbxthumb://type=Asset&id=122082009364146&w=150&h=150",
    "rbxthumb://type=Asset&id=130969527465346&w=150&h=150",
    "rbxthumb://type=Asset&id=105234598969049&w=150&h=150",
    "rbxthumb://type=Asset&id=104010825913281&w=150&h=150",
    "rbxthumb://type=Asset&id=71219341119919&w=150&h=150",
    "rbxthumb://type=Asset&id=98861278425029&w=150&h=150",
    "rbxthumb://type=Asset&id=78012648056733&w=150&h=150",
    "rbxthumb://type=Asset&id=71744475953983&w=150&h=150",
    "rbxthumb://type=Asset&id=124929807761049&w=150&h=150",
    "rbxthumb://type=Asset&id=121289652987098&w=150&h=150",
    "rbxthumb://type=Asset&id=80809761456188&w=150&h=150",
    "rbxthumb://type=Asset&id=93988459742193&w=150&h=150",
    "rbxthumb://type=Asset&id=105690080401988&w=150&h=150",
    "rbxthumb://type=Asset&id=114591683170998&w=150&h=150",
}
pcall(function() ContentProvider:PreloadAsync(DaftarGambar) end)

-- =====================================================================
-- SISTEM NOTIFIKASI
-- =====================================================================
local NotifContainer = Instance.new("Frame", SG)
NotifContainer.Name = "NotifContainer"
NotifContainer.Size = UDim2.new(0, 260, 1, -40)
NotifContainer.Position = UDim2.new(1, -20, 0, 20) 
NotifContainer.AnchorPoint = Vector2.new(1, 0)
NotifContainer.BackgroundTransparency = 1
NotifContainer.ZIndex = 2000


local NotifLayout = Instance.new("UIListLayout", NotifContainer)
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
NotifLayout.Padding = UDim.new(0, 10)

local function SendNotification(teks, durasi)
    pcall(function()
        -- Wrapper luar agar animasi tidak bentrok dengan susunan UIListLayout
        local Wrapper = Instance.new("Frame", NotifContainer)
        Wrapper.Size = UDim2.new(1, 0, 0, 72)
        Wrapper.BackgroundTransparency = 1

        -- Box notifikasi sebenarnya yang akan di-animasikan
        local NBox = Instance.new("Frame", Wrapper)
        NBox.Size = UDim2.new(1, 0, 1, 0)
        NBox.Position = UDim2.new(0, 150, 0, 0) -- Posisi awal bergeser ke kanan (luar)
        NBox.BackgroundColor3 = C.BG_DARKER
        NBox.BorderSizePixel = 0
        NBox.BackgroundTransparency = 1
        NBox.ZIndex = 2000
        Instance.new("UICorner", NBox).CornerRadius = UDim.new(0, 6)

        local LogoBg = Instance.new("Frame", NBox)
        LogoBg.Size = UDim2.new(0, 44, 0, 44)
        LogoBg.Position = UDim2.new(0, 8, 0.5, -22)
        LogoBg.BackgroundColor3 = C.ACCENT
        LogoBg.BorderSizePixel = 0
        LogoBg.BackgroundTransparency = 1
        LogoBg.ZIndex = 2001
        Instance.new("UICorner", LogoBg).CornerRadius = UDim.new(0, 4)

        local LogoImg = Instance.new("ImageLabel", LogoBg)
        LogoImg.Size = UDim2.new(1, -4, 1, -4)
        LogoImg.Position = UDim2.new(0.5, 0, 0.5, 0)
        LogoImg.AnchorPoint = Vector2.new(0.5, 0.5)
        LogoImg.BackgroundTransparency = 1
        LogoImg.Image = "rbxthumb://type=Asset&id=122082009364146&w=150&h=150"
        LogoImg.ImageTransparency = 1
        LogoImg.ZIndex = 2002

        local NTitle = Instance.new("TextLabel", NBox)
        NTitle.Size = UDim2.new(1, -64, 0, 20)
        NTitle.Position = UDim2.new(0, 60, 0, 8)
        NTitle.BackgroundTransparency = 1
        NTitle.Text = "Syndra Notification"
        NTitle.TextColor3 = C.WHITE
        NTitle.Font = Enum.Font.GothamBold
        NTitle.TextSize = 14
        NTitle.TextXAlignment = Enum.TextXAlignment.Left
        NTitle.TextTransparency = 1
        NTitle.ZIndex = 2001

        local NDesc = Instance.new("TextLabel", NBox)
        NDesc.Size = UDim2.new(1, -72, 0, 36)
        NDesc.Position = UDim2.new(0, 60, 0, 28)
        NDesc.BackgroundTransparency = 1
        NDesc.Text = tostring(teks)
        NDesc.TextColor3 = C.WHITE
        NDesc.Font = Enum.Font.Gotham
        NDesc.TextSize = 13
        NDesc.TextXAlignment = Enum.TextXAlignment.Left
        NDesc.TextYAlignment = Enum.TextYAlignment.Top
        NDesc.TextWrapped = true
        NDesc.TextTransparency = 1
        NDesc.ZIndex = 2001

        -- ANIMASI MASUK: Slide ke kiri (Position menjadi 0) & Muncul perlahan
        local tInfoIn = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(NBox, tInfoIn, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0}):Play()
        TweenService:Create(LogoBg, tInfoIn, {BackgroundTransparency = 0}):Play()
        TweenService:Create(LogoImg, tInfoIn, {ImageTransparency = 0}):Play()
        TweenService:Create(NTitle, tInfoIn, {TextTransparency = 0}):Play()
        TweenService:Create(NDesc, tInfoIn, {TextTransparency = 0}):Play()

        -- ANIMASI KELUAR: Slide ke kanan (Position kembali menjauh) & Hilang
        task.delay(durasi or 4, function()
            pcall(function()
                if Wrapper and Wrapper.Parent then
                    local tInfoOut = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    TweenService:Create(NBox, tInfoOut, {Position = UDim2.new(0, 150, 0, 0), BackgroundTransparency = 1}):Play()
                    TweenService:Create(LogoBg, tInfoOut, {BackgroundTransparency = 1}):Play()
                    TweenService:Create(LogoImg, tInfoOut, {ImageTransparency = 1}):Play()
                    TweenService:Create(NTitle, tInfoOut, {TextTransparency = 1}):Play()
                    TweenService:Create(NDesc, tInfoOut, {TextTransparency = 1}):Play()
                    task.wait(0.4)
                    Wrapper:Destroy()
                end
            end)
        end)
    end)
end

-- Notifikasi yang harus DITUNDA sampai user beneran masuk menu utama
-- (dipakai buat notif KBBI, yang loading-nya jalan di background dan bisa
-- kelar duluan sebelum user selesai login)
local hasEnteredMenu = false
local function NotifyAfterMenu(teks, durasi)
    if not hasEnteredMenu then
        repeat task.wait(0.2) until hasEnteredMenu
    end
    SendNotification(teks, durasi)
end

-- =====================================================================
-- LOGIN UI (Diperkecil + Avatar Asli + Animasi Gemetar)
-- =====================================================================
LoginFrame.Size             = UDim2.new(0, 300, 0, 380) 
LoginFrame.AnchorPoint      = Vector2.new(0.5, 0.5)
LoginFrame.Position         = UDim2.new(0.5, 0, 0.5, -10) 
LoginFrame.BackgroundColor3 = C.LOGIN_BG
LoginFrame.BorderSizePixel  = 0
LoginFrame.Active           = true
LoginFrame.Draggable        = false
LoginFrame.Visible          = false
Instance.new("UICorner", LoginFrame).CornerRadius = UDim.new(0, 12)

local LCloseBtn = Instance.new("ImageButton", LoginFrame)
LCloseBtn.Size                 = UDim2.new(0, 22, 0, 22)
LCloseBtn.Position             = UDim2.new(1, -15, 0, 14)
LCloseBtn.AnchorPoint          = Vector2.new(1, 0)
LCloseBtn.BackgroundTransparency = 1
LCloseBtn.Image                = "rbxthumb://type=Asset&id=93988459742193&w=150&h=150"

local LMinBtn = Instance.new("ImageButton", LoginFrame)
LMinBtn.Size                 = UDim2.new(0, 22, 0, 22)
LMinBtn.Position             = UDim2.new(1, -45, 0, 14)
LMinBtn.AnchorPoint          = Vector2.new(1, 0)
LMinBtn.BackgroundTransparency = 1
LMinBtn.Image                = "rbxthumb://type=Asset&id=105690080401988&w=150&h=150"

local LoginAvatarBg = Instance.new("Frame", LoginFrame)
LoginAvatarBg.Size             = UDim2.new(0, 80, 0, 80)
LoginAvatarBg.Position         = UDim2.new(0.5, 0, 0, 45)
LoginAvatarBg.AnchorPoint      = Vector2.new(0.5, 0)
LoginAvatarBg.BackgroundColor3 = C.WHITE
Instance.new("UICorner", LoginAvatarBg).CornerRadius = UDim.new(1, 0)

local LoginAvatar = Instance.new("ImageLabel", LoginAvatarBg)
LoginAvatar.Size                 = UDim2.new(1, -4, 1, -4)
LoginAvatar.Position             = UDim2.new(0.5, 0, 0.5, 0)
LoginAvatar.AnchorPoint          = Vector2.new(0.5, 0.5)
LoginAvatar.BackgroundTransparency = 1
LoginAvatar.Image                = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150"
Instance.new("UICorner", LoginAvatar).CornerRadius = UDim.new(1, 0)

local LoginTitle = Instance.new("TextLabel", LoginFrame)
LoginTitle.Size               = UDim2.new(1, 0, 0, 30)
LoginTitle.Position           = UDim2.new(0, 0, 0, 135)
LoginTitle.BackgroundTransparency = 1
LoginTitle.Text               = "Welcome"
LoginTitle.TextColor3         = C.WHITE
LoginTitle.Font               = Enum.Font.GothamBold
LoginTitle.TextSize           = 26

local LoginDesc = Instance.new("TextLabel", LoginFrame)
LoginDesc.Size               = UDim2.new(1, -40, 0, 30)
LoginDesc.Position           = UDim2.new(0, 20, 0, 170)
LoginDesc.BackgroundTransparency = 1
LoginDesc.Text               = "In the Roblox Syndra script, please enter your key below to start the script."
LoginDesc.TextColor3         = C.WHITE
LoginDesc.Font               = Enum.Font.Gotham
LoginDesc.TextSize           = 11
LoginDesc.TextWrapped        = true

local KeyInputBg = Instance.new("Frame", LoginFrame)
KeyInputBg.Size             = UDim2.new(1, -40, 0, 40)
KeyInputBg.Position         = UDim2.new(0, 20, 0, 215)
KeyInputBg.BackgroundColor3 = C.INPUT_BG
Instance.new("UICorner", KeyInputBg).CornerRadius = UDim.new(0, 6)

local KeyTextBox = Instance.new("TextBox", KeyInputBg)
KeyTextBox.Size               = UDim2.new(1, -20, 1, 0)
KeyTextBox.Position           = UDim2.new(0, 10, 0, 0)
KeyTextBox.BackgroundTransparency = 1
KeyTextBox.Text               = ""
KeyTextBox.PlaceholderText    = "key input"
KeyTextBox.PlaceholderColor3  = Color3.fromRGB(150, 150, 170)
KeyTextBox.TextColor3         = C.WHITE
KeyTextBox.Font               = Enum.Font.GothamMedium
KeyTextBox.TextSize           = 13
KeyTextBox.TextXAlignment     = Enum.TextXAlignment.Left
KeyTextBox.ClearTextOnFocus   = false

local EnterBtn = Instance.new("TextButton", LoginFrame)
EnterBtn.Size             = UDim2.new(0.5, -25, 0, 35)
EnterBtn.Position         = UDim2.new(0, 20, 0, 270)
EnterBtn.BackgroundColor3 = C.ACCENT
EnterBtn.Text             = "Enter"
EnterBtn.TextColor3       = C.WHITE
EnterBtn.Font             = Enum.Font.GothamBold
EnterBtn.TextSize         = 14
EnterBtn.AutoButtonColor  = false
Instance.new("UICorner", EnterBtn).CornerRadius = UDim.new(0, 8)

local GetKeyBtn = Instance.new("TextButton", LoginFrame)
GetKeyBtn.Size             = UDim2.new(0.5, -25, 0, 35)
GetKeyBtn.Position         = UDim2.new(0.5, 5, 0, 270)
GetKeyBtn.BackgroundColor3 = C.ACCENT
GetKeyBtn.Text             = "Get Key"
GetKeyBtn.TextColor3       = C.WHITE
GetKeyBtn.Font             = Enum.Font.GothamBold
GetKeyBtn.TextSize         = 14
GetKeyBtn.AutoButtonColor  = false
Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 8)

local Watermark = Instance.new("TextLabel", LoginFrame)
Watermark.Size               = UDim2.new(1, 0, 0, 20)
Watermark.Position           = UDim2.new(0, 0, 1, -25)
Watermark.BackgroundTransparency = 1
Watermark.Text               = "Syndra"
Watermark.TextColor3         = Color3.fromRGB(100, 100, 120)
Watermark.Font               = Enum.Font.GothamBold
Watermark.TextSize           = 11

LCloseBtn.MouseButton1Click:Connect(function() SG:Destroy() end)
LMinBtn.MouseButton1Click:Connect(function()
    LoginFrame.Visible = false
    local openBtn = SG:FindFirstChild("ImageButton") 
    if openBtn then openBtn.Visible = true end
end)

GetKeyBtn.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(GET_KEY_LINK)
    elseif toclipboard then toclipboard(GET_KEY_LINK) end
    local origText = GetKeyBtn.Text
    GetKeyBtn.Text = "Copied!"
    GetKeyBtn.BackgroundColor3 = C.GREEN
    task.delay(1.5, function()
        GetKeyBtn.Text = origText
        GetKeyBtn.BackgroundColor3 = C.ACCENT
    end)
    SendNotification("Link Discord dicopy ke clipboard!", 3)
end)

EnterBtn.MouseButton1Click:Connect(function()
    local inputKey = KeyTextBox.Text

    EnterBtn.Text   = "Memeriksa key..."
    EnterBtn.Active = false

    local isValid, reason = ValidateKeyOnServer(inputKey)

    if isValid then
        EnterBtn.Text = "Memuat modul..."

        local moduleUrl = GameModules[game.PlaceId]
        if not moduleUrl then
            SendNotification("Game ini belum didukung script", 4)
            EnterBtn.Text   = "Enter"
            EnterBtn.Active = true
            return
        end

        local fetchOk, moduleFnOrErr = pcall(function()
            local code = game:HttpGet(moduleUrl)
            return loadstring(code)
        end)

        if not fetchOk or not moduleFnOrErr then
            SendNotification("Gagal memuat modul game (cek koneksi)", 4)
            EnterBtn.Text   = "Enter"
            EnterBtn.Active = true
            return
        end

        -- Modul membangun kontennya sendiri ke dalam MainFrame di sini,
        -- SELAGI MainFrame masih tersembunyi -- baru di-reveal setelah beres
        local runOk, runErr = pcall(moduleFnOrErr, Core)
        if not runOk then
            SendNotification("Modul game error saat dijalankan", 5)
            EnterBtn.Text   = "Enter"
            EnterBtn.Active = true
            return
        end

        State.IsAuthenticated = true
        LoginFrame:Destroy()
        MainFrame.Visible = true
        hasEnteredMenu = true
        SendNotification("Welcome To Syndra", 4)
    else
        EnterBtn.Text   = "Enter"
        EnterBtn.Active = true

        task.spawn(function()
            local origPos = UDim2.new(0.5, 0, 0.5, -10)
            local tInfo = TweenInfo.new(0.04, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            local t1 = TweenService:Create(LoginFrame, tInfo, {Position = origPos + UDim2.new(0, 12, 0, 0)})
            local t2 = TweenService:Create(LoginFrame, tInfo, {Position = origPos - UDim2.new(0, 12, 0, 0)})
            local t3 = TweenService:Create(LoginFrame, tInfo, {Position = origPos})
            t1:Play(); t1.Completed:Wait()
            t2:Play(); t2.Completed:Wait()
            t1:Play(); t1.Completed:Wait()
            t2:Play(); t2.Completed:Wait()
            t3:Play()
        end)
        KeyTextBox.Text = ""
        KeyTextBox.PlaceholderText = (inputKey == "" and "Key belum diisi!") or reason or "Key Salah!"
        KeyTextBox.PlaceholderColor3 = C.RED
        task.delay(1.5, function()
            KeyTextBox.PlaceholderText = "key input"
            KeyTextBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 170)
        end)
    end
end)

-- =====================================================================
-- HEADER: LOGO, CLOSE, MINIMIZE
-- =====================================================================

local LogoSyndra = Instance.new("ImageLabel", MainFrame)
LogoSyndra.Size                 = UDim2.new(0, 36, 0, 36)
LogoSyndra.Position             = UDim2.new(0, 12, 0, 7)
LogoSyndra.BackgroundTransparency = 1
LogoSyndra.ZIndex               = 100
LogoSyndra.Image                = "rbxthumb://type=Asset&id=122082009364146&w=150&h=150"

local CloseBtn = Instance.new("ImageButton", MainFrame)
CloseBtn.Size                 = UDim2.new(0, 22, 0, 22)
CloseBtn.Position             = UDim2.new(1, -15, 0, 14)
CloseBtn.AnchorPoint          = Vector2.new(1, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Image                = "rbxthumb://type=Asset&id=93988459742193&w=150&h=150"
CloseBtn.ZIndex               = 100

local MinimizeBtn = Instance.new("ImageButton", MainFrame)
MinimizeBtn.Size                 = UDim2.new(0, 22, 0, 22)
MinimizeBtn.Position             = UDim2.new(1, -45, 0, 14)
MinimizeBtn.AnchorPoint          = Vector2.new(1, 0)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Image                = "rbxthumb://type=Asset&id=105690080401988&w=150&h=150"
MinimizeBtn.ZIndex               = 100

-- =====================================================================
-- FLOATING BUTTON (ICON SAAT MINIMIZE)
-- =====================================================================

local OpenMenuBtn = Instance.new("ImageButton", SG)
OpenMenuBtn.Size                 = UDim2.new(0, 45, 0, 45)
OpenMenuBtn.Position             = UDim2.new(0, 25, 0.5, -30) 
OpenMenuBtn.AnchorPoint          = Vector2.new(0, 0.5)
OpenMenuBtn.BackgroundTransparency = 1
OpenMenuBtn.Image                = "rbxthumb://type=Asset&id=114591683170998&w=150&h=150"
OpenMenuBtn.Visible              = false
OpenMenuBtn.Active               = true
OpenMenuBtn.Draggable            = true
Instance.new("UICorner", OpenMenuBtn).CornerRadius = UDim.new(0, 10)
-- =====================================================================
-- SIDEBAR NAVIGATION (IKON KIRI)
-- =====================================================================
local SidebarIconContainer = Instance.new("Frame", MainFrame)
SidebarIconContainer.Size             = UDim2.new(0, 60, 1, -110)
SidebarIconContainer.Position         = UDim2.new(0, 0, 0, 60)
SidebarIconContainer.BackgroundTransparency = 1

local SidebarLayout = Instance.new("UIListLayout", SidebarIconContainer)
SidebarLayout.SortOrder         = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding           = UDim.new(0, 12)
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local SidebarTabs = {}

local function CreateSidebarTab(iconActive, iconInactive, isActive, pageElements)
    local btn = Instance.new("TextButton", SidebarIconContainer)
    btn.Size             = UDim2.new(0, 38, 0, 38)
    btn.BackgroundColor3 = isActive and C.WHITE or C.ACCENT
    btn.Text             = ""
    btn.AutoButtonColor  = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local icon = Instance.new("ImageLabel", btn)
    icon.Size                 = UDim2.new(0, 24, 0, 24)
    icon.Position             = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint          = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxthumb://type=Asset&id=" .. (isActive and iconActive or iconInactive) .. "&w=150&h=150"

    SidebarTabs[btn] = {Icon = icon, Elements = pageElements, IdActive = iconActive, IdInactive = iconInactive}

    btn.MouseButton1Click:Connect(function()
        for tBtn, data in pairs(SidebarTabs) do
            tBtn.BackgroundColor3 = C.ACCENT
            if data.IdInactive then
                data.Icon.Image = "rbxthumb://type=Asset&id=" .. data.IdInactive .. "&w=150&h=150"
            end
            if data.Elements then
                for _, el in ipairs(data.Elements) do el.Visible = false end
            end
        end
        btn.BackgroundColor3 = C.WHITE
        icon.Image = "rbxthumb://type=Asset&id=" .. iconActive .. "&w=150&h=150"
        if pageElements then
            for _, el in ipairs(pageElements) do el.Visible = true end
        end
    end)

    return btn
end

-- =====================================================================
-- =====================================================================
-- LOGIKA CLOSE / MINIMIZE / OPEN
-- =====================================================================
local function UpdateProfileBtnPos() end -- placeholder jika diperlukan nanti

CloseBtn.MouseButton1Click:Connect(function()
    SG:Destroy()
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible    = false
    OpenMenuBtn.Visible  = true
end)

OpenMenuBtn.MouseButton1Click:Connect(function()
    OpenMenuBtn.Visible  = false
    if State.IsAuthenticated then
        MainFrame.Visible = true
    else
        LoginFrame.Visible = true
    end
end)

-- =====================================================================
-- CORE API -- semua yang boleh dipakai modul per-game (diakses via Core.X)
-- =====================================================================
Core = {
    -- Roblox services & referensi player
    Players         = Players,
    TweenService    = TweenService,
    ContentProvider = ContentProvider,
    LocalPlayer     = LocalPlayer,
    PlayerGui       = PlayerGui,

    -- GUI utama
    SG              = SG,
    MainFrame       = MainFrame,
    SidebarTabs     = SidebarTabs,

    -- Palet warna & animasi
    C               = C,
    TWEEN_INFO      = TWEEN_INFO,
    ApplyPressAnimation = ApplyPressAnimation,

    -- Pembuat komponen UI
    CreateToggle        = CreateToggle,
    CreateDropdown       = CreateDropdown,
    CreatePageContainer  = CreatePageContainer,
    CreateSidebarTab     = CreateSidebarTab,

    -- Notifikasi
    SendNotification = SendNotification,
    NotifyAfterMenu  = NotifyAfterMenu,

    -- Utilitas umum
    FormatRibuan = FormatRibuan,

    -- State bersama (modul menambahkan field miliknya sendiri ke tabel ini)
    State = State,
}

-- =====================================================================
-- DAFTAR MODUL PER-GAME
-- Tambahkan game baru cukup dengan menambah 1 baris di sini --
-- tidak perlu ubah apapun di script core ini.
-- =====================================================================
GameModules = {
    -- GANTI 0 dengan PlaceId game word-chain kamu (lihat game.PlaceId di output/console),
    -- dan ganti URL-nya kalau sudah upload wordchain.lua ke GitHub/CDN kamu sendiri.
    [130342654546662] = "https://raw.githubusercontent.com/ryxx17/Cihuyy/refs/heads/main/wordchain_module.lua",
}

LoginFrame.Visible = true
