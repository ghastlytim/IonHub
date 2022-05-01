-- Services
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Framework
local Framework = {}; Framework.__index = Framework; do
    function Framework:Round_V2(V2)
        return Vector2.new(math.floor(V2.X + 0.5), math.floor(V2.Y + 0.5))
    end
    function Framework:V3_To_V2(V3)
        return Vector2.new(V3.X, V3.Y)
    end
    function Framework:Draw(Object, Properties)
        Object = Drawing.new(Object)
        for Property, Value in pairs(Properties) do
            Object[Property] = Value
        end
        return Object
    end
    function Framework:Get_Bounding_Vectors(Part)
        local Part_CFrame, Part_Size = Part.CFrame, Part.Size 
        local X, Y, Z = Part_Size.X, Part_Size.Y, Part_Size.Z
        return {
            TBRC = Part_CFrame * CFrame.new(X, Y * 1.3, Z),
            TBLC = Part_CFrame * CFrame.new(-X, Y * 1.3, Z),
            TFRC = Part_CFrame * CFrame.new(X, Y * 1.3, -Z),
            TFLC = Part_CFrame * CFrame.new(-X, Y * 1.3, -Z),
            BBRC = Part_CFrame * CFrame.new(X, -Y * 1.6, Z),
            BBLC = Part_CFrame * CFrame.new(-X, -Y * 1.6, Z),
            BFRC = Part_CFrame * CFrame.new(X, -Y * 1.6, -Z),
            BFLC = Part_CFrame * CFrame.new(-X, -Y * 1.6, -Z),
        };
    end
end

-- Main
local ESP = {
    Settings = {
        Enabled = false,
        Maximal_Distance = 1000,
        Highlight = {Enabled = false, Color = Color3.new(1, 0, 0)},
        Box = {Enabled = false, Color = Color3.new(1, 1, 1)},
        Box_Outline = {Enabled = false, Color = Color3.new(0, 0, 0), Outline_Size = 1},
        Healthbar = {Enabled = false, Position = "Left", Color = Color3.new(1, 1, 1), Color_Lerp = Color3.fromRGB(40, 252, 3)},
        Name = {Enabled = false, Position = "Top", Color = Color3.new(1, 1, 1), OutlineColor = Color3.new(0, 0, 0)},
        Distance = {Enabled = false, Position = "Bottom", Color = Color3.new(1, 1, 1), OutlineColor = Color3.new(0, 0, 0)},
        Tool = {Enabled = false, Position = "Right", Color = Color3.new(1, 1, 1), OutlineColor = Color3.new(0, 0, 0)}
    },
    Objects = {},
    Overrides = {}
}

function ESP:GetObject(Object)
    return self.Objects[Object]
end

function ESP:Toggle(State)
    self.Settings.Enabled = State
end

local Get_Character = function(Player)
    if ESP.Overrides.Get_Character ~= nil then
        return ESP.Overrides.Get_Character(Player)
    end
    return Player.Character
end

local Get_Tool = function(Player)
    if ESP.Overrides.Get_Tool ~= nil then
        return ESP.Overrides.Get_Tool(Player)
    end
    local Character = Get_Character(Player)
    if Character then
        local Tool = Character:FindFirstChildOfClass("Tool")
        if Tool then
            return Tool.Name
        end
    end
    return "Hands"
end

local Player_Metatable = {}
do -- Player Metatable
    Player_Metatable.__index = Player_Metatable
    function Player_Metatable:Destroy()
        ESP.Objects[self.Object] = nil
        for Index, Drawing in pairs(self.Components) do
            Drawing.Visible = false
            Drawing:Remove()
            self.Components[Index] = nil
        end
    end
    function Player_Metatable:Update()
        local Box, Box_Outline = self.Components.Box, self.Components.Box_Outline
        local Healthbar, Healthbar_Outline = self.Components.Healthbar, self.Components.Healthbar_Outline
        local Name = self.Components.Name
        local Distance = self.Components.Distance
        local Tool = self.Components.Tool
        local Health = self.Components.Health
        local Character = Get_Character(self.Player)
        if Character then
            local Head, HumanoidRootPart, Humanoid = Character:FindFirstChild("Head"), Character:FindFirstChild("HumanoidRootPart"), Character:FindFirstChildOfClass("Humanoid")
            if not Humanoid then
                self:Destroy()
                return
            end
            local Health, Health_Maximum = Humanoid.Health, Humanoid.MaxHealth
            if Head and HumanoidRootPart and Health > 0 then
                local Dimensions = Framework:Get_Bounding_Vectors(HumanoidRootPart)
                local HRP_Position, On_Screen = Camera:WorldToViewportPoint(HumanoidRootPart.Position)
                local Stud_Distance, Meter_Distance = math.floor(HRP_Position.Z + 0.5), math.floor(HRP_Position.Z / 3.5714285714 + 0.5)

                local Y_Minimal, Y_Maximal = Camera.ViewportSize.X, 0
                local X_Minimal, X_Maximal = Camera.ViewportSize.X, 0

                for _, CF in pairs(Dimensions) do
                    local Vector = Camera:WorldToViewportPoint(CF.Position)
                    local X, Y = Vector.X, Vector.Y
                    if X < X_Minimal then 
                        X_Minimal = X
                    end
                    if X > X_Maximal then 
                        X_Maximal = X
                    end
                    if Y < Y_Minimal then 
                        Y_Minimal = Y
                    end
                    if Y > Y_Maximal then
                        Y_Maximal = Y
                    end
                end

                local Box_Size = Framework:Round_V2(Vector2.new(X_Minimal - X_Maximal, Y_Minimal - Y_Maximal))
                local Box_Position = Framework:Round_V2(Vector2.new(X_Maximal + Box_Size.X / X_Minimal, Y_Maximal + Box_Size.Y / Y_Minimal))

                if ESP.Settings.Enabled and On_Screen and Meter_Distance < ESP.Settings.Maximal_Distance then
                    -- Offsets
                    local Top_Offset = 3
                    local Bottom_Offset = Y_Maximal + 1
                    local Left_Offset = 0
                    local Right_Offset = 0

                    -- Box
                    Box.Size = Box_Size
                    Box.Position = Box_Position
                    Box.Color = ESP.Settings.Box.Color
                    Box.Visible = ESP.Settings.Box.Enabled

                    Box_Outline.Size = Box_Size
                    Box_Outline.Position = Box_Position
                    Box_Outline.Color = ESP.Settings.Box_Outline.Color
                    Box_Outline.Visible = ESP.Settings.Box_Outline.Enabled
                    Box_Outline.Thickness = ESP.Settings.Box_Outline.Outline_Size + 2

                    -- Healthbar
                    local Health_Top_Size_Outline = Vector2.new(Box_Size.X - 4, 3)
                    local Health_Top_Pos_Outline = Box_Position + Vector2.new(2, Box_Size.Y - 6)
                    local Health_Top_Size_Fill = Vector2.new((Health * Health_Top_Size_Outline.X / Health_Maximum) + 2, 1)
                    local Health_Top_Pos_Fill = Health_Top_Pos_Outline + Vector2.new(1 + -(Health_Top_Size_Fill.X - Health_Top_Size_Outline.X),1);

                    local Health_Left_Size_Outline = Vector2.new(3, Box_Size.Y - 4)
                    local Health_Left_Pos_Outline = Vector2.new(X_Maximal + Box_Size.X - 6, Box_Position.Y + 2)
                    local Health_Left_Size_Fill = Vector2.new(1, (Health * Health_Left_Size_Outline.Y / Health_Maximum) + 2)
                    local Health_Left_Pos_Fill = Health_Left_Pos_Outline + Vector2.new(1,-1 + -(Health_Left_Size_Fill.Y - Health_Left_Size_Fill.Y));

                    local Healthbar_Enabled = ESP.Settings.Healthbar.Enabled
                    local Healthbar_Position = ESP.Settings.Healthbar.Position
                    if Healthbar_Enabled then
                        if Healthbar_Position == "Left" then
                            Healthbar.Size = Health_Left_Size_Fill;
                            Healthbar.Position = Health_Left_Pos_Fill;
                            Healthbar_Outline.Size = Health_Left_Size_Outline;
                            Healthbar_Outline.Position = Health_Left_Pos_Outline;
                        elseif Healthbar_Position == "Right" then
                            Healthbar.Size = Health_Left_Size_Fill;
                            Healthbar.Position = Vector2.new(X_Maximal + Box_Size.X + 4, Box_Position.Y + 1) - Vector2.new(Box_Size.X, 0)
                            Healthbar_Outline.Size = Health_Left_Size_Outline
                            Healthbar_Outline.Position = Vector2.new(X_Maximal + Box_Size.X + 3, Box_Position.Y + 2) - Vector2.new(Box_Size.X, 0)
                        elseif Healthbar_Position == "Top" then
                            Healthbar.Size = Health_Top_Size_Fill;
                            Healthbar.Position = Health_Top_Pos_Fill;
                            Healthbar_Outline.Size = Health_Top_Size_Outline;
                            Healthbar_Outline.Position = Health_Top_Pos_Outline;
                            Top_Offset = Top_Offset + 6
                        elseif Healthbar_Position == "Bottom" then
                            Healthbar.Size = Health_Top_Size_Fill
                            Healthbar.Position = Health_Top_Pos_Fill - Vector2.new(0, Box_Size.Y - 9)
                            Healthbar_Outline.Size = Health_Top_Size_Outline;
                            Healthbar_Outline.Position = Health_Top_Pos_Outline - Vector2.new(0, Box_Size.Y - 9)
                            Bottom_Offset = Bottom_Offset + 6
                        end
                        Healthbar.Color = ESP.Settings.Healthbar.Color:Lerp(ESP.Settings.Healthbar.Color_Lerp, Health / Health_Maximum)
                    end
                    Healthbar.Visible = Healthbar_Enabled
                    Healthbar_Outline.Visible = Healthbar_Enabled

                    -- Name
                    local Name_Position = ESP.Settings.Name.Position
                    if Name_Position == "Top" then 
                        Name.Position = Vector2.new(X_Maximal + Box_Size.X / 2, Box_Position.Y) - Vector2.new(0, Name.TextBounds.Y - Box_Size.Y + Top_Offset) 
                        Top_Offset = Top_Offset + 10
                    elseif Name_Position == "Bottom" then
                        Name.Position = Vector2.new(Box_Size.X / 2 + Box_Position.X, Bottom_Offset) 
                        Bottom_Offset = Bottom_Offset + 10
                    elseif Name_Position == "Left" then
                        if Healthbar_Position == "Left" then
                            Name.Position = Health_Left_Pos_Outline - Vector2.new(Name.TextBounds.X/2 - 2 + 4, -(100 * Health_Left_Size_Outline.Y / 100) + 2 - Left_Offset)
                        else
                            Name.Position = Health_Left_Pos_Outline - Vector2.new(Name.TextBounds.X/2 - 2, -(100 * Health_Left_Size_Outline.Y / 100) + 2 - Left_Offset)
                        end
                        Left_Offset = Left_Offset + 10
                    elseif Name_Position == "Right" then
                        if Healthbar_Position == "Right" then
                            Name.Position = Vector2.new(X_Maximal + Box_Size.X + 4 + 4 + Name.TextBounds.X / 2, Box_Position.Y + 2) - Vector2.new(Box_Size.X, -(100 * Health_Left_Size_Outline.Y / 100) + 2 - Right_Offset)
                        else
                            Name.Position = Vector2.new(X_Maximal + Box_Size.X + 3 + Name.TextBounds.X / 2, Box_Position.Y + 2) - Vector2.new(Box_Size.X, -(100 * Health_Left_Size_Outline.Y / 100) + 2 - Right_Offset)
                        end
                        Right_Offset = Right_Offset + 10
                    end
                    Name.Color = ESP.Settings.Name.Color
                    Name.OutlineColor = ESP.Settings.Name.OutlineColor
                    Name.Visible = ESP.Settings.Name.Enabled

                    -- Distance
                    local Distance_Position = ESP.Settings.Distance.Position
                    if Distance_Position == "Top" then 
                        Distance.Position = Vector2.new(X_Maximal + Box_Size.X / 2, Box_Position.Y) - Vector2.new(0, Distance.TextBounds.Y - Box_Size.Y + Top_Offset) 
                        Top_Offset = Top_Offset + 10
                    elseif Distance_Position == "Bottom" then
                        Distance.Position = Vector2.new(Box_Size.X / 2 + Box_Position.X, Bottom_Offset) 
                        Bottom_Offset = Bottom_Offset + 10
                    elseif Distance_Position == "Left" then
                        if Healthbar_Position == "Left" then
                            Distance.Position = Health_Left_Pos_Outline - Vector2.new(Distance.TextBounds.X/2 - 2 + 4, -(100 * Health_Left_Size_Outline.Y / 100) + 2 - Left_Offset)
                        else
                            Distance.Position = Health_Left_Pos_Outline - Vector2.new(Distance.TextBounds.X/2 - 2, -(100 * Health_Left_Size_Outline.Y / 100) + 2 - Left_Offset)
                        end
                        Left_Offset = Left_Offset + 10
                    elseif Distance_Position == "Right" then
                        if Healthbar_Position == "Right" then
                            Distance.Position = Vector2.new(X_Maximal + Box_Size.X + 4 + 4 + Distance.TextBounds.X / 2, Box_Position.Y + 2) - Vector2.new(Box_Size.X, -(100 * Health_Left_Size_Outline.Y / 100) + 2 - Right_Offset)
                        else
                            Distance.Position = Vector2.new(X_Maximal + Box_Size.X + 3 + Distance.TextBounds.X / 2, Box_Position.Y + 2) - Vector2.new(Box_Size.X, -(100 * Health_Left_Size_Outline.Y / 100) + 2 - Right_Offset)
                        end
                        Right_Offset = Right_Offset + 10
                    end
                    Distance.Text = Meter_Distance.."m"
                    Distance.Color = ESP.Settings.Distance.Color
                    Distance.OutlineColor = ESP.Settings.Distance.OutlineColor
                    Distance.Visible = ESP.Settings.Distance.Enabled

                    -- Tool
                    local Tool_Position = ESP.Settings.Tool.Position
                    if Tool_Position == "Top" then 
                        Tool.Position = Vector2.new(X_Maximal + Box_Size.X / 2, Box_Position.Y) - Vector2.new(0, Tool.TextBounds.Y - Box_Size.Y + Top_Offset) 
                        Top_Offset = Top_Offset + 10
                    elseif Tool_Position == "Bottom" then
                        Tool.Position = Vector2.new(Box_Size.X / 2 + Box_Position.X, Bottom_Offset) 
                        Bottom_Offset = Bottom_Offset + 10
                    elseif Tool_Position == "Left" then
                        if Healthbar_Position == "Left" then
                            Tool.Position = Health_Left_Pos_Outline - Vector2.new(Tool.TextBounds.X/2 - 2 + 4, -(100 * Health_Left_Size_Outline.Y / 100) + 2 - Left_Offset)
                        else
                            Tool.Position = Health_Left_Pos_Outline - Vector2.new(Tool.TextBounds.X/2 - 2, -(100 * Health_Left_Size_Outline.Y / 100) + 2 - Left_Offset)
                        end
                        Left_Offset = Left_Offset + 10
                    elseif Tool_Position == "Right" then
                        if Healthbar_Position == "Right" then
                            Tool.Position = Vector2.new(X_Maximal + Box_Size.X + 4 + 4 + Tool.TextBounds.X / 2, Box_Position.Y + 2) - Vector2.new(Box_Size.X, -(100 * Health_Left_Size_Outline.Y / 100) + 2 - Right_Offset)
                        else
                            Tool.Position = Vector2.new(X_Maximal + Box_Size.X + 3 + Tool.TextBounds.X / 2, Box_Position.Y + 2) - Vector2.new(Box_Size.X, -(100 * Health_Left_Size_Outline.Y / 100) + 2 - Right_Offset)
                        end
                        Right_Offset = Right_Offset + 10
                    end
                    Tool.Text = Get_Tool(self.Player)
                    Tool.Color = ESP.Settings.Tool.Color
                    Tool.OutlineColor = ESP.Settings.Tool.OutlineColor
                    Tool.Visible = ESP.Settings.Tool.Enabled
                else
                    for Index, Drawing in pairs(self.Components) do
                        Drawing.Visible = false
                    end
                    return
                end
            else
                self:Destroy()
                return
            end
        else
            self:Destroy()
            return
        end
    end
end
do -- ESP Functions
    function ESP:Player(Instance, Data)
        local Object = setmetatable({
            Object = Data.Object,
            Player = Data.Player,
            Components = {},
            Type = "Player"
        }, Player_Metatable)
        if self:GetObject(Instance) then
            self:GetObject(Instance):Destroy()
        end
        local Components = Object.Components
        Components.Box = Framework:Draw("Square", {Thickness = 1, ZIndex = 2})
        Components.Box_Outline = Framework:Draw("Square", {Thickness = 3, ZIndex = 1})
        Components.Healthbar = Framework:Draw("Square", {Thickness = 1, ZIndex = 2, Filled = true})
        Components.Healthbar_Outline = Framework:Draw("Square", {Thickness = 3, ZIndex = 1, Filled = true})
        Components.Name = Framework:Draw("Text", {Text = Instance.Name, Font = 2, Size = 13, Outline = true, Center = true})
        Components.Distance = Framework:Draw("Text", {Font = 2, Size = 13, Outline = true, Center = true})
        Components.Tool = Framework:Draw("Text", {Font = 2, Size = 13, Outline = true, Center = true})
        self.Objects[Instance] = Object
        return Object
    end
    function ESP:Object(Data)
        
    end
end

local Connection = RunService.RenderStepped:Connect(function()
    for i, Object in pairs(ESP.Objects) do
        Object:Update()
    end
end)

return ESP, Connection
