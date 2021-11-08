%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(test).   
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("kernel/include/logger.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([start/0]). 


%% ====================================================================
%% External functions
%% ====================================================================


%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start()->
    io:format("~p~n",[{"Start setup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=setup(),
    io:format("~p~n",[{"Stop setup",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start pass_0()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=pass_0(),
    io:format("~p~n",[{"Stop pass_0()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   
      %% End application tests
    io:format("~p~n",[{"Start cleanup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cleanup(),
    io:format("~p~n",[{"Stop cleaup",?MODULE,?FUNCTION_NAME,?LINE}]),
   
    io:format("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------


%    ?LOG_EMERGENCY(StringOrReport[,Metadata])
%    ?LOG_EMERGENCY(FunOrFormat,Args[,Metadata])
%    ?LOG_ALERT(StringOrReport[,Metadata])
%    ?LOG_ALERT(FunOrFormat,Args[,Metadata])
%    ?LOG_CRITICAL(StringOrReport[,Metadata])
%    ?LOG_CRITICAL(FunOrFormat,Args[,Metadata])
%    ?LOG_ERROR(StringOrReport[,Metadata])
%    ?LOG_ERROR(FunOrFormat,Args[,Metadata])
%    ?LOG_WARNING(StringOrReport[,Metadata])
%    ?LOG_WARNING(FunOrFormat,Args[,Metadata])
%    ?LOG_NOTICE(StringOrReport[,Metadata])
%    ?LOG_NOTICE(FunOrFormat,Args[,Metadata])
%    ?LOG_INFO(StringOrReport[,Metadata])
%    ?LOG_INFO(FunOrFormat,Args[,Metadata])
%    ?LOG_DEBUG(StringOrReport[,Metadata])
%    ?LOG_DEBUG(FunOrFormat,Args[,Metadata])
%    ?LOG(Level,StringOrReport[,Metadata])
%    ?LOG(Level,FunOrFormat,Args[,Metadata])

pass_0()->
  %  ok=test_clean_create_dirs(),
  %  ok=test_start_vms(),
  %  ok=test_clone_infra(),
    
    
    ok=application:start(compute),
    io:format("sd:all ~p~n",[sd:all()]),
    io:format("nodes ~p~n",[nodes()]),
    StringOrReport="First test",
    Metadata=#{pid => self(),
	       gl => self(),
	       time => time(),
	       mfa => {?MODULE,?FUNCTION_NAME,2},
	       file => "test.erl",
	       line => ?LINE,
	       msg=>"glurk msh\n"},
  %  ?LOG_ERROR(StringOrReport,Metadata),
    ?LOG_ALERT(Metadata),
    ?LOG_WARNING(Metadata),
    ?LOG_NOTICE(Metadata),
    
   % ?LOG_INFO(#{ what => http_error, status => 418, src => ?MODULE, dst => glurk }),					
    ok.



    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
clone()->
    {ok,I}=file:consult("infra_app.config"),    
    StartList=proplists:get_value(applications_to_start,I),
    CloneList=[{AppId,AppId,GitPath}||{AppId,_Vsn,GitPath}<-StartList],
    clone(CloneList,[]).

clone([],R)->
    R;
clone([{Dir,Application,GitPath}|T],Acc)->
    io:format("{Dir,Application,GitPath ~p~n",[{Dir,Application,GitPath}]),
    AppDir=filename:join(Dir,Application),
    case filelib:is_dir(AppDir) of
	true->
	    os:cmd("rm -rf "++AppDir);
	false->
	    ok
    end,
    ok=file:make_dir(AppDir),
    
    R=os:cmd("git clone "++GitPath++" "++AppDir),
    Ebin=filename:join(AppDir,"ebin"),
    %check if app file is present 
    
    AppFile=filename:join([Ebin,Application++".app"]),
    true=filelib:is_file(AppFile),
    clone(T,[{ok,Application,Ebin}|Acc]).



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
clean_create_dir(Dir,Keep)->
    %Keep [Files or DirNames]
    Result=case filelib:is_dir(Dir) of
	       false->
		   file:make_dir(Dir),
		   {ok,[created,Dir]};
	       true-> %Clean up 
		   {ok,FileNames}=file:list_dir(Dir),
		   FilesToRemove=[filename:join(Dir,FileName)||FileName<-FileNames,
							       false=:=lists:member(FileName,Keep)],
		   [os:cmd("rm -rf "++FileToRemove)||FileToRemove<-FilesToRemove],
		   {ok,[clean_up,FilesToRemove]}
	   end,
    Result.


    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

spawn_vm(StartList)->
    F1=fun spawn_vm/2,
    F2=fun check/3,
    StartResult=mapreduce:start(F1,F2,[],StartList),
    Result=case [Node||{ok,Node}<-StartResult] of
	       []->
		   {ok,StartResult};
	       Nodes->
		   [{net_kernel:connect_node(Node),Node}||Node<-Nodes]
	   end,
    Result. 

spawn_vm(Parent,{Host,Name,Args})->
    X=slave:start(Host,Name,Args),
 %   io:format("X ~p~n",[X]),
    Parent!{spawn_vm,X}.

check(spawn_vm,Vals,_)->
    check(Vals,[]).
check([],Result)->
    Result;
check([StartResult|T],Acc)->
    check(T,[StartResult|Acc]).
 

   
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
test_clone_infra()->
    
    [{ok,"sd","sd/sd/ebin"},
     {ok,"controller","controller/controller/ebin"}]=clone(),
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

test_start_vms()->
    {ok,I}=file:consult("boot.config"),    
    NodesToStart=proplists:get_value(nodes_to_start,I),
    SortedStart=lists:sort(spawn_vm(NodesToStart)),
    [{true,'1@c100'},
     {true,'2@c100'},
     {true,'3@c100'},
     {true,'4@c100'},
     {true,'5@c100'},
     {true,'6@c100'},
     {true,'7@c100'},
     {true,'8@c100'},
     {true,'9@c100'}, 
     {true,controller@c100},
     {true,dbase@c100},
     {true,sd@c100}]=SortedStart,

    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
test_clean_create_dirs()->
    {ok,I}=file:consult("boot.config"),    
    % create vm dirs
    NodesToStart=proplists:get_value(nodes_to_start,I),
   
    Dirs=[Dir||{_Host,Dir,Args}<-NodesToStart],
    Dirs=["1","2","3","4","5","6","7","8","9","controller","sd","dbase"],

    NodesToStart=[{"c100","1","-setcookie cookie"},
		  {"c100","2","-setcookie cookie"},
		  {"c100","3","-setcookie cookie"},
		  {"c100","4","-setcookie cookie"},
		  {"c100","5","-setcookie cookie"},
		  {"c100","6","-setcookie cookie"},
		  {"c100","7","-setcookie cookie"},
		  {"c100","8","-setcookie cookie"},
		  {"c100","9","-setcookie cookie"},
		  {"c100","controller","-setcookie cookie"},
		  {"c100","sd","-setcookie cookie"},
		  {"c100","dbase","-setcookie cookie"}],

%    io:format("NodesToStart ~p~n",[NodesToStart]),

%    io:format("Dirs ~p~n",[Dirs]),
    Keep=["logs"],
    CCD1=[clean_create_dir(Dir,Keep)||Dir<-Dirs],
    [{ok,[created,"1"]},
     {ok,[created,"2"]},
     {ok,[created,"3"]},
     {ok,[created,"4"]},
     {ok,[created,"5"]},
     {ok,[created,"6"]},
     {ok,[created,"7"]},
     {ok,[created,"8"]},
     {ok,[created,"9"]},
     {ok,[created,"controller"]},
                               {ok,[created,"sd"]},
                               {ok,[created,"dbase"]}]=CCD1,
    
    [file:make_dir(filename:join(Dir,"glurk1"))||Dir<-Dirs],
    [file:make_dir(filename:join(Dir,"glurk2"))||Dir<-Dirs],

    [file:make_dir(filename:join(Dir,"logs"))||Dir<-Dirs],

    Dirs1=[file:list_dir_all(Dir)||Dir<-Dirs],
    Dirs1=[{ok,["glurk2","logs","glurk1"]},
             {ok,["glurk2","logs","glurk1"]},
             {ok,["glurk2","logs","glurk1"]},
             {ok,["glurk2","logs","glurk1"]},
             {ok,["glurk2","logs","glurk1"]},
             {ok,["glurk2","logs","glurk1"]},
             {ok,["glurk2","logs","glurk1"]},
             {ok,["glurk2","logs","glurk1"]},
             {ok,["glurk2","logs","glurk1"]},
             {ok,["glurk2","logs","glurk1"]},
             {ok,["glurk2","logs","glurk1"]},
             {ok,["glurk2","logs","glurk1"]}],
    

 %   io:format("List dir 1  ~p~n",[[file:list_dir_all(Dir)||Dir<-Dirs]]),
    
    CCD2=[clean_create_dir(Dir,Keep)||Dir<-Dirs],
    [{ok,[clean_up,["1/glurk2","1/glurk1"]]},
     {ok,[clean_up,["2/glurk2","2/glurk1"]]},
     {ok,[clean_up,["3/glurk2","3/glurk1"]]},
     {ok,[clean_up,["4/glurk2","4/glurk1"]]},
     {ok,[clean_up,["5/glurk2","5/glurk1"]]},
     {ok,[clean_up,["6/glurk2","6/glurk1"]]},
     {ok,[clean_up,["7/glurk2","7/glurk1"]]},
     {ok,[clean_up,["8/glurk2","8/glurk1"]]},
     {ok,[clean_up,["9/glurk2","9/glurk1"]]},
     {ok,[clean_up,["controller/glurk2","controller/glurk1"]]},
     {ok,[clean_up,["sd/glurk2","sd/glurk1"]]},
     {ok,[clean_up,["dbase/glurk2","dbase/glurk1"]]}]=CCD2,
    
    
    [{ok,["logs"]},
             {ok,["logs"]},
             {ok,["logs"]},
             {ok,["logs"]},
             {ok,["logs"]},
             {ok,["logs"]},
             {ok,["logs"]},
             {ok,["logs"]},
             {ok,["logs"]},
             {ok,["logs"]},
             {ok,["logs"]},
             {ok,["logs"]}]=[file:list_dir_all(Dir)||Dir<-Dirs],

   
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass1()->
   
    
    ok.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_2()->
    
     ok.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

setup()->
 %   {ok,I}=file:consult("boot.config"), 
   
    % create vm dirs
 %   NodesToStart=proplists:get_value(nodes_to_start,I),
   
 %   Dirs=[Dir||{_Host,Dir,Args}<-NodesToStart],
 %   Dirs=["1","2","3","4","5","6","7","8","9","controller","sd","dbase"],
 %   [os:cmd("rm -rf "++Dir)||Dir<-Dirs],   
   ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------    

cleanup()->
  
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
