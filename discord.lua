local s,discord = pcall(require, "discordRPC")
if not s then
    print("Discord RPC failed to load! Discord features are unavailable.")
    print(discord)
    discord = nil
end

Discord = {
    running = false
}

RPCLevels = {
    OFF = 0,
    PLAYING = 1,
    PARTIAL = 2,
    FULL = 3
}

local presence = {}

function Discord.updatePresence()
    if not discord then return end
    discord.updatePresence(presence)
end

function Discord.setActivity(details, state, startTime, endTime)
    if not discord then return end
    presence.details = details
    presence.state = state
    presence.startTimestamp = startTime or presence.startTimestamp or os.time()
    presence.endTimestamp = endTime or nil
end

function Discord.setTime(startTime, endTime)
    if not discord then return end
    presence.startTimestamp = startTime or presence.startTimestamp or os.time()
    presence.endTimestamp = endTime or nil
end

function Discord.setParty(partyId, partySize, partyMax, matchSecret, joinSecret, spectateSecret)
    if not discord then return end
    presence.partyId = partyId
    presence.partySize = partySize
    presence.partyMax = partyMax
    presence.matchSecret = matchSecret
    presence.joinSecret = joinSecret
    presence.spectateSecret = spectateSecret
end

function Discord.start()
    if not discord then return end
    if Discord.running then return end
    Discord.running = true
    discord.initialize("1444766632064061520", true)
    presence.largeImageKey = "icon"
    presence.largeImageText = "VoltRhythm"
end

function Discord.stop()
    if not discord then return end
    if not Discord.running then return end
    Discord.running = false
    discord.shutdown()
end

function Discord.update()
    if not discord then return end
    discord.runCallbacks()
end

function Discord.onReady(method) if not discord then return end discord.ready = method end

function Discord.onDisconnected(method) if not discord then return end discord.disconnected = method end

function Discord.onErrored(method) if not discord then return end discord.errored = method end

function Discord.onJoinGame(method) if not discord then return end discord.joinGame = method end

function Discord.onSpectateGame(method) if not discord then return end discord.spectateGame = method end

function Discord.onJoinRequest(method) if not discord then return end discord.joinRequest = method end