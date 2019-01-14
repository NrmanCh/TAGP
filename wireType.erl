%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. Dec 2018 13:50
%%%-------------------------------------------------------------------
-module(wireType).
-author("Changizi").

%% API
-export([]).
-export([create/0, init/0]). % More to be added later.

create() -> {ok, spawn(?MODULE, init, [])}.

init() ->
  survivor:entry(wireTyp_created),
  loop().

loop() ->
  receive
    {initial_state, [ResInst_Pid, TypeOptions], ReplyFn} ->
      %io:format("im here in recieve intial state~n"),
      Location = location:create(ResInst_Pid, emptySpace),
      In = connector:create(ResInst_Pid, simpleWire),
      Out = connector:create(ResInst_Pid, simpleWire),
      ReplyFn(#{resInst => ResInst_Pid, chambers => [Location],
        cList => [In, Out], typeOptions => TypeOptions}),
      loop();
    {connections_list, State , ReplyFn} ->
      #{cList := C_List} = State, ReplyFn(C_List),
      loop();
    {locations_list, State, ReplyFn} ->
      #{chambers := L_List} = State, ReplyFn(L_List),
      loop();
    {flow_influence, _State, ReplyFn} ->
      FlowInfluenceFn = fun(Flow) -> flow(Flow) end, % placeholder only.
      ReplyFn(FlowInfluenceFn),
      loop()
  end.

flow(N) -> - 0.01 * N.
