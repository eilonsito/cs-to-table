PC = false

if not gg then
    PC = true
else
    PC = false
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
if not PC then
    File = gg.prompt(
        {
            "◄\tScript By Elon Musk\t►\nSelect Dump.cs File"
        },
        {gg.EXT_STORAGE .. "/Download/"},
        {"file"}
    )
    if File ~= nil and File ~= gg.EXT_STORAGE .. "/Download/" then
        File = assert(io.open(File[1], "r"))
    end
else
    File = assert(io.open("dump.cs", "r"))
end

local str = File:read("*a")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Dumper(str)
    local trash = {}

    for _ in str:gmatch("Image %d+: (%a+)") do
        trash[#trash + 1] = _
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function TrashClean(any)
        for _, __ in pairs(trash) do
            local boomer = any:find(__)
            if boomer ~= nil then
                return true
            end
        end
        return false
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    local function garbageClear(tab)
        if type(tab) == "table" then
            for k, v in pairs(tab) do
                if type(v) == "table" then
                    if not v or v == "" or #v == 0 then
                        k = nil
                    end
                    if type(v) == "table" then
                        garbageClear(v)
                    end
                end
            end
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function FortifyGC(tab)
        local temp = tab
        for k, v in pairs(temp) do
            for key, value in pairs(temp[k]) do
                for index, val in pairs(temp[k][key]) do
                    for p, o in pairs(temp[k][key][index]) do
                        if not o or #o == 0 or o == "" then
                            p = nil
                        end
                    end
                    if not val or #val == 0 or val == "" then
                        index = nil
                    end
                end
                if not value or #value == 0 or value == "" then
                    key = nil
                end
            end
            if not v or #v == 0 or v == "" then
                k = nil
            end
        end
        return temp
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    DumperTable = {
        Update = function(self, ...)
            local name, class, FM, data = ...
            if not self[name] then
                self[name] = {}
            else
                if not self[name][class] then
                    self[name][class] = {}
                else
                    if data ~= nil and not self[name][class][FM] then
                        self[name][class][FM] = {}
                    else
                        if data ~= nil then
                            self[name][class][FM][#self[name][class][FM] + 1] = data
                            garbageClear(DumperTable)
                        end
                    end
                end
            end
        end
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    for namespace, classname, body in str:gmatch("Namespace: (%g+)\n%.*public class (%a+) .-// TypeDefIndex:.-\n{(.-)\n}") do
        if not namespace then
            namespace = "System"
        end
        if not TrashClean(namespace) then
            namespace = namespace:gsub("[.]", "")
            local bug = string.find(body, "public const string %a+ =%g+")
            if bug ~= nil then
                body = ""
            end
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            for fbody in body:gmatch("// Fields\n(.-)%// [%bMethods*%bProperties*]+.\n") do
                for field_dtype, Mode, field_name, field_offset in fbody:gmatch(".-([public+*private+*protected+*internal+]+%s*[*override+*static+*readonly+*]*) (%a+) (%g+); // (0x%x+)") do
                    if field_offset ~= "0x0" and (Mode == "int" or Mode == "bool" or Mode == "double" or Mode == "float") then
                        local temp = {
                            name = tostring(field_name),
                            type = tostring(Mode),
                            Offset = field_offset,
                            info = tostring(field_dtype)
                        }
                        if field_dtype ~= nil and Mode ~= nil and field_name ~= nil and field_offset ~= nil then
                            DumperTable:Update(namespace, classname, "Fields", temp)
                            if not PC then
                                gg.toast("Plz Wait...", true)
                            else
                                print(field_dtype, Mode, field_name, field_offset)
                            end
                        end
                    end
                end
            end
            --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            for meth in body:gmatch("// Methods(.+)") do
                for offset, _, data_type, method_name in meth:gmatch("RVA:.-Offset: (0x%x+).-([public+*private+*protected+*internal+]+%s*[*override+*static+*readonly+*]*) (%.*%a+) (.-) %{ %}\n") do
                    if data_type == "int" or data_type == "bool" or data_type == "double" or data_type == "float" then
                        if offset ~= nil and _ ~= nil and data_type ~= nil and method_name ~= nil then
                            local temp = {
                                name = tostring(method_name:gsub("%(.-%)", "")),
                                type = tostring(data_type),
                                Offset = offset,
                                Info = _
                            }
                            DumperTable:Update(namespace, classname, "Methods", temp)
                            if PC == true then
                                print(data_type, method_name)
                            end
                        end
                    end
                end
            end
        end
    end

    DumperTable.Update = nil
    garbageClear(DumperTable)
    return DumperTable
end
Dumper(str)
DumperTable = FortifyGC(DumperTable)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Dump(ResTab)
    local cache, stack, output = {}, {}, {}
    local depth = 1
    local output_str = "{\n"
    while true do
        local size = 0
        for k, v in pairs(ResTab) do
            size = size + 1
        end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        local cur_index = 1
        for k, v in pairs(ResTab) do
            if (cache[ResTab] == nil) or (cur_index >= cache[ResTab]) then
                if (string.find(output_str, "}", output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str, "\n", output_str:len())) then
                    output_str = output_str .. "\n"
                end
                table.insert(output, output_str)
                output_str = ""
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "[" .. tostring(k) .. "]"
                else
                    key = "['" .. tostring(k) .. "']"
                end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. string.rep("\t", depth) .. key .. " = " .. tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. string.rep("\t", depth) .. key .. " = {\n"
                    table.insert(stack, ResTab)
                    table.insert(stack, v)
                    cache[ResTab] = cur_index + 1
                    break
                else
                    output_str = output_str .. string.rep("\t", depth) .. key .. " = '" .. tostring(v) .. "'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep("\t", depth - 1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep("\t", depth - 1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        if (size == 0) then
            output_str = output_str .. "\n" .. string.rep("\t", depth - 1) .. "}"
        end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        if (#stack > 0) then
            ResTab = stack[#stack]
            stack[#stack] = nil
            depth = cache[ResTab] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    table.insert(output, output_str)
    output_str = table.concat(output)
    return output_str
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Res = io.output("DumpTable.lua")
Res:write(
    "\n--[[\nNameSpace  ->>\n ClassName  ->>\n  (•)Fields \n\t ► Info \n\t ►  Name \n\t ►  Offset\n  (•)Methods \n\t ► Info \n\t ►  name \n\t ►  Type \n\t ►  Offset\n]]\n\n" ..
        "Dumped_table = " .. Dump(DumperTable)
)
Res:close()
File:close()
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
if not PC then
    gg.alert("◄\tSuccess\t►\n\n\n File Name : DumpTable.lua\n\n Dir same as the script path!")
else
    print("\n\n\n\n\n\n\tSuccess\t\n\n\n\n\n\n File Name : DumpTable.lua\n\n Dir same as the script path!")
end
