%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. Dec 2018 09:23
%%%-------------------------------------------------------------------
-module(fanInst).
-author("Changizi").

%% API
-export([create/5, init/5, switch_on/1, switch_off/1, is_on/1, flow_influence/1]).
% -export([commission/1, activate/1]).
% -export([deactivate/1, decommission/1]).

% Pump is a pipe and more; this pipe instance is passed to the create function.
% RealWorldCmdFn is a function to transfer commands to the real-world pump.

create(Host, FanTyp_Pid, WireInst_Pid, BCM, RealWorldCmdFn) -> {ok, spawn(?MODULE, init, [Host, FanTyp_Pid, WireInst_Pid, BCM, RealWorldCmdFn])}.

init(Host, FanTyp_Pid, WireInst_Pid, BCM, RealWorldCmdFn) ->
  {ok, State} = apply(resource_type, get_initial_state, [FanTyp_Pid, self(), [WireInst_Pid, BCM, RealWorldCmdFn]]),
  %  get_initial_state  (ResTyp_Pid,  ResInst_Pid, TypeOptions)
  survivor:entry({ fanInst_created, State }),
  loop(Host, State, FanTyp_Pid, WireInst_Pid).
  
  
switch_off(FanInst_Pid) ->
  FanInst_Pid ! switchOff.

switch_on(FanInst_Pid) ->
  FanInst_Pid ! switchOn.

is_on(FanInst_Pid) ->
  msg:get(FanInst_Pid, isOn).

flow_influence(FanInst_Pid) ->
  msg:get(FanInst_Pid, get_flow_influence).


loop(Host, State, FanTyp_Pid, WireInst_Pid) ->
  receive
    {switchOn, ReplyFn} ->
      {ok, NewState} = msg:set_ack(FanTyp_Pid, switchOn, State),
      io:format("Fan set on ~n"),
      survivor:entry({ fanInst_updated, NewState }),
      ReplyFn(NewState),
      loop(Host, NewState, FanTyp_Pid, WireInst_Pid);
    {switchOff, ReplyFn}->
      {ok, NewState} = msg:set_ack(FanTyp_Pid, switchOff, State),
      io:format("Fan set off ~n"),
      survivor:entry({ fanInst_updated, NewState }),
      ReplyFn(NewState),
      loop(Host, NewState, FanTyp_Pid, WireInst_Pid);
    {isOn, ReplyFn} ->
      {ok, Answer} = msg:get(FanTyp_Pid, on_or_off, State),
      ReplyFn(Answer),
      loop(Host, State, FanTyp_Pid, WireInst_Pid);
    {get_type, ReplyFn} ->
      ReplyFn(FanTyp_Pid),
      loop(Host, State, FanTyp_Pid, WireInst_Pid);
    {get_flow_influence, ReplyFn} ->
      {ok, InfluenceFn} = msg:get(FanTyp_Pid, flow_influence, State),
      ReplyFn(InfluenceFn),
      loop(Host, State, FanTyp_Pid, WireInst_Pid);
    OtherMessage ->
      WireInst_Pid ! OtherMessage,
      loop(Host, State, FanTyp_Pid, WireInst_Pid)
  end.
