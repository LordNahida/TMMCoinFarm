local PathfindingService = game:GetService("PathfindingService");
local RunService = game:GetService("RunService");
local Workspace = game:GetService("Workspace");
local Players = game:GetService("Players");
local Player = Players.LocalPlayer;

local Characters = Workspace.Characters;
local DebrisClient = Workspace.DebrisClient;
local Mineables = Workspace.Mineables;
local Entities = Workspace.Entities;

local RaycastParameters = RaycastParams.new();

RaycastParameters.FilterType = Enum.RaycastFilterType.Whitelist;
RaycastParameters.FilterDescendantsInstances = {Entities};
RaycastParameters.RespectCanCollide = true;

local TeleportSpeed = 11.5;
local NextFrame = RunService.Heartbeat;

local function ImprovedTeleport(Target)
    if (typeof(Target) == "Instance" and Target:IsA("BasePart")) then Target = Target.Position; end;
    if (typeof(Target) == "CFrame") then Target = Target.p end;

    local HRP = (Player.Character and Player.Character:FindFirstChild("HumanoidRootPart"));
    if (not HRP) then return; end;

    local StartingPosition = HRP.Position;
    local PositionDelta = (Target - StartingPosition);--Calculating the difference between the start and end positions.
    local StartTime = tick();
    local TotalDuration = (StartingPosition - Target).magnitude / TeleportSpeed;

    repeat NextFrame:Wait();
        local Delta = tick() - StartTime;
        local Progress = math.min(Delta / TotalDuration, 1);--Getting the percentage of completion of the teleport (between 0-1, not 0-100)
        --We also use math.min in order to maximize it at 1, in case the player gets an FPS drop, so it doesn't go past the target.
        local MappedPosition = StartingPosition + (PositionDelta * Progress);
        HRP.Velocity = Vector3.new();--Resetting the effect of gravity so it doesn't get too much and drag the player below the ground.
        HRP.CFrame = CFrame.new(MappedPosition);
    until (HRP.Position - Target).magnitude <= TeleportSpeed / 20;
    HRP.Anchored = false;
    HRP.CFrame = CFrame.new(Target);
end;

local function CanGoTo(Target)
    local Path = PathfindingService:CreatePath({
        AgentCanClimb = true;
        WaypointSpacing = 1;
    });
    local HumanoidRootPart = Player.Character.HumanoidRootPart
    Path:ComputeAsync(HumanoidRootPart.Position, Target);
    local _, Points = pcall(Path.GetWaypoints, Path, HumanoidRootPart.Position);
    return (_ and #Points > 0 and Points);
end;

local function GetGifts()
    local Gifts = DebrisClient:GetChildren();
    local Mdx = #Gifts;
    for _ = 1, Mdx do
        local Gift = Gifts[_];
        if (not Gift) then break; end;
        if (Gift.Name ~= "GiftPrefab" or not Gift:FindFirstChild("Top") or not Gift:FindFirstChild("HitDetect") or not CanGoTo(Gift.HitDetect.Position)) then
            table.remove(Gifts, _);
            _ = _ - 1;
            Mdx = Mdx - 1;
        end;
    end;
    return Gifts;
end;

local function GetGiftDistance(Gift)
    if (not Gift) then return math.huge; end;
    local HitDetect = Gift:FindFirstChild("HitDetect");
    if (not HitDetect) then return math.huge; end;
    return (Player.Character.HumanoidRootPart.Position - HitDetect.Position).Magnitude;
end;

local function GetNearestGift()
    local Mineable = Mineables:GetChildren()[1];
    if (Mineable and Mineable:FindFirstChild("Highlight") and CanGoTo(Mineable.Highlight.Position)) then
        return Mineable;
    end;
    local Gifts = GetGifts();
    local ClosestGift = Gifts[1];
    local ClosestDist = GetGiftDistance(ClosestGift);

    for _ = 2, #Gifts do
        local Gift = Gifts[_];
        local Dist = GetGiftDistance(Gift);
        if (Dist < ClosestDist and Dist > 4) then
            ClosestDist = Dist;
            ClosestGift = Gift;
        end;
    end;
    
    return ((ClosestDist ~= math.huge) and ClosestGift);
end;

local function Goto(Target, Gift)
    local Path = PathfindingService:CreatePath({
        AgentCanClimb = true;
        WaypointSpacing = 1;
    });
    local HumanoidRootPart = Player.Character.HumanoidRootPart
    Path:ComputeAsync(HumanoidRootPart.Position, Target);
    local Points = Path:GetWaypoints(HumanoidRootPart.Position);
    
    for _ = 1, #Points do
        if (not Points[_ + 1]) then break; end;
        local New = Points[_].Position;
        local Next = Points[_ + 1].Position;
        if ((HumanoidRootPart.Position - New).Magnitude > 10) then warn("AX") return; end;-- AC Caught on, so abort.
        ImprovedTeleport(Vector3.new(New.X, math.max(Next.Y, New.Y) + 3, New.Z));
    end;

    if (#Points == 0) then return false; end;
    ImprovedTeleport(Points[#Points].Position + Vector3.new(0, 3, 0));
end;

local function FarmGift()
    local Gift = GetNearestGift();
    if (not Gift) then print("No gift") return; end;
    local HitDetect = Gift:FindFirstChild("HitDetect") or Gift:FindFirstChild("Highlight");
    if (not HitDetect or not HitDetect:IsA("BasePart")) then return; end;
    print(Gift)
    Goto(HitDetect.Position, Gift);
end;

_G.TMMXFarm = true;
while (_G.TMMXFarm) do
    RunService.Heartbeat:Wait();
    print(pcall(FarmGift));
end;
