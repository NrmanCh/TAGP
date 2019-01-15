%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. Nov 2018 11:10
%%%-------------------------------------------------------------------
-module(currentFlowType).
-author("Changizi").

%% API
-export([create/0, init/0, discover_circuit/2, get_resource_circuit/2]).


create() -> {ok, spawn(?MODULE, init, [])}.

init() ->
survivor:entry(currentFlowType_created),
loop().

get_resource_circuit(TypePid, State) ->
  msg:get(TypePid, resource_circuit, State).

loop() ->
  receive
    {initial_state, [ResInst_Pid, [Root_ConnectorPid, TypeOptions]], ReplyFn} ->
      {ok, C} = discover_circuit(Root_ConnectorPid, ResInst_Pid),
      
      ReplyFn(#{resInst => ResInst_Pid, circuit => C, typeOptions => TypeOptions}),
      loop();
    {connections_list, _State , ReplyFn} ->
      ReplyFn([]),
      loop();
    {locations_list, _State, ReplyFn} ->
      ReplyFn([]),
      loop();
    {resource_circuit, State, ReplyFn} ->
      #{circuit := C} = State,
      {_RootC, CircuitMap} = C,
      ReplyFn(extract(CircuitMap)),
      loop()
  end.


extract(C) -> 
  maps:fold(
      fun(K, V, ResLoop = #{}) ->
		%io:format("~p: ~p~n", [K, V]),
		{ok, ResPid} = connector:get_ResInst(K),
		%io:format("ResPid: ~p~n", [ResPid]),
		ResLoop#{ResPid => processed}
	  end, #{}, C).
	  
	  
discover_circuit(Root_Pid, ResInst_Pid) ->
  %% insert Root_ConnectorPid and create a map
  {ok,  Circuit} = discover_circuit([Root_Pid], #{ }, ResInst_Pid),
  {ok,  {Root_Pid, Circuit}}.

%% Do pattern matching on 'disconnected'. Circuit is the map
discover_circuit([ disconnected | Todo_List], Circuit, ResInst_Pid) ->
  %io:format("Circuits 1 ~p~n", [Circuit]),
  discover_circuit(Todo_List, Circuit, ResInst_Pid);

%% If a connector is connected, it has Pid
discover_circuit([C | Todo_List], Circuit, ResInst_Pid) ->
  %io:format("C ~p , Todo_list ~p , Circuit ~p ~n", [C, Todo_List, Circuit]),
  {ok, Updated_Todo_list, Updated_Circuit} =
    %% process_connection returns an Updated_Todo_list and Updated_Circuit
  process_connection(C, maps:find(C, Circuit ), Todo_List, Circuit, ResInst_Pid),
  %io:format("Updated_Todo_list: ~p , Updated_Circuit: ~p ~n", [Updated_Todo_list, Updated_Circuit]),
  discover_circuit(Updated_Todo_list, Updated_Circuit, ResInst_Pid);

%% when all the connectors have been seen
discover_circuit([], Circuit, ResInst_Pid) ->
  { ok, Circuit }.

%% check with 'error' on the map if C hasent been processed
process_connection(C, error, Todo_List, Circuit, ResInst_Pid) ->
  %io:format("in process_connection: C  ~p , Todo_list ~p , Circuit ~p ~n", [C, Todo_List, Circuit]),
  Updated_Circuit = Circuit#{ C => processed },
  %%retrieve the connected pid off the current connector
  {ok, CC} = connector:get_connected(C),
  %io:format("CC: ~p ~n", [CC]),
  %add he connected pid off the current connector to the list
  Updated_Todo_list = [ CC | Todo_List],
  %io:format("Updated_Todo_list: ~p ~n", [Updated_Todo_list]),
  %retrieve the ResPid and C_list of the current connector
  {ok, ResPid} = connector:get_ResInst(C),
  {ok, C_list} = resource_instance:list_connectors(ResPid),
  
  {ok, [Location_ResPid|_]} = resource_instance:list_locations(ResPid),
  location:arrival(Location_ResPid, ResInst_Pid),
  
  %add the current C_list with
  {ok, C_list ++  Updated_Todo_list, Updated_Circuit};
%% if C has already been processed, take the tail of Todo_List
process_connection( _, _ , Todo_List, Circuit, ResInst_Pid) ->
  {ok, Todo_List, Circuit}.
