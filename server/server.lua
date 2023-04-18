-- Define the duty logs table
local QBCore = exports["qb-core"]:GetCoreObject()

QBCore.Commands.Add("onduty", "Start a duty shift", {}, false, function(source, args)
    local playerId = source
    local player = QBCore.Functions.GetPlayer(playerId)
    local citizenid = player.PlayerData.citizenid

    if player.PlayerData.job.name == 'police' or  player.PlayerData.job.name == 'ambulance' then
        local query = 'SELECT * FROM duty_logs WHERE citizenid = ? AND end_time IS NULL'
        exports.oxmysql:execute(query, {citizenid}, function(result)
            if result[1] then
                local startTime = os.time()
                exports.oxmysql:execute('UPDATE duty_logs SET start_time = ? WHERE citizenid = ?', {startTime, citizenid})
                TriggerClientEvent('chat:addMessage', playerId, { args = { '^1Duty Logs', '^7You are already on duty.' } })
            else
                local startTime = os.time()
                exports.oxmysql:execute('INSERT INTO duty_logs (start_time, citizenid) VALUES (?, ?)', {startTime, citizenid})
                TriggerClientEvent('chat:addMessage', playerId, { args = { '^1Duty Logs', '^7You are now on duty.' } })
                -- TriggerClientEvent('chat:addMessage', -1, { args = { '^1Duty Logs', citizenid..' Just Clocked In' } })
            end
        end)
    else 
        TriggerClientEvent('QBCore:Notify', source, 'Only for Emergency Services', 'error', 2500)
    end
end)

QBCore.Commands.Add("offduty", "End a duty shift", {}, false, function(source, args)
    local playerId = source
    local player = QBCore.Functions.GetPlayer(playerId)
    local citizenid = player.PlayerData.citizenid
    if player.PlayerData.job.name == 'police' or  player.PlayerData.job.name == 'ambulance' then
        local query = 'SELECT * FROM duty_logs WHERE citizenid = ? AND end_time IS NULL'
        exports.oxmysql:execute(query, {citizenid}, function(result)
            if result[1] then
                local endTime = os.time()
                local duration = endTime - result[1].start_time
                exports.oxmysql:execute('UPDATE duty_logs SET end_time = ?, duration = ? WHERE citizenid = ? AND end_time IS NULL', {endTime, duration, citizenid})
                TriggerClientEvent('chat:addMessage', playerId, { args = { '^1Duty Logs', '^7You are now off duty.' } })
                -- TriggerClientEvent('chat:addMessage', -1, { args = { '^1Duty Logs', citizenid..' Just Clocked out' } })
            else
                TriggerClientEvent('chat:addMessage', playerId, { args = { '^1Duty Logs', '^7You are not on duty.' } })
            end
        end)
    else 
        TriggerClientEvent('QBCore:Notify', source, 'Only for Emergency Services', 'error', 2500)
    end
end)

QBCore.Commands.Add("dutycheck", "Check the total duty duration of a citizen", {{name = "citizenid", help = "Citizen ID of the officer to check duty duration for"}}, true, function(source, args)
    local playerId = source
    local citizenid = args[1]
    local player = QBCore.Functions.GetPlayer(playerId)
    print(player.PlayerData.job.isboss)
    if player.PlayerData.job.name == 'police' or  player.PlayerData.job.name == 'ambulance' then
        if player.PlayerData.job.isboss then 
            local query = 'SELECT SUM(duration) AS total_duration FROM duty_logs WHERE citizenid = ?'
            exports.oxmysql:execute(query, {citizenid}, function(result)
                if result[1].total_duration then
                    local totalDuration = result[1].total_duration
                    local hours = math.floor(totalDuration / 3600)
                    local minutes = math.floor((totalDuration % 3600) / 60)
                    local seconds = totalDuration % 60
                    TriggerClientEvent('chat:addMessage', playerId, { args = { '^1Duty Logs', string.format('^7Total duty duration for %s: %02d:%02d:%02d', citizenid, hours, minutes, seconds) } })
                else
                    TriggerClientEvent('chat:addMessage', playerId, { args = { '^1Duty Logs', string.format('^7No duty logs found for %s', citizenid) } })
                end
            end)
        else 
            TriggerClientEvent('QBCore:Notify', source, 'Only for Boss', 'error', 2500)
        end
    else 
        TriggerClientEvent('QBCore:Notify', source, 'Only for Emergency Services', 'error', 2500)
    end
end)

QBCore.Commands.Add("dutyreset", "Reset the total duty duration of a citizen", {{name = "citizenid", help = "Citizen ID of the officer to reset duty duration for"}}, true, function(source, args)
    local playerId = source
    local citizenid = args[1]
    local player = QBCore.Functions.GetPlayer(playerId)
    if player.PlayerData.job.name == 'police' or  player.PlayerData.job.name == 'ambulance' then
        if player.PlayerData.job.isboss then 
            local query = 'SELECT SUM(duration) AS total_duration FROM duty_logs WHERE citizenid = ?'
            exports.oxmysql:execute(query, {citizenid}, function(result)
                if result[1].total_duration then
                    exports.oxmysql:execute('DELETE FROM duty_logs WHERE citizenid = ?', {citizenid})
                    TriggerClientEvent('chat:addMessage', playerId, { args = { '^1Duty Logs', string.format('^7Duty duration for %s has been reset.', citizenid) } })
                else
                    TriggerClientEvent('chat:addMessage', playerId, { args = { '^1Duty Logs', string.format('^7No duty logs found for %s', citizenid) } })
                end
            end)
        else 
            TriggerClientEvent('QBCore:Notify', source, 'Only for Boss', 'error', 2500)
        end
    else 
        TriggerClientEvent('QBCore:Notify', source, 'Only for Emergency Services', 'error', 2500)
    end
end)

AddEventHandler("playerDropped", function()
    local player = QBCore.Functions.GetPlayer(source)
    local citizenid = player.PlayerData.citizenid
    -- Check if the officer is on duty
    local query = 'SELECT * FROM duty_logs WHERE citizenid = ? AND end_time IS NULL'
    exports.oxmysql:execute(query, {citizenid}, function(result)
      if result[1] then
        local endTime = os.time()
        local duration = endTime - result[1].start_time
        exports.oxmysql:execute('UPDATE duty_logs SET end_time = ?, duration = ? WHERE citizenid = ? AND end_time IS NULL', {endTime, duration, citizenid})
      end
    end)
end)
  
