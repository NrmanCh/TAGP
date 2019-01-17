%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Nov 2018 13:54
%%%-------------------------------------------------------------------
-module(resource_instance).
-author("Changizi").

%% API
-export([create/2]).
-export([list_connectors/1, list_locations/1]).
-export([get_type/1, get_ops/1, get_state/1, set_state/2, get_flow_influence/1]).
-export([ form_list/0, set_condition/1, connect/1, connect/3, subscribe/2, disconnect/1]).
%%% More to follow later.

create(Selector, Environment) ->
  apply(Selector, create, Environment).
% returns {ok, ResInst_Pid}

list_connectors(ResInst_Pid)	->
  msg:get(ResInst_Pid, get_connectors).

list_locations(ResInst_Pid)	-> % ResInst is hosting
  msg:get(ResInst_Pid, get_locations).

get_type(ResInst_Pid) -> % allows to retrieve state-agnostic information
  msg:get(ResInst_Pid, get_type).

get_ops(ResInst_Pid) -> % list of commands available in the current state
  % Does not lock the resource state; list may change at any time
  msg:get(ResInst_Pid, get_ops).

get_state(ResInst_Pid) -> % current state understood by type (only)
  % Does not lock the resource state; may change at any time
  msg:get(ResInst_Pid, get_state).
  
set_state(ResInst_Pid, NewState) -> % current state understood by type (only)
  % Does not lock the resource state; may change at any time
  msg:set_ack(ResInst_Pid, set_state, NewState).

set_condition(ResInst_Pid) -> % list of commands available in the current state
  msg:get(ResInst_Pid, set_condition).
  
get_flow_influence(ResInst_Pid) -> 
	msg:get(ResInst_Pid, get_flow_influence).
  
subscribe(ResourceInst_Pid, ResourceInst_pid_Sub) ->
  msg:set_ack(ResourceInst_Pid, subscribe, ResourceInst_pid_Sub).

%%	ResInst_Pid_list = all the pids of the wireInst's.
connect(ResInst_Pid_list) ->
  connect(hd(ResInst_Pid_list), tl(ResInst_Pid_list), hd(ResInst_Pid_list)).

connect(T, [], FirstValue)->
  {ok,ConList_FirstVal} = list_connectors(FirstValue),  %fetch this wire insts connect pid
  {ok,ConList_T} = list_connectors(T),  %fetch this wire insts connect pid
  connector:connect(hd(ConList_FirstVal),lists:last(ConList_T)), % connect p1 out to p2 in
  connector:connect(lists:last(ConList_T),hd(ConList_FirstVal)),  % connect p2 in to p1 out
  io:format("connecting: ~p to ~p ~n",[hd(ConList_FirstVal),lists:last(ConList_T)]); 

connect(A,[B|BS], FirstItem)->
  {ok,ConList_A} = list_connectors(A),  %fetch this wire insts connect pid
  {ok,ConList_B} = list_connectors(B),  %fetch this wire insts connect pid
  connector:connect(lists:last(ConList_A),hd(ConList_B)), % connect p1 out to p2 in
  connector:connect(hd(ConList_B),lists:last(ConList_A)), % connect p2 in to p1 out
  io:format("connecting: ~p to ~p ~n",[lists:last(ConList_A),hd(ConList_B)]),
  connect(B,BS, FirstItem).

%%Disconnect all 
disconnect(L) ->
  disconnect(L, []).
disconnect([A|B], Acc) ->
  {ok,ConList_A} = list_connectors(A),  %fetch this wire insts connect pid
  ResInst_Pid_list = lists:append(ConList_A, Acc),
  disconnect(B, ResInst_Pid_list);
disconnect([], ResInst_Pid_list) ->
   io:format("disconnecting: ~p~n",[ResInst_Pid_list]),
  [connector:disconnect(X) || X <- ResInst_Pid_list ].


%%	to create a list of the ets-table
form_list()->
  form_list(ets:first(logboek),[]).
form_list(Key,List)->
  if Key =/= '$end_of_table' ->
    [{_,Beschrijving}] = ets:lookup(logboek,Key),
    Lijst = insert(Beschrijving,List),
    form_list(ets:next(logboek,Key),Lijst);
    true -> List
  end.

insert(X,[])->[X];
insert(X,[Y|YS])-> [Y,insert(X, YS)].

%%keys(TableName) ->
%%  FirstKey = ets:first(TableName),
%%  keys(TableName, FirstKey, [FirstKey]).
%%
%%keys(_TableName, '$end_of_table', ['$end_of_table'|Acc]) ->
%%  Acc;
%%keys(TableName, CurrentKey, Acc) ->
%%  NextKey = ets:next(TableName, CurrentKey),
%%  keys(TableName, NextKey, [NextKey|Acc]).
