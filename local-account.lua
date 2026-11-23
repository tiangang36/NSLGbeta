local root='C:/Users/Administrator/Documents/Codex/2026-11-22/1-2-rea-3-4-computeruse/outputs/offline-login/'
local out=assert(io.open(root..'local-session.log','w'))
local function emit(x) out:write(tostring(x)..string.char(10));out:flush() end
local function step(name,f) emit('BEGIN '..name);local ok,res=xpcall(f,debug.traceback);emit('END '..name..' '..tostring(ok)..' '..tostring(res));return ok,res end
SDKMgr.Login=function() emit('SDK login suppressed for local test') end
SDKMgr.OneSDK_Login=SDKMgr.Login
local main=LuaMain
local old=main.Update
local frames=0;local errorSeen={}
main.Update=function(...)
 local args={...}
 local ok,err=xpcall(function() return old(unpack(args)) end,debug.traceback)
 if not ok and not errorSeen[tostring(err)] then errorSeen[tostring(err)]=true;emit('UPDATE_ERROR '..tostring(err)) end
 if rawget(_G,'OFFLINE_RECRUIT') then local ok,e=pcall(OFFLINE_RECRUIT.tick);if not ok then emit('RECRUIT_TICK_ERROR '..tostring(e))end end
 frames=frames+1
 if frames==300 or frames==600 then if frames==300 then CS.UnityEngine.ScreenCapture.CaptureScreenshot(root..'offline-main-scene.png') end;local loading=UIMgr:GetUIByName('LoadingUI');if loading then emit('LOADING_STATE '..tostring(loading.loadingState)) end;emit('SCENE_STATUS '..tostring(SceneController:GetCurSceneName())..' avatar='..tostring(ClientProxy:GetAvatarId()));for _,n in ipairs({'MainUI','LoginUI','LoadingUI','TopBarUI'}) do local ui=UIMgr:GetUIByName(n);emit('UI '..n..' '..tostring(ui and ui:IsShow())) end end;if frames~=90 then return end
 emit('DEFERRED_INIT');local marker=io.open(root..'offline-ready.flag','w');marker:write('ready');marker:close()
 local account=ClientProxy
 if not step('scenario',function() account:InitScenarioCfg({scenarioId=1,seasonId=1,openServerTimestamp=1}) end) then return end
 local a
 if not step('avatar',function() G_UNGuardGlobals();require('Proxy.Avatar');G_GuardGlobals();local gm=require('Proxy.AvatarMembers.ImpGM');gm.InitGMData=function() end;a=Avatar.New();rawset(_G,'LOCAL_TEST_AVATAR',a) end) then return end
 step('local identity',function()
  local coord=MapHelper:GetIntByCoord(100,100);emit('LOCAL_CITY_COORD '..tostring(coord));local city={cityCoord=coord,isRebirth=false,cityId=900000001,buildId=900000001,cityLevel=1,armyTeamList={},armyTeamIdList={},armyTeams={},heroList={},constructionList={},buildInfo={},cityBuildInfo={},cityConstruction={},cityInfo={},buildings={},createTimestamp=os.time(),constructionInfo={}};rawset(a,'CityComp',city);rawset(a,'mainCityCoord',{coord=coord});rawset(a,'personalInfo',{createTimestamp=os.time(),avatarId=900000001,name='LocalTester',serverId=0,level=1});rawset(a,'createTimestamp',os.time());rawset(a,'accountCreateTime',os.time());local vals={avatarId=900000001,name='LocalTester',avatarName='LocalTester',accountName='offline_test',serverId=0,accountType=0,loginTimestamp=os.time(),timestamp=os.time(),openServerTimestamp=1,chapterId=1,hasAvatarInit=true,inPreReq=false}
  for k,v in pairs(vals) do rawset(a,k,v) end
  for k,v in pairs(vals) do if type(a.__PTB)=='table' then rawset(a.__PTB,k,v) end end
  for _,k in ipairs({'myArmyIdList','myHubenArmyIdListMp','myOtherIdList','globalViewVehicleIdsMap','remoteControlledVehicleIdList'}) do rawset(a,k,{}) end
  rawset(a,'CallServer',function(self,n,args) emit('LOCAL_RPC '..tostring(n)) end)
  rawset(a,'IsAvatar',function() return true end)
  rawset(a,'IsAccount',function() return false end)
  rawset(a,'GetServerId',function() return 0 end)
  rawset(a,'GetAvatarId',function() return 900000001 end)
  rawset(a,'GetAvatarName',function() return 'LocalTester' end)
  rawset(a,'IsOutMainCityDone',function() return true end)
  rawset(a,'IsSDKState',function() return false end)
  global_declare('ClientProxy',a)
 end)
 step('recruit state',function() a:InitRecruitLoginData({RecruitComp={packageList={}}}) end)
 step('offline recruit',function()local runtime=assert(loadfile(root..'recruit-runtime.ljbc'))()(a,root,emit);rawset(_G,'OFFLINE_RECRUIT',runtime)end)
 step('local database',function() account:InitNslgDb(900000001) end)
 step('close login interface',function() UIMgr:HideUI('NoticeUI');UIMgr:HideUI('LoginUI');UIMgr:HideUI('LoginLoadingUI') end)
 step('currency and helpers',function() local uiModule=require('UI.Control.NewsTickerUIController');local orig=uiModule.__OnUpdateComp__;uiModule.__OnUpdateComp__=function(self,...) if self.tickerPlayers==nil then self.tickerPlayers={} end;return orig(self,...) end end);step('switch scene',function() SceneController:SwitchTargetScene(CommonConst.GlobalSceneName.NSLG) end)
 emit('SCENE_REQUESTED '..tostring(SceneController:GetCurSceneName()))
end
emit('DEFERRED_HOOK_INSTALLED '..type(main)..' '..type(old))

