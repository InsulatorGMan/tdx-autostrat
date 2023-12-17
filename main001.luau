local HttpService = game:GetService('HttpService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')

local TDX_AutoStrat = {}

TDX_AutoStrat.WorkSpaceFolder = "TDX_AutoStrat"
TDX_AutoStrat.Debug = false
TDX_AutoStrat.RemotesFolder = ReplicatedStorage:WaitForChild('Remotes')

function TDX_AutoStrat:Init()

    if not isfolder(TDX_AutoStrat.WorkSpaceFolder) then
        makefolder(TDX_AutoStrat.WorkSpaceFolder)
    end

end

-- // Move the player's character into the lobby's trigger.
function TDX_AutoStrat:JoinLobby(lobbyNumber)
    local Player = Players.LocalPlayer.Character
    Player:PivotTo(Workspace["APCs"][lobbyNumber]["APC"].Detector.CFrame)
end

-- // Looks for the required lobby and returns the lobbyNumber.
TDX_AutoStrat.SearchForGame = function(mapName, timeOut)
    local Lobbies = Workspace["APCs"]:GetChildren()
    for i, lobby in pairs(Lobbies) do
        local LobbyScreen = lobby["mapdisplay"]["screen"]["displayscreen"]
        local Map = LobbyScreen["map"].Text
        if Map == mapName then TDX_AutoStrat.JoinLobby(lobby.Name) end
    end
end

-- // Place a tower onto the battlefield.
TDX_AutoStrat.PlaceTower = function(tower, position)
    local Arguments = {
        [1] = 0, -- Unknown, Does not seem to affect anything
        [2] = tower,
        [3] = position,
        [4] = 0 -- Unknown, Does not seem to affect anything
    }
    TDX_AutoStrat.RemotesFolder:WaitForChild("PlaceTower"):InvokeServer(unpack(
                                                                            Arguments))
end

-- // Upgrade the tower with the provided path
TDX_AutoStrat.UpgradeTower = function(tower, path)
    local Arguments = {
        [1] = tower,
        [2] = path -- [1] Top [2] Bottom
    }

    TDX_AutoStrat.RemotesFolder:WaitForChild("TowerUpgradeRequest"):FireServer(
        unpack(Arguments))
end

-- // Sell the provided tower.
TDX_AutoStrat.SellTower = function(tower)
    TDX_AutoStrat.RemotesFolder:WaitForChild("SellTower"):FireServer(unpack({
        [1] = tower
    }))
end

-- // Use the tower's ability if it has one.
TDX_AutoStrat.UseTowerAbility = function(tower)
    TDX_AutoStrat.RemotesFolder:WaitForChild("TowerUseAbilityRequest")
        :InvokeServer(unpack({[1] = tower, [2] = 1}))
end

-- // Cast vote to skip the current wave.
TDX_AutoStrat.SkipWave = function()
    TDX_AutoStrat.RemotesFolder:WaitForChild("SkipWaveVoteCast"):FireServer(
        unpack({[1] = true}))
end

-- // Ready up after voting
function TDX_AutoStrat:Ready()

    TDX_AutoStrat.RemotesFolder:WaitForChild("DifficultyVoteReady"):FireServer()

end

-- // Cast difficulty vote
TDX_AutoStrat.VoteForDifficulty = function(difficulty)

    TDX_AutoStrat.RemotesFolder:WaitForChild("DifficultyVoteCast"):FireServer(
        unpack({[1] = difficulty}))

end

-- // Strategy Recorder
TDX_AutoStrat.useRecorder = function(stratName, author)

    local EventsToWatch = {
        TDX_AutoStrat.RemotesFolder["TowerUpgradeRequest"],
        TDX_AutoStrat.RemotesFolder["PlaceTower"],
        TDX_AutoStrat.RemotesFolder["SellTower"],
        TDX_AutoStrat.RemotesFolder["TowerUseAbilityRequest"],
        TDX_AutoStrat.RemotesFolder["DifficultyVoteCast"],
        TDX_AutoStrat.RemotesFolder["DifficultyVoteReady"],
        TDX_AutoStrat.RemotesFolder["SkipWaveVoteCast"]
    }

    local RecordedStrategyFileName = stratName + '_' + author + '.json'
    local StrategySteps = {}

    for i, event in pairs(EventsToWatch) do

        if event:IsA('RemoteFunction') then
            event.OnServerInvoke:Connect(
                function(_player, args)
                    table.insert(StrategySteps, args)
                end)
        else
            event.OnServerEvent:Connect(function(_player, args)
                table.insert(StrategySteps, args)
            end)
        end

    end

    local JSONEncodedStrategySteps = HttpService:JSONEncode(StrategySteps)
    print(JSONEncodedStrategySteps)

end

return TDX_AutoStrat
