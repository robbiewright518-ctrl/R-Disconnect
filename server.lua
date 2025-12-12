local lastCoords = {}

RegisterNetEvent('robbies_disconnect:updateCoords', function(coords)
    lastCoords[source] = coords
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local coords = lastCoords[src] or vector3(0,0,0)
    local id = src

    local displayReason = reason
    if reason:lower():find("quit") then
        displayReason = "Quit"
    end

    TriggerClientEvent('robbies_disconnect:showText', -1, coords, id, displayReason)
    lastCoords[src] = nil
end)