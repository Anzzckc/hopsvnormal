local AllIDs = {}
local FailedIDs = {}
local foundAnything = ""
local actualHour = os.date("!*t").hour
local S_T = game:GetService("TeleportService")
local S_H = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")

local File = pcall(function()
    AllIDs = S_H:JSONDecode(readfile("server-hop-temp.json"))
end)
if not File then
    table.insert(AllIDs, actualHour)
    pcall(function()
        writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
    end)
end

local function SmartTeleport(placeId, jobId)
    if jobId == game.JobId then return false end
    local sb = RS:FindFirstChild("__ServerBrowser")
    if sb and sb:IsA("RemoteFunction") then
        local success = pcall(function()
            return sb:InvokeServer("teleport", jobId)
        end)
        if success then return true end
    end
    local success = pcall(function()
        S_T:TeleportToPlaceInstance(placeId, jobId, game.Players.LocalPlayer)
    end)
    return success
end

local function TPReturner(placeId)
    local Site;
    if foundAnything == "" then
        Site = S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100'))
    else
        Site = S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
    end
    if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
        foundAnything = Site.nextPageCursor
    end
    local num = 0
    for i,v in pairs(Site.data) do
        local Possible = true
        local ID = tostring(v.id)
        if tonumber(v.maxPlayers) > tonumber(v.playing) and ID ~= game.JobId then
            for _,Existing in pairs(AllIDs) do
                if ID == tostring(Existing) then
                    Possible = false
                    break
                end
            end
            if Possible then
                for _,Failed in pairs(FailedIDs) do
                    if ID == tostring(Failed) then
                        Possible = false
                        break
                    end
                end
            end
            if Possible then
                table.insert(AllIDs, ID)
                wait()
                pcall(function()
                    writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
                    wait()
                    local teleported = SmartTeleport(placeId, ID)
                    if not teleported then
                        table.insert(FailedIDs, ID)
                    end
                end)
                wait(4)
            end
        end
        num = num + 1
    end
end

local module = {}
function module:Teleport(placeId)
    while wait() do
        pcall(function()
            TPReturner(placeId)
            if foundAnything ~= "" then
                TPReturner(placeId)
            end
        end)
    end
end
return module
