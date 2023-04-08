local Network = require(game:GetService("ReplicatedStorage").Library.Client.Network)
local Fire, Invoke = Network.Fire, Network.Invoke

-- Hooking the _check function in the module to bypass the anticheat.

local old
old = hookfunction(getupvalue(Fire, 1), function(...)
   return true
end)

-- Grabbing every useful key/name (at the time this code was written)

local LocalPlayer = game:GetService("Players").LocalPlayer

local is_synapse_function = is_synapse_function or iskrnlclosure or isourclosure or isexecutorclosure
local set_identity = typeof(syn)=="table" and syn.set_thread_identity or setthreadcontext or set_thread_context or setthreadidentity or set_thread_identity -- To every exploit developer who doesn't use universal shared function names, kindly go fuck yourself for making my write this. I would not need to do this if you egomaniacs actually followed a universal namecalling convention (i love you azulx).

local Keys = {}

local function GetIndex(TableChecked, Constant, Num) -- You know who you are, ty for saving my sanity with the suggestion <3
   return TableChecked[table.find(TableChecked,Constant) - Num]
end

for i,v in next, getgc() do
   if typeof(v) == "function" and islclosure(v) and not is_synapse_function(v) then
       local Constants = getconstants(v)
       
       if table.find(Constants, "PetsControl") then
           Keys["Join Coin"] = GetIndex(Constants, "selectionFunc", 1)
           Keys["Farm Coin"] = getconstants(getproto(v,5))[#getconstants(getproto(v,5))]
       end
       
       if table.find(Constants, "CreateParticleHost") and table.find(Constants,"IsBoost") then
           Keys["Collect Lootbag"] = Constants[#Constants-1]
       end
       
       if table.find(Constants, "Coins returned as nil") then
           Keys["Get Coins"] = GetIndex(Constants, "Print", 1)
       end
       
       if table.find(Constants, "Failed to buy egg (") then
           Keys["Buy Egg"] = GetIndex(Constants, "Signal", 1)
       end
       
       if table.find(Constants, "Could not redeem rewards.") then
           Keys["Redeem Rank Rewards"] = GetIndex(Constants, "Animation", 1)
       end
       
       if table.find(Constants, "Animation") and getinfo(v).source:find("VIP R") and #Constants < 15 then
           Keys["Redeem VIP Rewards"] = GetIndex(Constants, "Animation", 1)
       end
       
       
       if table.find(Constants, "networkTarget") and not table.find(Constants, "modelGold") then
           Keys["Change Pet Target"] = GetIndex(Constants, "Coin", 1)
       end
       
       if table.find(Constants, "rbxassetid://7009851850") then
           if not table.find(Constants, "Enabled") then
               Keys["Convert To Dark Matter"] = GetIndex(Constants, "Audio", 1)
           end
           
           if getinfo(v).source:find("Golden ") then
               Keys["Use Golden Machine"] = GetIndex(Constants, "Functions", 1)
           elseif getinfo(v).source:find("Rainbow ") then
               Keys["Use Rainbow Machine"] = GetIndex(Constants, "Functions", 1)
           end
       end
       
       if table.find(Constants, 2.5) and table.find(Constants, "Invoke") then
           Keys["Enchant Pet"] = GetIndex(Constants, "Functions", 1)
       end
       
       if table.find(Constants, "rbxassetid://8993965384") then
           Keys["Redeem Free Gift"] = GetIndex(Constants, "Directory", 1)
       end
       
       if table.find(Constants, 1.2) and table.find(Constants,"UsingMachine") then
           Keys["Fuse Pets"] = GetIndex(Constants, "Functions", 1)
       end
       
       if table.find(Constants, "Are you sure you want to purchase this ") then
           Keys["Buy Merchant Item"] = GetIndex(Constants, "Audio", 2)
       end
       
       if getinfo(v).name == "RedeemQueuePet" then
           Keys["Redeem Dark Matter Pet"] = GetIndex(Constants, "Message", 1)
       end


       if getinfo(v).name == "ToggleSetting" then
           Keys["Toggle Setting"] = Constants[#Constants]
       end
       
       if getinfo(v).name == "DeletePets" then
           local IAmGoingToCry = getconstants(getproto(v,1))
           Keys["Delete Several Pets"] = GetIndex(IAmGoingToCry, "ToggleMultiDelete", 1)
       end
       
       if getinfo(v).name == "Rename" then
           Keys["Rename Pet"] = GetIndex(Constants, "Message", 2)
       end
       
       if getinfo(v).name == "ChangeDiamondAmount" then
           Keys["Change Trade Diamonds"] = GetIndex(Constants, "diamonds", 1)
       end
       
       if table.find(Constants, "Buy this area for ") then
           Keys["Buy Area"] = GetIndex(Constants, "Error", 1)
       end

       if table.find(Constants, "UpdatePriceFrame") and table.find(getconstants(v),"Boost") then
           local IAmGoingToCry = getconstants(getproto(v,2))
           Keys["Activate Boost"] = IAmGoingToCry[#IAmGoingToCry]
       end
   end
end

for i,v in next, getconnections(game.RunService.Heartbeat) do
   local Constants = v.Function and getconstants(v.Function)
   
   if Constants and table.find(Constants, 0.25) then
       Keys["Claim Orbs"] = Constants[#Constants]
   end
end


local UseBoost = getsenv(LocalPlayer.PlayerScripts:FindFirstChild("Exclusive Shop", true)).UpdateBoosts

if not Keys["Activate Boost"] then
   local BoostConstants = getconstants(getproto(getproto(UseBoost,2),2))
   
   Keys["Activate Boost"] = BoostConstants[#BoostConstants]
end


-- Firing the remote with the given remote name

local Blunder = require(game:GetService("ReplicatedStorage"):FindFirstChild("BlunderList", true))
local OldGet = Blunder.getAndClear

setreadonly(Blunder, false)

local function OutputData(Message)
   rconsoleprint("@@RED@@")
   rconsoleprint(Message .. "\n")
end

Blunder.getAndClear = function(...)
   local Packet = ...
   
   for i,v in next, Packet.list do
       if v.message ~= "PING" then
           OutputData(v.message)
           table.remove(Packet.list, i)
       end
   end
   
   return OldGet(Packet)
end