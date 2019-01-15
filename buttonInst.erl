%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. Dec 2018 13:22
%%%-------------------------------------------------------------------
-module(buttonInst).
-author("Changizi").

%% API
-export([create/5, init/5, switch_on/1, switch_off/1, is_on/1, flow_influence/1]).
% -export([commission/1, activate/1]).
% -export([deactivate/1, decommission/1]).

% Pump is a pipe and more; this pipe instance is passed to the create function.
% RealWorldCmdFn is a function to transfer commands to the real-world pump.

create(Host, ButtonTyp_Pid, WireInst_Pid, BCM, RealWorldCmdFn) -> {ok, spawn(?MODULE, init, [Host, ButtonTyp_Pid, WireInst_Pid, BCM, RealWorldCmdFn])}.

init(Host, ButtonTyp_Pid, WireInst_Pid, BCM, RealWorldCmdFn) ->
  {ok, State} = apply(resource_type, get_initial_state, [ButtonTyp_Pid, self(), [WireInst_Pid, BCM, RealWorldCmdFn]]),
  %  get_initial_state  (ResTyp_Pid,  ResInst_Pid, TypeOptions)
  survivor:entry({ buttonInst_created, State }),
  erlang:send_after(1500, self(), readValue),
  loop(Host, State, ButtonTyp_Pid, WireInst_Pid).

read_button(ButtonInst_Pid) ->
  ButtonInst_Pid ! readValue.

switch_off(ButtonInst_Pid) ->
  ButtonInst_Pid ! switchOff.

switch_on(ButtonInst_Pid) ->
  ButtonInst_Pid ! switchOn.

is_on(ButtonInst_Pid) ->
  msg:get(ButtonInst_Pid, isOn).

flow_influence(ButtonInst_Pid) ->
  msg:get(ButtonInst_Pid, get_flow_influence).


loop(Host, State, ButtonTyp_Pid, WireInst_Pid) ->
  %read_button(self()),
  receive
    {subscribe, ListIds, ReplyFn} ->
      #{subs := ListId} = State,
      ListSubscribers = lists:append(ListIds, ListId),
      NewState = maps:put(subs, ListSubscribers, State),
      survivor:entry({ buttonInst_subsPids, NewState }),
      ReplyFn(NewState),
      loop(Host, NewState, ButtonTyp_Pid, WireInst_Pid);
    readValue ->
      {ok, NewState} = msg:set_ack(ButtonTyp_Pid, readValue, State),
      #{butValue := OldValue} = State, #{butValue := NewValue} = NewState,
      check(OldValue, NewValue, NewState),
      erlang:send_after(1500, self(), readValue),
      loop(Host, NewState, ButtonTyp_Pid, WireInst_Pid);
    switchOn ->
      #{bcmPin := Pin, subs := SubsList, count := N} = State,
      case Pin of
        22 ->
          case N of
            _ when N < 8 ->
              N1 = N +1,
              io:format("N1 ~p~n", [N1]),
              %io:format("N1 ~p~n", [SubsList]),
              set_counter_resources(SubsList, N1),
              %msg:set_ack(Res_Inst, switchOn),
              NewState = maps:update(count, N1, State),
              loop(Host, NewState, ButtonTyp_Pid, WireInst_Pid);
            Otherwise ->
              N1 = 0,
              io:format("Butvalue ~p~n", [Otherwise]),
              NewState = maps:update(count, N1, State),
              loop(Host, NewState, ButtonTyp_Pid, WireInst_Pid)
          end;
        21 ->
          loop(Host, State, ButtonTyp_Pid, WireInst_Pid)
      end;

      %{ok, NewState} = msg:set_ack(Res_Inst, switchOn),
  %survivor:entry({ buttonInst_updated, NewState }),
    switchOff ->
      {ok, NewState} = msg:set_ack(ButtonTyp_Pid, switchOff, State),
      survivor:entry({ buttonInst_updated, NewState }),
      loop(Host, NewState, ButtonTyp_Pid, WireInst_Pid);
    {isOn, ReplyFn} ->
      {ok, Answer} = msg:get(ButtonTyp_Pid, on_or_off, State),
      ReplyFn(Answer),
      loop(Host, State, ButtonTyp_Pid, WireInst_Pid);
    {get_type, ReplyFn} ->
      ReplyFn(ButtonTyp_Pid),
      loop(Host, State, ButtonTyp_Pid, WireInst_Pid);
    {get_flow_influence, ReplyFn} ->
      {ok, InfluenceFn} = msg:get(ButtonTyp_Pid, flow_influence, State),
      ReplyFn(InfluenceFn),
      loop(Host, State, ButtonTyp_Pid, WireInst_Pid);
    OtherMessage ->
      WireInst_Pid ! OtherMessage,
      loop(Host, State, ButtonTyp_Pid, WireInst_Pid)
  end.

check(OldValue ,NewValue, NewState) when OldValue /= NewValue ->
  case NewValue of
    1 ->
      io:format("Butvalue ~p~n", [NewValue]),
      survivor:entry({ buttonInst_updated, NewState }),
      switch_on(self()),
      timer:sleep(1000);
    Otherwise ->
      survivor:entry({ buttonInst_updated, NewState }),
      io:format("Butvalue ~p~n", [Otherwise])
  end;
check(OldValue ,NewValue, NewState) when OldValue == NewValue ->
  ok.


set_counter_resources(X, N1) ->
  [LedThrees, LedTwos, LedOnes] = X,
  <<Threes:1, Twos:1, Ones:1>> = <<N1:3>>,
  msg:set_ack(LedThrees, counter, Threes),
  msg:set_ack(LedTwos, counter,  Twos),
  msg:set_ack(LedOnes, counter, Ones),
  io:format(", , , ~p ~p ~p ~n", [Threes, Twos, Ones]).







