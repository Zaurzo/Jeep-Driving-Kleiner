local cc_lang, cc_subtitles
local captions = {}

local function SendCloseCaption(sound, pos, fromPlayer)
    if not sound then return end

    pos = pos or vector_origin
    fromPlayer = fromPlayer == nil and false or fromPlayer

    if SERVER then
        net.Start('gmod_close_captions')
        net.WriteString(sound)
        net.WriteVector(pos)
        net.WriteBool(fromPlayer)
        net.Broadcast()
    end

    if CLIENT and gui.AddCaption then
        local tab = captions[sound]
        if not tab then return end

        local lang = cc_lang:GetString()

        if not lang or lang == '' then
            lang = 'english'
        end

        local caption = tab.text[lang]

        if not caption or (tab.sfx and cc_subtitles:GetBool()) then return end
        
        if pos then
            local dist = pos:DistToSqr(LocalPlayer():GetPos()) / 10000

            if dist > 100 then 
                return 
            end
        end

        gui.AddCaption(caption, tab.duration or SoundDuration(sound), fromPlayer)
    end
end

if SERVER then
    util.AddNetworkString('gmod_close_captions')
end

if CLIENT then
    cc_lang = GetConVar('cc_lang')
    cc_subtitles = GetConVar('cc_subtitles')

    net.Receive('gmod_close_captions', function()
        SendCloseCaption(net.ReadString(), net.ReadVector(), net.ReadBool())
    end)
end

hook.Add('EntityEmitSound', 'gmod_lua_close_captions', function(soundData)
    local sound = soundData.SoundName:lower()

    if string.match(sound, '^%W') then
        sound = string.sub(sound, 2)
    end

    if not captions[sound] then return end

    local ent = soundData.Entity
    local isEntityValid = ent and ent:IsValid()

    SendCloseCaption(sound, isEntityValid and ent:GetPos(), isEntityValid and ent:IsPlayer())
end)

function sound.AddCaption(tab)
    if not istable(tab) then
        return error("bad argument #1 to 'AddCaption' (table expected, got " .. type(tab) .. ")", 2)
    end

    local sound = tab.sound

    if sound and tab.text then
        captions[sound] = tab
    end
end

function sound.GetCaptionTable()
    return captions
end

timer.Simple(0.1, function()
    hook.Run('SetupCloseCaptions')
end)