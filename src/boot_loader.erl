%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(boot_loader).  
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%%---------------------------------------------------------------------
%% Records for test
%%
-define(BootConfig,"boot.config").
-define(InfraAppConfig,"infra_app.config").

%% --------------------------------------------------------------------
%-compile(export_all).
-export([initial_boot/0]).

%% ====================================================================
%% External functions
%% ====================================================================
initial_boot()-> 
    {ok,CleanCreateDirsResult}=clean_app_dirs(),
%    {ok,StartVmList}=start_vms(),
    {ok,CloneInfo}=clone(),
    {ok,StartInfo}=start_infra_apps(CloneInfo),
    {ok,ConnectedNodes}=connect(),    
    {ok,[ConnectedNodes,StartInfo,CloneInfo,CleanCreateDirsResult]}.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
connect()->
    {ok,I}=file:consult(?BootConfig),   
    NodesToConnect=proplists:get_value(nodes_to_contact,I),
    R=[{net_kernel:connect_node(Node),Node}||Node<-NodesToConnect],
    {ok,R}.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
start_infra_apps(CloneInfo)->
    AppAndEbin=[{list_to_atom(AppId),Ebin}||{ok,AppId,Ebin,_GitInfo}<-CloneInfo],
    {ok,start_app(AppAndEbin)}.

start_app(AppAndEbin)->
    start_app(AppAndEbin,[]).

start_app([],StartResult)->
    StartResult;
start_app([{Application,undefined}|T],Acc)->
    start_app(T,[{{error,[undefined]},Application}|Acc]);
start_app([{Application,Ebin}|T],Acc)->   
    true=rpc:call(node(),code,add_patha,[Ebin],2000),
    R=rpc:call(node(),application,start,[Application],3*5000),
    start_app(T,[{R,Application,Ebin}|Acc]).

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
clean_app_dirs()->
    {ok,I}=file:consult(?InfraAppConfig),    
    AppsToStart=proplists:get_value(applications_to_start,I),
    RemovedDirs=[{AppId,os:cmd("rm -rf "++ AppId)}||{AppId,_Vsn,_GitPath}<-AppsToStart],
    {ok,RemovedDirs}.
			      

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
clone()->
    {ok,I}=file:consult(?InfraAppConfig),    
    StartList=proplists:get_value(applications_to_start,I),
    {ok,clone(StartList,[])}.

clone([],R)->
    R;
clone([{Application,_Vsn,GitPath}|T],Acc)->
    AppDir=Application,
    case filelib:is_dir(AppDir) of
	true->
	    os:cmd("rm -rf "++AppDir);
	false->
	    ok
    end,
    ok=file:make_dir(AppDir),
    
    GitInfo=os:cmd("git clone "++GitPath++" "++AppDir),
    Ebin=filename:join(AppDir,"ebin"),
    %check if app file is present 
    
    AppFile=filename:join([Ebin,Application++".app"]),
    true=filelib:is_file(AppFile),
    clone(T,[{ok,Application,Ebin,GitInfo}|Acc]).


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
