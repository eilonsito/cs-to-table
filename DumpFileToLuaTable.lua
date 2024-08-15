local IsPc = not gg

-- File Handling --
local FilePath

if not IsPc then
    FilePath = gg.prompt(
        { "◄\tScript By Elon Musk\t►\nSelect Dump.cs File" },
        { gg.EXT_STORAGE .. "/Download/" },
        { "file" }
    )

    if FilePath and FilePath[1] ~= gg.EXT_STORAGE .. "/Download/" then
        File = assert(io.open(FilePath[1], "r"))
    end
else
    -- If on PC, default is dump.cs --
    File = assert(io.open("dump.cs", "r"))
end

local FileContent = File:read("*a")


-- Function to Parse and clean the file --
local function Dumper(Content)
    local TrashPatterns = {}

    -- Get unwanted patterns --
    for Match in Content:gmatch("Image %d+: (%a+)") do
        table.insert(TrashPatterns, Match)
    end

    -- Check if the string is trash --
    local function IsTrash(Value)
        for _, Pattern in ipairs(TrashPatterns) do
            if Value:find(Pattern) then
                return true
            end
        end
        return false
    end

    -- Clean up the table --
    local function CleanTable(Tab)
        for Key, Value in pairs(Tab) do
            if type(Value) == "table" then
                CleanTable(Value)
                if next(Value) == nil then
                    Tab[Key] = nil
                end
            elseif not Value or Value == "" then
                Tab[Key] = nil
            end
        end
    end

    -- Remove empty entries --
    local function OptimizeTable(Tab)
        for Key, Value in pairs(Tab) do
            if type(Value) == "table" then
                OptimizeTable(Value)
                if next(Value) == nil then
                    Tab[Key] = nil
                end
            elseif not Value or Value == "" then
                Tab[Key] = nil
            end
        end
        return Tab
    end

    -- Main table to store the parsed data --
    local DumperTable = {}

    -- Update with new data --
    function DumperTable:Update(Name, Class, FieldMethod, Data)
        self[Name] = self[Name] or {}
        self[Name][Class] = self[Name][Class] or {}
        if Data then
            self[Name][Class][FieldMethod] = self[Name][Class][FieldMethod] or {}
            table.insert(self[Name][Class][FieldMethod], Data)
            CleanTable(DumperTable)
        end
    end

    -- Parse to extract fields and methods --
    for Namespace, Classname, Body in Content:gmatch("Namespace: (%g+)\n%.*public class (%a+) .-// TypeDefIndex:.-\n{(.-)\n}") do
        Namespace = Namespace or "System"

        if not IsTrash(Namespace) then
            Namespace = Namespace:gsub("%.", "")

            -- Skip any body with public const string patterns --
            if Body:find("public const string %a+ =%g+") then
                Body = ""
            end

            -- Extract and store fields --
            for FieldBody in Body:gmatch("// Fields\n(.-)%// [%bMethods*%bProperties*]+.\n") do
                for FieldType, Mode, FieldName, FieldOffset in FieldBody:gmatch(".-([public+*private+*protected+*internal+]+%s*[*override+*static+*readonly+*]*) (%a+) (%g+); // (0x%x+)") do
                    if FieldOffset ~= "0x0" and (Mode == "int" or Mode == "bool" or Mode == "double" or Mode == "float") then
                        local FieldData = {
                            Name = FieldName,
                            Type = Mode,
                            Offset = FieldOffset,
                            Info = FieldType
                        }
                        DumperTable:Update(Namespace, Classname, "Fields", FieldData)
                        
                        if not IsPc then
                            gg.toast("Please wait...", true)
                        else
                            print(FieldType, Mode, FieldName, FieldOffset)
                        end
                    end
                end
            end

            -- Extract and store methods --
            for MethodBody in Body:gmatch("// Methods(.+)") do
                for Offset, Info, DataType, MethodName in MethodBody:gmatch("RVA:.-Offset: (0x%x+).-([public+*private+*protected+*internal+]+%s*[*override+*static+*readonly+*]*) (%.*%a+) (.-) { %}\n") do
                    if DataType == "int" or DataType == "bool" or DataType == "double" or DataType == "float" then
                        local MethodData = {
                            Name = MethodName:gsub("%(.-%)", ""),
                            Type = DataType,
                            Offset = Offset,
                            Info = Info
                        }
                        DumperTable:Update(Namespace, Classname, "Methods", MethodData)

                        if IsPc then
                            print(DataType, MethodName)
                        end
                    end
                end
            end
        end
    end

    CleanTable(DumperTable)
    return DumperTable
end

local DumperTable = Dumper(FileContent)
DumperTable = OptimizeTable(DumperTable)

-- Converts table to strings --
local function DumpTableToString(ResTab)
    local Output, Stack, Cache = {}, {}, {}
    local Depth = 1
    local OutputStr = "{\n"
    
    while true do
        local Size = 0
        for _ in pairs(ResTab) do
            Size = Size + 1
        end
        
        local CurIndex = 1
        for Key, Value in pairs(ResTab) do
            if not Cache[ResTab] or CurIndex >= Cache[ResTab] then
                if OutputStr:find("}", OutputStr:len()) then
                    OutputStr = OutputStr .. ",\n"
                elseif not OutputStr:find("\n", OutputStr:len()) then
                    OutputStr = OutputStr .. "\n"
                end
                table.insert(Output, OutputStr)
                OutputStr = ""

                local KeyStr = (type(Key) == "number" or type(Key) == "boolean") and "[" .. tostring(Key) .. "]" or "['" .. tostring(Key) .. "']"

                if type(Value) == "number" or type(Value) == "boolean" then
                    OutputStr = OutputStr .. string.rep("\t", Depth) .. KeyStr .. " = " .. tostring(Value)
                elseif type(Value) == "table" then
                    OutputStr = OutputStr .. string.rep("\t", Depth) .. KeyStr .. " = {\n"
                    table.insert(Stack, ResTab)
                    table.insert(Stack, Value)
                    Cache[ResTab] = CurIndex + 1
                    break
                else
                    OutputStr = OutputStr .. string.rep("\t", Depth) .. KeyStr .. " = '" .. tostring(Value) .. "'"
                end

                if CurIndex == Size then
                    OutputStr = OutputStr .. "\n" .. string.rep("\t", Depth - 1) .. "}"
                else
                    OutputStr = OutputStr .. ","
                end
            else
                if CurIndex == Size then
                    OutputStr = OutputStr .. "\n" .. string.rep("\t", Depth - 1) .. "}"
                end
            end

            CurIndex = CurIndex + 1
        end

        if Size == 0 then
            OutputStr = OutputStr .. "\n" .. string.rep("\t", Depth - 1) .. "}"
        end

        if #Stack > 0 then
            ResTab = Stack[#Stack]
            Stack[#Stack] = nil
            Depth = Cache[ResTab] and Depth - 1 or Depth + 1
        else
            break
        end
    end

    table.insert(Output, OutputStr)
    return table.concat(Output)
end

-- Output to a file --
local Res = io.output("DumpTable.lua")
Res:write(
    "\n--[[\nNamespace  ->>\n Classname  ->>\n  (•)Fields \n\t ► Info \n\t ►  Name \n\t ►  Offset\n  (•)Methods \n\t ► Info \n\t ►  Name \n\t ►  Type \n\t ►  Offset\n]]\n\n" ..
    "DumpedTable = " .. DumpTableToString(DumperTable)
)
Res:close()
File:close()

if not IsPc then
    gg.alert("◄\tSuccess\t►\n\n\n File Name: DumpTable.lua\n\n Dir same as the script path!")
else
    print("\n\n\n\n\n\n\tSuccess\t\n\n\n\n\n\n File Name: DumpTable.lua\n\n Dir same as the script path!")
end
