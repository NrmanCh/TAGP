%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. Dec 2018 09:23
%%%-------------------------------------------------------------------
-module(ledInst).
-author("Changizi").

%% API
-export([create/5, init/5, switch_on/1, switch_off/1, is_on/1, flow_influence/1]).
% -export([commission/1, activate/1]).
% -export([deactivate/1, decommission/1]).

% Pump is a pipe and more; this pipe instance is passed to the create function.
% RealWorldCmdFn is a function to transfer commands to the real-world pump.

create(Host, LedTyp_Pid, WireInst_Pid, BCM, RealWorldCmdFn) -> {ok, spawn(?MODULE, init, [Host, LedTyp_Pid, WireInst_Pid, BCM, RealWorldCmdFn])}.

init(Host, LedTyp_Pid, WireInst_Pid, BCM, RealWorldCmdFn) ->
  {ok, State} = apply(resource_type, get_initial_state, [LedTyp_Pid, self(), [WireInst_Pid, BCM, RealWorldCmdFn]]),
  %  get_initial_state  (ResTyp_Pid,  ResInst_Pid, TypeOptions)
  survivor:entry({ ledInst_created, State }),
  loop(Host, State, LedTyp_Pid, WireInst_Pid).

switch_off(LedInst_Pid) ->
  LedInst_Pid ! switchOff.

switch_on(LedInst_Pid) ->
  LedInst_Pid ! switchOn.

is_on(LedInst_Pid) ->
  msg:get(LedInst_Pid, isOn).

flow_influence(LedInst_Pid) ->
  msg:get(LedInst_Pid, get_flow_influence).


loop(Host, State, LedTyp_Pid, WireInst_Pid) ->
  receive
    {counter, Status, ReplyFn} ->
    case Status of
    1 -> {ok, NewState} = msg:set_ack(LedTyp_Pid, switchOn, State);
    0 -> {ok, NewState} = msg:set_ack(LedTyp_Pid, switchOff, State)
    end,
    survivor:entry({ ledInst_updated, NewState }),
    ReplyFn(NewState),
    loop(Host, NewState, LedTyp_Pid, WireInst_Pid);
    {switchOn, ReplyFn} ->
      {ok, NewState} = msg:set_ack(LedTyp_Pid, switchOn, State),
      ReplyFn(NewState),
      survivor:entry({ ledInst_updated, NewState }),
      loop(Host, NewState, LedTyp_Pid, WireInst_Pid);
    switchOn ->
      {ok, NewState} = msg:set_ack(LedTyp_Pid, switchOn, State),
      survivor:entry({ ledInst_updated, NewState }),
      loop(Host, NewState, LedTyp_Pid, WireInst_Pid);
    switchOff ->
      {ok, NewState} = msg:set_ack(LedTyp_Pid, switchOff, State),
      survivor:entry({ ledInst_updated, NewState }),
      loop(Host, NewState, LedTyp_Pid, WireInst_Pid);
    {isOn, ReplyFn} ->
      {ok, Answer} = msg:get(LedTyp_Pid, on_or_off, State),
      ReplyFn(Answer),
      loop(Host, State, LedTyp_Pid, WireInst_Pid);
    {get_type, ReplyFn} ->
      ReplyFn(LedTyp_Pid),
      loop(Host, State, LedTyp_Pid, WireInst_Pid);
    {get_flow_influence, ReplyFn} ->
      {ok, InfluenceFn} = msg:get(LedTyp_Pid, flow_influence, State),
      ReplyFn(InfluenceFn),
      loop(Host, State, LedTyp_Pid, WireInst_Pid);
    OtherMessage ->
      WireInst_Pid ! OtherMessage,
      loop(Host, State, LedTyp_Pid, WireInst_Pid)
  end.
