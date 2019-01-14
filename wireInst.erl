%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. Dec 2018 13:51
%%%-------------------------------------------------------------------
-module(wireInst).
-author("Changizi").

%% API
-export([]).
-export([create/2, init/2, flow_influence/1]).


create(Host, ResTyp_Pid) -> {ok, spawn(?MODULE, init, [Host, ResTyp_Pid])}.

init(Host, ResTyp_Pid) ->
  {ok, State} = apply(resource_type, get_initial_state, [ResTyp_Pid, self(), []]),
%%  {ok, State} = resource_type:get_initial_state(ResTyp_Pid, self(), []),
  survivor:entry({ wireInst_created, State }),
  loop(Host, State, ResTyp_Pid).

flow_influence(WireInst_Pid) ->
  msg:get(WireInst_Pid, get_flow_influence).

loop(Host, State, ResTyp_Pid) ->
  receive
    {get_connectors, ReplyFn} ->
      {ok,C_List} = resource_type:get_connections_list(ResTyp_Pid, State),
      ReplyFn(C_List),
      loop(Host, State, ResTyp_Pid);
    {get_locations, ReplyFn} ->
      {ok, List} = resource_type:get_locations_list(ResTyp_Pid, State),
      ReplyFn(List),
      loop(Host, State, ResTyp_Pid);
    {get_type, ReplyFn} ->
      ReplyFn(ResTyp_Pid),
      loop(Host, State, ResTyp_Pid);
    {get_ops, ReplyFn} ->
      ReplyFn([]),
      loop(Host, State, ResTyp_Pid);
    {get_state, ReplyFn} ->
      ReplyFn(State),
      loop(Host, State, ResTyp_Pid);
    {get_flow_influence, ReplyFn} ->
      {ok, InfluenceFn} = msg:get(ResTyp_Pid, flow_influence, State),
      ReplyFn(InfluenceFn),
      loop(Host, State, ResTyp_Pid)
  end.
