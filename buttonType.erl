%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. Dec 2018 13:21
%%%-------------------------------------------------------------------
-module(buttonType).
-author("Changizi").

%% API
-export([create/0, init/0, gpio/1]).

create() -> {ok, spawn(?MODULE, init, [])}.

init() ->
  survivor:entry(buttonTyp_created),
  loop().

loop() ->
  receive

%    get_initial_state, self(), RealWorldCmdFn: de functie die de echte hardware aanstuurt
    {initial_state, [ResInst_Pid, [WireInst_Pid, BCM, RealWorldCmdFn]], ReplyFn} ->
      Output = RealWorldCmdFn({init, BCM}),
      ReplyFn(#{resInst => ResInst_Pid, wireInst => WireInst_Pid, bcmPin => BCM,
        subs => [], rw_cmd => RealWorldCmdFn, on_or_off => off, outputInst => Output, 
        btnValue => 0, count => 0}),
      loop();
    {readValue, State, ReplyFn} ->
      #{outputInst := Output, rw_cmd := ExecFn} = State,
      NewValue = list_to_integer(ExecFn({readButton, Output})),
      ReplyFn(State#{btnValue := NewValue}),
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

gpio({init, BCM}) ->
  %{ok, L0} = gpio:start_init(4, out),
  {ok, B1} = gpio:start_init(BCM, in),
  B1;
gpio({readButton, Output}) ->
  Btnvalue = gpio:read(Output),
  Btnvalue.
