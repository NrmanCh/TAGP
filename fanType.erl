%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. Dec 2018 09:14
%%%-------------------------------------------------------------------
-module(fanType).
-author("Changizi").

%% API
-export([create/0, init/0]).

create() -> {ok, spawn(?MODULE, init, [])}.

init() ->
  survivor:entry(fanTyp_created),
  loop().

loop() ->
  receive

%    get_initial_state, self(), RealWorldCmdFn: de functie die de echte hardware aanstuurt
    {initial_state, [ResInst_Pid, [PipeInst_Pid, RealWorldCmdFn]], ReplyFn} ->
      ReplyFn(#{resInst => ResInst_Pid, pipeInst => PipeInst_Pid,
        rw_cmd => RealWorldCmdFn, on_or_off => off}),
      loop();
    {switchOff, State, ReplyFn} ->
      #{rw_cmd := ExecFn} = State, ExecFn(off),
      ReplyFn(State#{on_or_off := off}),
      loop();
    {switchOn, State, ReplyFn} ->
      #{rw_cmd := ExecFn} = State, ExecFn(on),
      ReplyFn(State#{on_or_off := on}),
      loop();
    {on_or_off, State, ReplyFn} ->
      #{on_or_off := OnOrOff} = State,
      ReplyFn(OnOrOff),
      loop();
    {flow_influence, State, ReplyFn} ->
      #{on_or_off := OnOrOff} = State,
      io:format("OnOrOff ~p~n", [OnOrOff]),
      FlowInfluenceFn = fun(Flow) -> flow(Flow, OnOrOff) end, % placeholder only.
      ReplyFn(FlowInfluenceFn),
      loop()
  end.

flow(Flow, on)  ->
  (250 - 5 * Flow - 2 * Flow * Flow);
flow(_Flow, off) -> 0.
