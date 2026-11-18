-- Read-first quest flow. Native gamepad dialogue owns Skip/Continue/Accept;
-- never call protected quest actions or close its windows from addon code.
local frame=CreateFrame('Frame')
local function apply()
  ForeverHandheldDB=ForeverHandheldDB or {}
  local db=ForeverHandheldDB
  db.questReadingBefore=db.questReadingBefore or {}
  local function set(group,t,key,value)
    if type(t)~='table' then return end
    local before=db.questReadingBefore
    before[group]=before[group] or {}
    if before[group][key]==nil then
      before[group][key]={present=rawget(t,key)~=nil,value=t[key]}
    end
    t[key]=value
  end
  -- Loreward's bridge can reapply its choice when changing guide steps.
  if type(LorewardDB)=='table' then
    LorewardDB.settings=LorewardDB.settings or {}
    set('Loreward',LorewardDB.settings,'questAutomation','manual')
  end
  local profile=RXP and RXP.settings and RXP.settings.profile
  set('RestedXP',profile,'enableQuestAutomation',false)
  set('RestedXP',profile,'enableGossipAutomation',false)
  set('ControllerForever',ControllerForeverDB,'questAccept',nil)
  set('ControllerForever',ControllerForeverDB,'questTurnIn',nil)
  set('AutoGear',AutoGearDB,'AutoAcceptQuests',false)
  set('AutoGear',AutoGearDB,'AutoCompleteNonItemQuests',false)
  set('AutoGear',AutoGearDB,'AutoCompleteItemQuests',false)
  -- AutoGear's equipment scoring/equipping, loot, repairs, and junk settings
  -- stay separate. Reward selection waits for the player's native confirmation.
  db.questReading={mode='read-first',appliedAt=date('%Y-%m-%d %H:%M:%S'),
    rxp=profile and profile.enableQuestAutomation==false or false,
    loreward=LorewardDB and LorewardDB.settings.questAutomation=='manual' or false,
    autoGear=AutoGearDB and not AutoGearDB.AutoCompleteItemQuests or false}
end
frame:RegisterEvent('PLAYER_LOGIN')
frame:RegisterEvent('PLAYER_ENTERING_WORLD')
frame:SetScript('OnEvent',function()
  apply()
  C_Timer.After(2,apply)
end)
