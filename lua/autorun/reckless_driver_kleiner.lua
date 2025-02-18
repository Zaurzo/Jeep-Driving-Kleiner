-- get ur drivers license kleiner!!!!!!
-- you keep hitting everything...

do
    local ENT = {}

    ENT.Base = 'base_gmodentity'
    ENT.Type = 'ai'

    function ENT:Initialize()
        self:SetModel('models/player/kleiner.mdl')
        self:SetSubMaterial(5, 'models/kleiner/kleiner_sheet')
    end
    
    function ENT:Think()
        self:SetSequence(389)
        self:SetCycle(0)
    end

    scripted_ents.Register(ENT, 'reckless_kleiner')
end

do
    local ENT = {}
    local classname = 'reckless_dr_isaac_kleiner'

    ENT.Base = 'base_gmodentity'
    ENT.Type = 'anim'

    hook.Add('SetupCloseCaptions', 'reckless_kleiner_captions', function()
        local function addEnglishCaption(name, text, dur)
            text = text or ''

            sound.AddCaption({
                sound = 'reckless_driver_kleiner/' .. name .. '.mp3',
                text = { english = text },
                duration = dur
            })
        end

        addEnglishCaption('line1', 'Oh my goodness, we\'re going turbo speed!', 2.3)
        addEnglishCaption('line2', 'Great Scott. I can already presume a speeding ticket in my near future!', 4)
        addEnglishCaption('line3', 'I will confess this is probably not the safest.', 2.5)
        addEnglishCaption('line4', 'If we do this any longer, I just might crash.', 2.8)
        addEnglishCaption('kill1', 'Haha! See-ya suckers!', 1.5)
        addEnglishCaption('kill2', 'I don\'t feel an ounce of regret.', 1.5)
        addEnglishCaption('kill3', 'Uh-oh! Road bump ahead!', 2)
        addEnglishCaption('kill4', 'How silly of you, you should always look both ways when crossing.', 3)
    end)

    if SERVER then
        hook.Add('CanPlayerEnterVehicle', 'reckless_kleiner_jeep_control', function(ply, veh)
            if veh.ownedByRecklessDriverKleiner and IsValid(veh.driver) then
                return false
            end
        end)

        hook.Add('PlayerSpawnedNPC', 'reckless_kleiner_set_creator', function(ply, ent)
            if ent:GetClass() == 'reckless_dr_isaac_kleiner' then
                ent._playerCreator = ply
            end
        end)

        hook.Add('CreateEntityRagdoll', 'reckless_kleiner_undo_ragdoll', function(owner, ragdoll)
            if owner:IsNPC() and owner.isRecklessDriverKleiner and owner:GetClass() == 'npc_kleiner' then
                undo.Create('NPC')
                    undo.SetPlayer(owner._playerCreator)
                    undo.AddEntity(ragdoll)
                    undo.SetCustomUndoText('Undone Dr. Isaac Kleiner')
                undo.Finish('NPC (npc_kleiner)')
            end
        end)

        hook.Add('PreUndo', 'reckless_kleiner_vehicle_undo', function(data)
            local ent = data.Entities and data.Entities[1]

            if IsValid(ent) and ent:GetClass() == 'reckless_dr_isaac_kleiner' and not IsValid(ent.driver) then
                data.Name = 'Vehicle'
                data.NiceText = 'Vehicle (Jeep)'
                data.CustomUndoText = 'Undone Jeep'
            end
        end)

        hook.Add('EntityTakeDamage', 'reckless_kleiner_damage_control', function(ent, dmginfo)
            local attacker = dmginfo:GetAttacker()
            local dmg = dmginfo:GetDamage()

            if (attacker:IsValid() and attacker.ownedByRecklessDriverKleiner and not attacker.kleinerDead) and attacker:IsVehicle() then
                if dmg > ent:Health() then
                    local self = attacker.self

                    if IsValid(self) then
                        self:RandomVoiceLine('kill', 1, 4, 2)
                    end
                end
            end

            local health = ent.kleinerHealth

            if health and ent.ownedByRecklessDriverKleiner and not ent.kleinerDead and ent:IsVehicle() then
                local newHealth = health - dmg

                if newHealth <= 0 then
                    local driver = ent.driver

                    if IsValid(driver) then
                        local npc = ents.Create('npc_kleiner')

                        if npc:IsValid() then
                            dmginfo:SetDamage(1 / 0)

                            npc.isRecklessDriverKleiner = true
                            npc._playerCreator = IsValid(ent.self) and ent.self._playerCreator

                            npc:SetPos(driver:GetPos())
                            npc:SetAngles(driver:GetAngles())
                            npc:Spawn()
                            npc:SetShouldServerRagdoll(true)
                            npc:TakeDamageInfo(dmginfo)
                        end
                        
                        driver:Remove()
                    end
                    
                    ent.kleinerDead = true
                end

                ent.kleinerHealth = newHealth
            end
        end)

        local ai_disabled = GetConVar('ai_disabled')
        local ai_ignoreplayers = GetConVar('ai_ignoreplayers')

        local vector_up = vector_up

        function ENT:RandomVoiceLine(name, min, max, delay)
            if not IsValid(self.driver) then return end

            if delay then
                if CurTime() < (self.randomLineDelay or CurTime()) then
                    return false
                end

                self.randomLineDelay = CurTime() + delay
            end

            self.driver:EmitSound('reckless_driver_kleiner/' .. name .. math.random(min, max) .. '.mp3')
        end

        function ENT:Initialize()
            self:DrawShadow(false)
            self:SetCollisionGroup(8)

            timer.Simple(0, function()
                if not self:IsValid() then return end

                local vehicle = ents.Create('prop_vehicle_jeep_old')
                local driver = ents.Create('reckless_kleiner')

                if not vehicle:IsValid() or not driver:IsValid() then return end

                vehicle:SetSpawnEffect(true)
                driver:SetSpawnEffect(true)

                vehicle:SetModel('models/buggy.mdl')
                vehicle:SetKeyValue('vehiclescript', 'scripts/vehicles/jeep_test.txt')
                vehicle:SetPos(self:GetPos())
                vehicle:SetAngles(self:GetAngles())
                vehicle:Spawn()

                driver:SetAngles(vehicle:GetAngles() + Angle(0, 90, 0))
                driver:SetPos(vehicle:GetPos() - vehicle:GetRight() * 9 + vehicle:GetUp() * 24 - vehicle:GetForward() * 48)

                driver:Spawn()
                driver:SetParent(vehicle)

                vehicle.ownedByRecklessDriverKleiner = true
                vehicle.kleinerHealth = 50

                vehicle.reverseDelay = CurTime() + 1
                vehicle.driver = driver
                vehicle.self = self

                vehicle.turboSound = CreateSound(vehicle, 'vehicles/v8/v8_turbo_on_loop1.wav')
                vehicle.turboSound:Play()

                vehicle.turboSound:ChangeVolume(0)
                vehicle.turboSound:SetSoundLevel(180)

                driver.isRecklessDriverKleiner = true

                local phys = vehicle:GetPhysicsObject()
                local hookName = tostring(vehicle) .. '_VehicleMove'

                vehicle:CallOnRemove('stopTurboSound', function()
                    if self:IsValid() then
                        self:Remove()
                    end

                    hook.Remove('Think', hookName)

                    vehicle.turboSound:Stop()
                end)

                driver:CallOnRemove('stopVehicleThink', function()
                    if vehicle:IsValid() then
                        vehicle.turboSound:Stop()
                    end

                    hook.Remove('Think', hookName)
                end)

                self.vehicle = vehicle
                self.driver = driver

                self:SetModel('models/props_junk/PopCan01a.mdl')

                timer.Create(hookName, 0.25, 0, function()
                    if not vehicle:IsValid() or not driver:IsValid() then
                        timer.Remove(hookName)
                        return
                    end
            
                    if ai_disabled:GetBool() then
                        vehicle.enemy = nil
                        return
                    end

                    local enemy = vehicle.enemy
                    local hasEnemy = IsValid(enemy)
            
                    if hasEnemy and enemy:IsPlayer() then
                        if not enemy:Alive() or ai_ignoreplayers:GetBool() then
                            vehicle.enemy = nil
                            return
                        end
                    end

                    if not hasEnemy then
                        for k, ent in ipairs(ents.GetAll()) do
                            if (ent:IsNextBot() or (ent:IsNPC() and ent:GetClass() ~= 'reckless_kleiner') or (ent:IsPlayer() and ent:Alive())) and driver:Visible(ent) then
                                vehicle.enemy = ent
                                break
                            end
                        end
                    end
                end)

                local world = game.GetWorld()

                hook.Add('Think', hookName, function()
                    if not vehicle:IsValid() or not driver:IsValid() then return end
                    
                    local pos = vehicle:GetPos()
                    local onGroundCheck = util.TraceLine({
                        start = pos,
                        endpos = pos + vector_up * -50,
                        mask = MASK_NPCWORLDSTATIC
                    })
                
                    if onGroundCheck.Entity ~= world then return end
            
                    local enemy = vehicle.enemy
                    local vel = vehicle:GetVelocity():LengthSqr() / 100

                    if math.random(1500) == 1500 then
                        if vel > 7000 then 
                            self:RandomVoiceLine('line', 1, 2, 6)
                        else
                            self:RandomVoiceLine('line', 3, 4, 6)
                        end
                    end

                    vehicle:StartEngine(true)
                    driver:SetEyeTarget(driver:GetPos() + (driver:GetAngles():Forward() * 1000))

                    if not IsValid(enemy) then
                        vehicle.reverseDelay = CurTime() + 0.25
                        vehicle.turboSound:ChangeVolume(0)
                        
                        return vehicle:SetHandbrake(true)
                    else
                        vehicle:SetHandbrake(false)

                        vehicle.turboSound:ChangeVolume(math.Clamp(vel, 1, 1500) / 1500)
                    end    
            
                    local forward = vehicle:GetForward() * 1.5
            
                    local diff = (enemy:GetPos() - pos):GetNormalized()
                    local cross = diff:Cross(vehicle:GetForward())
                    local steer = cross:Length()

                    local getlook = math.abs(steer) < 0.15
            
                    local nside = (pos - enemy:GetPos()):Dot(vehicle:GetRight())

                    local isReversing = vehicle.reverse
                    local sidenum = (nside < 20 and (not isReversing and 1 or -1)) or (nside > 20 and (not isReversing and -1 or 1)) or 0
                    
                    if not isReversing then
                        if vel > 1 then
                            vehicle.reverseDelay = CurTime() + 0.25
                        elseif CurTime() > vehicle.reverseDelay then
                            vehicle.reverse = true

                            timer.Simple(math.Rand(2, 4), function()
                                if vehicle:IsValid() then
                                    vehicle.reverse = false
                                    vehicle.reverseDelay = CurTime() + 0.25
                                end
                            end)
                        end
                    end
                    
                    if not getlook then
                        vehicle:SetSteering(sidenum, sidenum ~= -1 and 1 or 0)
            
                        if vel > 800 and not vehicle.reverse then
                            phys:SetVelocity(vehicle:GetVelocity() - vehicle:GetForward() * 22)
                        end
                    else
                        if vehicle.reverse then
                            vehicle.reverse = false
                        end

                        vehicle:SetSteering(0, 0)
                    end
            
                    phys:SetVelocity(vehicle:GetVelocity() + vehicle:GetForward() * (vehicle.reverse and -6.25 or 20))
                end)
            end)
        end

        function ENT:OnRemove()
            SafeRemoveEntity(self.vehicle)
            SafeRemoveEntity(self.driver)
        end    
    else
        function ENT:Draw() 
        end
    end

    scripted_ents.Register(ENT, classname)

    list.Set('NPC', classname, {
        Name = 'reckless driver kleiner',
        Category = 'Comedic',
        IconOverride = 'reckless_driver_kleiner/spawnicon.png',
        Class = classname,
    })
end

if CLIENT then
    --language.Add('jeep_owned_by_reckless_driver_kleiner', 'Reckless Driver Kleiner (Jeep)')

    language.Add('reckless_kleiner', 'Reckless Driver Kleiner')
    killicon.Add('jeep_owned_by_reckless_driver_kleiner', 'HUD/killicons/default', Color(255, 80, 0, 255))
end