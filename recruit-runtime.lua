return function(a,root,emit)
 math.randomseed(os.time());local E=assert(loadfile(root..'recruit-engine.ljbc'))()
 local pools={};local by={}
 for _,cfg in pairs(package_package) do
  if type(cfg)=='table' and cfg.ID and cfg.money_id then
   local cards={};for _,c in pairs(package_package_cards) do if c.name==cfg.package_id then
 if c.card_type==1 and heros_heros[c.card_id] then cards[#cards+1]={id=c.card_id,kind=1,quality=heros_heros[c.card_id].quality}
 elseif c.card_type==2 and skills_skills[c.card_id] then cards[#cards+1]={id=c.card_id,kind=2,quality=skills_skills[c.card_id].quality+2} end end end
   if #cards>0 and not by[cfg.ID] then local p={id=cfg.ID,cfg=cfg,cards=cards};pools[#pools+1]=p;by[p.id]=p end
  end
 end
 local qs={};for _,p in ipairs(pools)do for _,c in ipairs(p.cards)do local k=c.kind..':'..tostring(c.quality);qs[k]=(qs[k]or 0)+1 end end;for k,v in pairs(qs)do emit('RARITY_VALUE '..k..' count='..v)end
 table.sort(pools,function(x,y)return x.id<y.id end)
 local s=E.new(pools,1000000);assert(#pools>1,'No usable client pools');local selected=1;local last='Rates 8/30/62; hero/skill 50/50; gold within 20';local names={}
 local function name(id,kind)local skill=kind==CommonConst.RecruitCardType.Skill;local c=(skill and skills_skills or heros_heros)[id];return (skill and '[Skill] ' or '[Hero] ')..tostring(c and c.name or id)end
 local function save()local f=assert(io.open(root..'recruit-save.json','w'));f:write(rapidJson.encode({balance=s.balance,selected=s.selected,inventory=(function()local r={};for k,v in pairs(s.inventory)do r[tostring(k)]=v end;return r end)(),history=s.history,nextId=s.nextId,pity=s.pity,rulesVersion=2}));f:close()end
 local f=io.open(root..'recruit-save.json','r');if f then local ok,d=pcall(rapidJson.decode,f:read('*a'));f:close();if ok and type(d)=='table' then s.pity=d.pity or {};s.balance=d.balance or s.balance;s.inventory={};for _,c in ipairs(d.history or {})do local key=tostring(c.cardType)..':'..tostring(c.cardID);s.inventory[key]=(s.inventory[key] or 0)+1 end;s.history=d.history or {};s.nextId=d.nextId or s.nextId;s:select(d.selected);for i,p in ipairs(pools)do if p.id==s.selected then selected=i end end end end
 local packages={};for _,p in ipairs(pools) do local c=p.cfg;packages[#packages+1]={packageId=p.id,packageType=c.type,guaranteedCount=0,lastFreeTime=0,lastDiscountTime=0,totaldDrawCount=0,openTimestamp=1,mergedPackageIds={},blacklist={},banCard={},selectList={},wishList={},wishGuaranteed=0,remainExchangeTime=0,midCount=0,seasonExchangeTime=0} end
 a:InitRecruitLoginData({RecruitComp={packageList=packages}});rawset(a,'GetGlobalMinHeroLevel',function()return 1 end)
 rawset(a,'CheckMingJiangCanFree',function()return false end);rawset(a,'CheckMingJiangCanDiscount',function()return false end)
 rawset(a,'GetNextGuaranteedCount',function(self,id)return 20-(s.pity[tostring(id)]or 0)end)
 local complete=0;for _,p in ipairs(pools)do if p.complete then complete=complete+1 end end;emit('WEIGHTED_READY complete='..complete..' total='..#pools)
 local oldMoney=a.GetMoneyById;rawset(a,'GetMoneyById',function(self,id,...)if id==7 then return s.balance end;return oldMoney(self,id,...)end)
 local function refresh()pcall(function()GameEvent:Fire('ON_MONEY_CHANGED')end)end
 local function grant(cards)
  for _,c in ipairs(cards) do
   if c.cardType==CommonConst.RecruitCardType.Skill then
    local data={skillId=c.cardID,level=1,userList={},orderLevel=0,skillSkinInfo={},customComp={},featureCacheList={},stateList={}}
    local ok,e=xpcall(function()a:RPCNotifySkillResponse(0,{skillList={data}});assert(a:GetAvatarSkillBySkillID(c.cardID),'Missing skill')end,debug.traceback);emit('SKILL_GRANT '..c.cardID..' '..tostring(ok)..' '..tostring(e))
   else
   local cfg=heros_heros[c.cardID]
   local data={ID=c.cardUniqueID,heroID=c.cardID,level=1,index=c.cardUniqueID,exp=0,wound_num=0,max_troop_num=100,army_troop_num=0,troop_num=0,skillList={},buff_list={},heroAPData={},evolutionLevel=0,wakeupIDList={},warbookLock={},energy=100,exEnergy=0,energyRTime=os.time(),lUEnergyTimes=0,heroStateList={},equipments={},armsAdvancedSkillList={},extraAPPointData={},heroSkinInfo={},enlighten=0,knotFate=0,groupSwitch=0,proposeFeatures={},customFeatures={},customAttr={},customTalents={},armsAdvancedId=0,validEndTime=0}
   local ok,e=xpcall(function()a:RPCNotifyHeroResponse(0,{heroList={data}})end,debug.traceback);emit('HERO_GRANT '..c.cardID..' '..tostring(ok)..' '..tostring(e))
   end
  end
 end
 grant(s.history);emit('RESTORED_HERO_COUNT '..tostring(#a.heroList))

 local function draw(id,count)
  local cards,e=s:draw(id,count);if not cards then last=e;emit('RECRUIT_REJECT '..tostring(e));return end
  grant(cards);local d=a:GetPackageData(id);if d then d.totaldDrawCount=d.totaldDrawCount+count;d.guaranteedCount=s.pity[tostring(id)]or 0 end
  local text={};for _,c in ipairs(cards)do text[#text+1]=tostring(name(c.cardID,c.cardType)) end;last=table.concat(text,' / ');save();refresh();emit('LOCAL_DRAW pool='..id..' count='..count..' balance='..s.balance..' '..last)
  local ok,e=xpcall(function()local r=UIMgr:GetUIByName('RecruitHeroUI');if r and r:IsShow() then r:SetPackageId(id);r:ShowGetCard(cards) else UIMgr:ShowUI('RecruitHeroUI',function(ui)ui:SetPackageId(id);ui:SetInitCards(cards)end)end end,debug.traceback);emit('RECRUIT_ANIMATION '..tostring(ok)..' '..tostring(e))
  return cards
 end
 rawset(a,'ClientReqRecruit',function(self,id,count)return draw(id,count or 1)end);rawset(a,'RPCRecruit',function(self,id,count)return draw(id,count or 1)end);rawset(a,'RPCGetRecruitInfo',function()emit('LOCAL_RECRUIT_INFO')end)
 local U=CS.UnityEngine;local UI=U.UI;local go=U.GameObject('OfflineRecruitGM');U.Object.DontDestroyOnLoad(go);local canvas=go:AddComponent(typeof(U.Canvas));canvas.renderMode=U.RenderMode.ScreenSpaceOverlay;canvas.sortingOrder=32760;go:AddComponent(typeof(UI.GraphicRaycaster));local scaler=go:AddComponent(typeof(UI.CanvasScaler));scaler.uiScaleMode=UI.CanvasScaler.ScaleMode.ScaleWithScreenSize;scaler.referenceResolution=U.Vector2(1280,720)
 local font=U.Resources.GetBuiltinResource(typeof(U.Font),'Arial.ttf')
 local function obj(n,x,y,w,h,parent)local g=U.GameObject(n);g.transform:SetParent(parent or go.transform,false);local r=g:AddComponent(typeof(U.RectTransform));r.anchorMin=U.Vector2(0,1);r.anchorMax=U.Vector2(0,1);r.pivot=U.Vector2(0,1);r.anchoredPosition=U.Vector2(x,-y);r.sizeDelta=U.Vector2(w,h);return g end
 local panel=obj('GM Panel',10,70,460,305);local bg=panel:AddComponent(typeof(UI.Image));bg.color=U.Color(0.06,0.07,0.1,0.96)
 local function label(n,x,y,w,h)local g=obj(n,x,y,w,h,panel.transform);local t=g:AddComponent(typeof(UI.Text));t.font=font;t.fontSize=17;t.color=U.Color.white;t.supportRichText=false;t.raycastTarget=false;return t end
 local title=label('Title',10,5,440,27);title.text='OFFLINE GM - 8/30/62 - pity 20'
 local poolText=label('Pool',10,37,440,45);local balance=label('Balance',10,84,440,25);local result=label('Results',10,193,440,105)
 local hitButtons={}
 local function button(n,x,y,w,fn,parent)local g=obj(n,x,y,w,32,parent or panel.transform);local im=g:AddComponent(typeof(UI.Image));im.color=U.Color(0.25,0.3,0.4,1);local b=g:AddComponent(typeof(UI.Button));b.targetGraphic=im;local child=obj(n..' Text',0,0,w,32,g.transform);local t=child:AddComponent(typeof(UI.Text));t.raycastTarget=false;t.font=font;t.fontSize=16;t.color=U.Color.white;t.alignment=U.TextAnchor.MiddleCenter;t.text=n;hitButtons[#hitButtons+1]={rect=g:GetComponent(typeof(U.RectTransform)),name=n,run=fn};return b end
 local function update()local p=pools[selected];poolText.text='Pool '..p.id..' / group '..p.cfg.package_id..' / season '..table.concat(p.cfg.season or {},'-')..' / total '..#p.cards;balance.text='Local gold: '..s.balance..'   Saved draws: '..#s.history;result.text=last end
 local function selectPool(i)
 selected=i;s:select(pools[i].id);save();local ui=UIMgr:GetUIByName('RecruitUI');if ui and ui:IsShow()then ui.nowSelectCardPackageId=s.selected;ui:RefreshPanelData()end;update();emit('GM_POOL '..s.selected..' group='..pools[i].cfg.package_id)
 end
 button('Prev pool',10,114,105,function()selectPool((selected-2)%#pools+1)end)
 button('Next pool',125,114,105,function()selectPool(selected%#pools+1)end)
 button('+100000',240,114,100,function()s:setBalance(s.balance+100000);save();refresh();update()end)
 button('Draw 1',10,154,105,function()draw(s.selected,1);update()end)
 button('Draw 5',125,154,105,function()draw(s.selected,5);update()end)
 button('Open recruit',240,154,200,function()UIMgr:ShowUI('RecruitUI');update()end)
 local visible=true;button('GM',10,28,65,function()visible=not visible;panel:SetActive(visible)end,go.transform)
 update();emit('GM_READY pools='..#pools..' balance='..s.balance)
 local smoke=io.open(root..'recruit-smoke.flag','r');local testing=smoke~=nil;if smoke then smoke:close() end;local ticks=0
 local testFlag=io.open(root..'mixed-test.flag','r');local mixedTest=testFlag~=nil;if testFlag then testFlag:close()end
 local function tick()
  ticks=ticks+1
  if mixedTest and ticks==240 then
   for _,p in ipairs(pools)do local h,k=0,0;for _,c in ipairs(p.cards)do if c.kind==CommonConst.RecruitCardType.Skill then k=k+1 else h=h+1 end end;if h>0 and k>0 then emit('MIXED_TEST_POOL '..p.id..' heroes='..h..' skills='..k);draw(p.id,20);break end end
  end
  if U.Input.GetMouseButtonUp(0) then
   local pos=U.Input.mousePosition
   for i=#hitButtons,1,-1 do local b=hitButtons[i];if b.rect.gameObject.activeInHierarchy and U.RectTransformUtility.RectangleContainsScreenPoint(b.rect,U.Vector2(pos.x,pos.y),nil)then
    emit('GM_MOUSE '..b.name);local ok,e=xpcall(b.run,debug.traceback);if not ok then emit('GM_ERROR '..tostring(e))end;break
   end end
  end
  if ticks%60==0 then
   local ui=UIMgr:GetUIByName('RecruitUI');if ui and ui:IsShow() and ui.nowSelectCardPackageId~=s.selected and by[ui.nowSelectCardPackageId]then
    for i,p in ipairs(pools)do if p.id==ui.nowSelectCardPackageId then selected=i;s:select(p.id);save();emit('UI_POOL '..p.id..' group='..p.cfg.package_id);break end end
   end;update()
  end
  if not testing then return end
  local action=({[240]='Next pool',[300]='+100000',[360]='Draw 1',[420]='Draw 5',[540]='Open recruit'})[ticks]
  if action then emit('SMOKE_CLICK '..action);local g=go.transform:Find('GM Panel/'..action);assert(g,'Missing GM button');g:GetComponent(typeof(UI.Button)).onClick:Invoke() end
  if ticks==660 then local ui=UIMgr:GetUIByName('RecruitUI');emit('ORIGINAL_DRAW_BUTTON');if ui then ui:OnBtn5BtnClick() end end
  
  if ticks==480 or ticks==1500 then U.ScreenCapture.CaptureScreenshot(root..'recruit-smoke-'..ticks..'.png');emit('SMOKE_STATE balance='..s.balance..' history='..#s.history..' selected='..s.selected) end
 end
 return {state=s,draw=draw,update=update,root=go,tick=tick}
end

