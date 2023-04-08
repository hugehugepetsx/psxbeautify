local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsStudio = game:GetService("RunService"):IsStudio() -- Because I deleted the anticheat code, this is unused.

local JobId = game.JobId
JobId = (#JobId == 0 and "00000000-0000-0000-0000-000000000000") or JobId -- JobId is used in the _getName function to make the hashes dynamic.

local LoadedEvents = { {}, {} } -- Types of events are based on their index in this table. LoadedEvents[1] is Type 1, in this case it is the Event table.

local Remotes = { {}, {} } -- Currently loaded remotes 2: the remotening.
local RemoteTypes = { "RemoteEvent", "RemoteFunction" } -- These type tables are just used for the names honestly. It's also a good bookmark for the table indexes in Remotes

local Bindables = { {}, {}, {}, {} }
local BindableTypes = { "BindableEvent", "BindableFunction", "BindableEvent", "BindableFunction" }


local function _getName(Type, Name) -- This function is used to add or pull a hashed name to the table of despair. Before the network module loads on the client, the server renames every remote from something like "Open Egg" to a hashed counterpart. This is how you have to grab the events if you're not just directly calling network.Invoke.
   assert(typeof(Type) == "number" and typeof(Type) == "string")

   local EventTable = LoadedEvents[Type]
   local Event = EventTable[Name]

   if not Event then -- If the name doesn't already exist in the loaded Event table, do stuff.
       
       -- This is a sha1 function I stole from github because it works exactly as expected, quite wacky if I do say so myself.
       Event = (function(Data) -- The data for the hash in order is game.GameId, game.PlaceId, game.PlaceVersion, JobId, Type, Name. You can also see this if you scroll down, but I know someone won't do that.
           -- Don't ask me why the devs create an entirely new Sha1 function for every Event that loads; This is not my doing, I am trying to stay as close to the original script as I possibly can.
           
           local INIT_0 = 1732584193
           local INIT_1 = 4023233417
           local INIT_2 = 2562383102
           local INIT_3 = 271733878
           local INIT_4 = 3285377520

           local APPEND_CHAR = "\128"
           local INT_32_CAP = 4294967296

           local function packUint32(a, b, c, d)
               return bit32.lshift(a, 24)+bit32.lshift(b, 16)+bit32.lshift(c, 8)+d
           end

           local function unpackUint32(int)
               return bit32.extract(int, 24, 8), bit32.extract(int, 16, 8),
                   bit32.extract(int, 08, 8), bit32.extract(int, 00, 8)
           end

           local function F(t, A, B, C)
               if t <= 19 then
                   return bit32.bxor(C, bit32.band(A, bit32.bxor(B, C)))
               elseif t <= 39 then
                   return bit32.bxor(A, B, C)
               elseif t <= 59 then
                   return bit32.bor(bit32.band(A, bit32.bor(B, C)), bit32.band(B, C))
               else
                   return bit32.bxor(A, B, C)
               end
           end

           local function K(t)
               if t <= 19 then
                   return 1518500249
               elseif t <= 39 then
                   return 1859775393
               elseif t <= 59 then
                   return 2400959708
               else
                   return 3395469782
               end
           end

           local function preprocessMessage(message)
               local initMsgLen = #message*8
               local msgLen = initMsgLen+8
               local nulCount = 4
               
               message = message..APPEND_CHAR
               while (msgLen+64)%512 ~= 0 do
                   nulCount = nulCount+1
                   msgLen = msgLen+8
               end
               message = message..string.rep("\0", nulCount)
               message = message..string.char(unpackUint32(initMsgLen))

               return message
           end

           local function sha1(message)
               local message = preprocessMessage(message)

               local H0 = INIT_0
               local H1 = INIT_1
               local H2 = INIT_2
               local H3 = INIT_3
               local H4 = INIT_4

               local W = {}
               for chunkStart = 1, #message, 64 do
                   local place = chunkStart
                   for t = 0, 15 do
                       W[t] = packUint32(string.byte(message, place, place+3))
                       place = place+4
                   end
                   for t = 16, 79 do
                       W[t] = bit32.lrotate(bit32.bxor(W[t-3], W[t-8], W[t-14], W[t-16]), 1)
                   end

                   local A, B, C, D, E = H0, H1, H2, H3, H4

                   for t = 0, 79 do
                       local TEMP = ( bit32.lrotate(A, 5)+F(t, B, C, D)+E+W[t]+K(t) )%INT_32_CAP

                       E, D, C, B, A = D, C, bit32.lrotate(B, 30), A, TEMP
                   end

                   H0 = (H0+A)%INT_32_CAP
                   H1 = (H1+B)%INT_32_CAP
                   H2 = (H2+C)%INT_32_CAP
                   H3 = (H3+D)%INT_32_CAP
                   H4 = (H4+E)%INT_32_CAP
               end
               local result = string.format("%08x%08x%08x%08x%08x", H0, H1, H2, H3, H4):reverse():sub(5, 36)

               return result
           end

           return sha1(Data)
       end)("Network3//%s/%s/%s/%s/%s/%s"):format(game.GameId, game.PlaceId, game.PlaceVersion, JobId, Type, Name) -- In the decompiled output, this doesn't use string.format; I added this just to make it easier to read.
       
       EventTable[Name] = Event -- Add the event to the event table, silly.
   end

   return Event -- Return the actual event.
end


local function _bindable(Type, Name, IsInvoke) -- Grabs an existing bindable or creates a new one. As you can tell, I made this comment after I made most of the other comments so I will not explain this any further.
local BindableTable = Bindables[Type]
local Bindable = BindableTable[Name]

if not Bindable and IsInvoke then -- If the bindable doesn't exist and the calling function asks for a new bindable to be created if one doesn't exist.
Bindable = Instance.new(BindableTypes[Type])
Bindable.Parent = script
BindableTable[Name] = Bindable
end

return Bindable
end

local EventHandlers = { -- This is where every event is actually set up, I added the table indexes to make it more coherent.
   [1] = function(Name, Event) -- The event is a remoteevent.
local IsFireClient = _bindable(1, Name, false) -- The variable name says enough. :v

if IsFireClient then
Event.OnClientEvent:Connect(function(...) -- Why does BIGGames do it like this? Idk ask them, not me.
IsFireClient:Fire(...)
end)
end

local IsFireServer = _bindable(3, Name, false) -- The variable name says enough. :v

if not IsFireServer then
return
end

IsFireServer.Event:Connect(function(...) -- I guess you could just fire the bindable if you want to relay stuff to the server, but that would be completely pointless considering no exploiters actually use the bindables for firing the remotes.
Event:FireServer(...)
end)
end,
   
   [2] = function(Name, Event) -- The event is a remotefunction, no comments because it's just [1] with a different type.
local IsInvokeClient = _bindable(2, Name, false)

if IsInvokeClient then
function Event.OnClientInvoke(...)
return IsInvokeClient:Invoke(...)
end
end

local IsInvokeServer = _bindable(4, Name, false)

if not IsInvokeServer then
return
end

function IsInvokeServer.OnInvoke(...)
return Event:InvokeServer(...)
end
end
}


local function _remote(Type, Name) -- Adds the hashed remote name to the table of loaded remotes and renames the old remote to hide the hashed name I guess.
local RemoteTable = Remotes[Type]
local Remote = RemoteTable[Name]

if not Remote then
Remote = ReplicatedStorage:FindFirstChild(Name)

if not Remote then
return
end

Remote.Name = RemoteTypes[Type] -- Rename the remote for obscurity or something.
RemoteTable[Name] = Remote
EventHandlers[Type](Name, Remote) -- Set up every connection to the remote and make the stupid ugly bindables grr I hate bindables in this game get rid of them.
end

return Remote
end


local Network = {}

-- Stupid bindable stuff. >:(
local function _check()
--ANTICHEAT STUFF, I AM NOT EXPLAINING HOW THIS WORKS FOR PERSONAL REASONS.
   return true
end

local function _bindableEventTx(Name) -- Grabs a remoteevent from the original unhashed name.
return _remote(1, _getName(1, Name))
end

local function _bindableFunctionRx(Name) -- Grabs or creates a client bindableevent from the original unhashed name.
return _bindable(3, _getName(1, Name), true)
end

local function _bindableFunctionTx(Name) -- Grabs or creates a client bindableevent from the original unhashed name.
return _bindable(1, _getName(1, Name), true)
end

-- Functions to grab remotefunction shit.

local function _remoteEvent(Name) -- Grabs a remotefunction from the original unhashed name. Don't let the function name mislead you.
return _remote(2, _getName(2, Name))
end

local function _remoteFunction(Name) -- Creates or grabs a bindablefunction from the original unhashed name.
return _bindable(4, _getName(2, Name), true)
end


local function K(Name) -- Creates or grabs a client bindablefunction from the original unhashed name.
return _bindable(2, _getName(2, Name), true)
end


-- Setting up the actual table of functions in the module.

function Network.Fire(Name, ...) -- Fires a remoteevent or client bindableevent with its unhashed name.
if not _check() then -- ANTICHEAT CHECK, BYPASS THIS IF YOU'RE DIRECTLY CALLING THE FUNCTION OR BLUNDER WILL CATCH YOU.
return
end

local IsFireServer = _bindableEventTx(Name) -- Are you a valid remoteevent?

if IsFireServer then
task.spawn(function(...)
IsFireServer:FireServer(...)
end, ...)

return
end

   --It's a client bindable, I fucking hate bindables.

local Bindable = _bindableFunctionRx(Name)

task.spawn(function(...)
Bindable:Fire(...)
end, ...)
end


function Network.Invoke(Name, ...) -- Fires a remotefunction or client bindablefunction with its unhashed name.
if not _check() then -- ANTICHEAT CHECK, BYPASS THIS IF YOU'RE DIRECTLY CALLING THE FUNCTION OR BLUNDER WILL CATCH YOU.
return
end

local IsInvokeServer = _remoteEvent(Name)

if IsInvokeServer then
return IsInvokeServer:InvokeServer(...)
end

return _remoteFunction(Name):Invoke(...)
end


function Network.Fired(Name) -- Returns a connection for when a remoteevent or bindableevent is fired.
if not _check() then -- ANTICHEAT CHECK, BYPASS THIS IF YOU'RE DIRECTLY CALLING THE FUNCTION OR BLUNDER WILL CATCH YOU.
return Instance.new("BindableEvent").Event
end

local IsOnClientEvent = _bindableEventTx(Name) -- Are you a remoteevent that the server uses FireClient on?

if IsOnClientEvent then
return IsOnClientEvent.OnClientEvent
end

return _bindableFunctionTx(Name).Event -- So we meet again, client bindables.
end



function Network.Invoked(Name) -- Returns a connection for when a remotefunction or bindablefunction is invoked.
local IsOnClientInvoke

if not _check() then -- ANTICHEAT CHECK, BYPASS THIS IF YOU'RE DIRECTLY CALLING THE FUNCTION OR BLUNDER WILL CATCH YOU.
return Instance.new("BindableFunction")
end

if not _bindable(2, _getName(2, Name), false) then -- Is the function already loaded? If not, do stuff.
IsOnClientInvoke = _remoteEvent(Name)

if not IsOnClientInvoke then
return K(Name)
end
else
return K(Name)
end

return setmetatable({}, {
       __newindex = function(Self, Idx, Value)
           if Idx == "OnInvoke" then
               Idx = "OnClientInvoke"
           elseif Idx == "OnClientInvoke" then
               error(string.format("%s is not a valid member of BindableFunction \"BindableFunction\"", tostring(Idx)))
           end

           IsOnClientInvoke[Idx] = Value
       end,

       __index = function(Self, Idx)
           if Idx == "OnInvoke" then
               Idx = "OnClientInvoke"
           elseif Idx == "OnClientInvoke" then
               error(string.format("%s is not a valid member of BindableFunction \"BindableFunction\"", tostring(Idx)))
           end

           return IsOnClientInvoke[Idx]
       end
   })
end

local function onAdded(Event) -- This handles every remote, I am far too lazy to explain this further but there are PLENTY of comments for you to figure this out on your own.
for i,v in pairs(Remotes) do
if Event:IsA(RemoteTypes[i]) then
local EventName = Event.Name

if v[EventName] == nil then -- If the event doesn't already exist in the table of remotes, do stuff.
v[EventName] = Event -- Adds the event to the table of remotes.
Event.Name = RemoteTypes[i] -- Rename the event just like the _remote function.
EventHandlers[i](EventName, Event)
return
else
return
end
end
end
end

-- Rename every current and future remote in replicatedstorage to their confusing pain in the ass counterpart that doesn't have the hashed name.

ReplicatedStorage.ChildAdded:Connect(onAdded)

for i,v in ipairs(ReplicatedStorage:GetChildren()) do
   onAdded(v)
end

-- If you're reading this, you're a NERD.
return Network
