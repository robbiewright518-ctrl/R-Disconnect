local COORD_UPDATE_INTERVAL = 5000
local TEXT_DISPLAY_DURATION = 10000
local MAX_RENDER_DISTANCE = 100.0
local MAX_RENDER_DISTANCE_SQUARED = MAX_RENDER_DISTANCE * MAX_RENDER_DISTANCE
local TEXT_WRAP_LIMIT = 40

local activeTexts = {}

-- Basic fixed-width wrap to keep long messages readable in-world
local function wrapText(input, limit)
    if #input <= limit then
        return input, 1, #input
    end

    local lines = {}
    local longest = 0
    local index = 1

    while index <= #input do
        local chunk = input:sub(index, index + limit - 1)
        table.insert(lines, chunk)
        if #chunk > longest then
            longest = #chunk
        end
        index = index + limit
    end

    return table.concat(lines, "\n"), #lines, longest
end

local function withinRenderRange(fromCoords, targetCoords)
    local distSq = Vdist2(fromCoords.x, fromCoords.y, fromCoords.z, targetCoords.x, targetCoords.y, targetCoords.z)
    return distSq <= MAX_RENDER_DISTANCE_SQUARED
end

-- Update coords every 5s
CreateThread(function()
    while true do
        Wait(COORD_UPDATE_INTERVAL)
        local ped = PlayerPedId()
        if ped ~= 0 then
            TriggerServerEvent('robbies_disconnect:updateCoords', GetEntityCoords(ped))
        end
    end
end)

-- Receive disconnect info
RegisterNetEvent('robbies_disconnect:showText', function(coords, id, reason)
    local text = ("ID: %s | Reason: %s"):format(id, reason)
    local wrappedText, lineCount, longestLine = wrapText(text, TEXT_WRAP_LIMIT)
    table.insert(activeTexts, {
        coords = coords,
        text = wrappedText,
        expire = GetGameTimer() + TEXT_DISPLAY_DURATION,
        lines = lineCount,
        longestLine = longestLine
    })
end)

-- Draw 3D text with black box
local function DrawText3D(x, y, z, text, lineCount, longestLine)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    SetTextScale(0.28, 0.28)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(_x, _y)

    local lines = lineCount or 1
    local widthFactor = math.max(0.35, math.min(longestLine or #text, TEXT_WRAP_LIMIT) / TEXT_WRAP_LIMIT)
    local rectWidth = 0.02 + widthFactor * 0.18
    local rectHeight = 0.03 + (lines - 1) * 0.02
    local rectY = _y + 0.012 + (lines - 1) * 0.01
    DrawRect(_x, rectY, rectWidth, rectHeight, 0, 0, 0, 180)
end

-- Render loop (with distance check)
CreateThread(function()
    while true do
        Wait(0)
        if #activeTexts > 0 then
            local now = GetGameTimer()
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)

            for i = #activeTexts, 1, -1 do
                local entry = activeTexts[i]
                if now > entry.expire then
                    table.remove(activeTexts, i)
                else
                    if withinRenderRange(pCoords, entry.coords) then
                        DrawText3D(entry.coords.x, entry.coords.y, entry.coords.z + 0.9, entry.text, entry.lines, entry.longestLine)
                    end
                end
            end
        else
            Wait(250)
        end
    end
end)

-- Test command removed per request
