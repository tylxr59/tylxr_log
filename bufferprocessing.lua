-- This was the only way I could get both the buffer to work and also not have the buffer processing function be spawned multiple times by each script every time a log was sent.
IsProcessBufferStarted = false
Buffer = {}

local function badResponse(endpoint, status, response)
    warn(('unable to submit logs to %s (status: %s)\n%s'):format(endpoint, status, json.encode(response, { indent = true })))
end

-- Change this to your Loki server's endpoint if its being run on a different server
local endpoint = 'http://localhost:3100/loki/api/v1/push'
local headers = {
    ['Content-Type'] = 'application/json'
}

function ProcessBuffer()
    if #Buffer > 0 then
        -- Perform the HTTP request for all logs in the buffer
        local postBody = json.encode({streams = Buffer})
        PerformHttpRequest(endpoint, function(status, _, _, _)
            if status ~= 204 then
                print(postBody)
                badResponse(endpoint, status, ("%s"):format(status, postBody))
            end
        end, 'POST', postBody, headers)
        -- Clear the buffer
        Buffer = {}
    end

    SetTimeout(5000, ProcessBuffer)
end

-- On resource start, start the buffer processing
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName and not IsProcessBufferStarted then
        IsProcessBufferStarted = true
        ProcessBuffer()
    end
end)

RegisterNetEvent('ox_logger:buffer', function(payload)
    print(json.encode(payload))
    table.insert(Buffer, payload)
end)