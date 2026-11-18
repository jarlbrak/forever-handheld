-- Regression test for patches/RXPGuides: run against a patched RXPGuides/GuideWindow.lua.
-- Usage: lua tests/patches/test-rxp-guidewindow.lua path/to/GuideWindow.lua
local function readSection(path, start, finish)
 local file=assert(io.open(path))
 local text=file:read('*a'):gsub('\r\n','\n');file:close()
 local first=assert(text:find(start,1,true))
 local last=assert(text:find(finish,first+#start,true))
 return text:sub(first,last-1)
end

local combat=true
function InCombatLockdown()return combat end
local guideEvents
function CreateFrame()
 local frame={registers=0}
 function frame:RegisterEvent(name)self.event=name;self.registers=self.registers+1 end
 function frame:IsEventRegistered(name)return self.event==name end
 function frame:UnregisterEvent()self.event=nil end
 function frame:SetScript(_,callback)self.callback=callback end
 guideEvents=frame
 return frame
end
local bottom={height=0,shown=true,changes=0}
function bottom:GetHeight()return self.height end
function bottom:IsShown()return self.shown end
function bottom:Hide()assert(not combat);self.shown=false;self.changes=self.changes+1 end
function bottom:Show()assert(not combat);self.shown=true;self.changes=self.changes+1 end
local root={height=22}
function root:GetHeight()return self.height end
function root:SetHeight(height)assert(not combat);self.height=height end
local rxp={v2={IsGuideWindowEnabled=function()return false end},settings={profile={frameHeight=75}}}
local layout=readSection(arg[1],'local guideLayoutEvents = CreateFrame','function BottomFrame.UpdateFrame')
local loadLayout=assert(loadstring('local BottomFrame,RXPFrame,addon=...\n'..layout..'\nreturn updateGuideWindowSize'))
local update=loadLayout(bottom,root,rxp)
update();update()
assert(guideEvents.event=='PLAYER_REGEN_ENABLED' and guideEvents.registers==1 and bottom.changes==0 and root.height==22)
combat=false;guideEvents.callback(guideEvents)
assert(not guideEvents.event and not bottom.shown and root.height==28)
combat=true;update();bottom.height=52;combat=false;guideEvents.callback(guideEvents)
assert(bottom.shown and root.height==75 and guideEvents.registers==2)
print('PASS: protected RestedXP geometry coalesces in combat and applies current guide state on exit')

local currentStep={height=31,shown=true}
function currentStep:GetHeight()return self.height end
function currentStep:IsShown()return self.shown end
function currentStep:SetHeight(height)assert(not combat);self.height=height end
function currentStep:SetShown(shown)assert(not combat);self.shown=shown end
local stepGeometry=readSection(arg[1],'local stepLayoutEvents = CreateFrame','function CurrentStepFrame.UpdateText')
local loadStep=assert(loadstring('local CurrentStepFrame=...\n'..stepGeometry..'\nreturn applyStepGeometry'))
local applyStep=loadStep(currentStep)
combat=true;applyStep(43,true);applyStep(58,true)
assert(guideEvents.event=='PLAYER_REGEN_ENABLED' and guideEvents.registers==1 and currentStep.height==31)
combat=false;guideEvents.callback(guideEvents)
assert(not guideEvents.event and currentStep.shown and currentStep.height==58)
combat=true;applyStep(0,false);combat=false;guideEvents.callback(guideEvents)
assert(not currentStep.shown and currentStep.height==0 and guideEvents.registers==2)
print('PASS: RestedXP current-step geometry defers both legacy and alternate display changes')

local moveStarts,resizeStarts,stops,anchors,saves,updates=0,0,0,0,0,0
local alt=false
function IsAltKeyDown()return alt end
function root:StartMoving()assert(not combat);moveStarts=moveStarts+1 end
function root:StartSizing()assert(not combat);resizeStarts=resizeStarts+1 end
function root:StopMovingOrSizing()assert(not combat);stops=stops+1 end
function root:SetScript(_,script)assert(not combat);self.script=script end
root.BottomFrame={UpdateFrame=function()end}
function rxp.GetGuideProgress()return 17 end
function rxp.SetStep(step)assert(step==17 and not combat);updates=updates+1 end
function rxp.UpdateItemFrame()assert(not combat)end
function rxp.settings:SaveFramePositions()assert(not combat);saves=saves+1 end
local mouseLayout=readSection(arg[1],'local layoutButton, isResizing, mouseReleaseEvents','RXPFrame:SetScript("OnMouseDown", RXPFrame.OnMouseDown)')
local loadMouse=assert(loadstring('local RXPFrame,addon,SetStepFrameAnchor=...\n'..mouseLayout))
loadMouse(root,rxp,function()assert(not combat);anchors=anchors+1 end)
combat=true
root:OnMouseDown('LeftButton');root:OnMouseUp('LeftButton')
assert(moveStarts==0 and stops==0 and anchors==0 and saves==0,'combat clicks touched protected guide geometry')
combat=false;rxp.settings.profile.lockFrames=true
root:OnMouseDown('LeftButton');root:OnMouseUp('LeftButton')
assert(moveStarts==0 and stops==0 and saves==0,'locked guide click changed layout')
rxp.settings.profile.lockFrames=false
root:OnMouseDown('LeftButton');root:OnMouseUp('RightButton')
assert(moveStarts==1 and stops==0,'unrelated release ended the active drag')
root:OnMouseUp('LeftButton')
assert(stops==1 and anchors==1 and saves==1,'normal drag did not finalize')
root:OnMouseDown('LeftButton',true);assert(resizeStarts==1 and root.script==root.BottomFrame.UpdateFrame)
combat=true;root:OnMouseUp('LeftButton');root:OnMouseUp('LeftButton')
assert(guideEvents.event=='PLAYER_REGEN_ENABLED' and guideEvents.registers==1 and stops==1 and saves==1,'release did not defer exactly once')
combat=false;guideEvents.callback(guideEvents)
assert(not guideEvents.event and not root.script and stops==2 and anchors==2 and saves==2 and updates==1,'deferred resize did not finalize')
root:OnMouseUp('LeftButton');assert(stops==2 and saves==2,'unmatched release repeated the saved layout update')
print('PASS: RestedXP suppresses combat and locked drags, finalizes only matching releases, and defers an interrupted resize until combat ends')
