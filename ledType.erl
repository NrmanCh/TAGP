%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. Dec 2018 09:14
%%%-------------------------------------------------------------------
-module(ledType).
-author("Changizi").

%% API
-export([create/0, init/0, gpio/1]).

create() -> {ok, spawn(?MODULE, init, [])}.

init() ->
  survivor:entry(ledTyp_created),
  loop().

loop() ->
  receive

%    get_initial_state, self(), RealWorldCmdFn: de functie die de echte hardware aanstuurt
    {initial_state, [ResInst_Pid, [WireInst_Pid, BCM, RealWorldCmdFn]], ReplyFn} ->
      Output = RealWorldCmdFn({init, BCM}),
      ReplyFn(#{resInst => ResInst_Pid, wireInst => WireInst_Pid, bcmPin => BCM,
        rw_cmd => RealWorldCmdFn, on_or_off => off, outputInst => Output, ledValue => 0}),
      loop();
    {switchOff, State, ReplyFn} ->
       #{outputInst := Output, rw_cmd := ExecFn} = State,
       NewLedVal = ExecFn({write, Output, 0}),
      ReplyFn(State#{on_or_off := on, ledValue := NewLedVal}),
      loop();
    {switchOn, State, ReplyFn} ->
      #{outputInst := Output, rw_cmd := ExecFn} = State,
      NewLedVal = ExecFn({write, Output, 1}),
      ReplyFn(State#{on_or_off := on, ledValue := NewLedVal}),
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
  {ok, L0} = gpio:start_init(BCM, out),
  timer:sleep(200),
  %{ok, B1} = gpio:start_init(22, in),
  L0;
gpio({write, Output, Value}) ->
  LedValue = gpio:write(Output, Value),
  %timer:sleep(1000),
  %gpio:write(Output, 0),
  LedValue.
