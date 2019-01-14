%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Nov 2018 13:51
%%%-------------------------------------------------------------------
-module(msg).
-author("Changizi").

%% API

-define(TimeOut, 5000).
-export([get/2, get/3, set_ack/2, set_ack/3]).
-export([test/0]).

get(Pid, Key) ->
  Pid ! {Key, replier(R = make_ref())},
  receive
    {R, Info} -> {ok, Info}
  after ?TimeOut -> {error, timed_out, Pid, Key, R}
  end.

get(Pid, Key, P_list) ->
  io:format("im here in msg~n"),
  Pid ! {Key, P_list, replier(R = make_ref())},
  receive
    {R, Info} -> {ok, Info}
  after ?TimeOut -> {error, timed_out, Pid, Key, R}
  end.

set_ack(Pid, Key) -> % identical to get; for readability only.
  Pid ! {Key, replier(R = make_ref())},
  receive
    {R, Info} -> {ok, Info}
  after ?TimeOut -> {error, timed_out, Pid, Key, R}
  end.

set_ack(Pid, Key, P_list) -> % identical to get; for readability only.
  Pid ! {Key, P_list, replier(R = make_ref())},
  receive
    {R, Info} -> {ok, Info}
  after ?TimeOut -> {error, timed_out, Pid, Key, R}
  end.

replier(Ref) -> %%closure maken, je geeft een functie mee naar de ontvanger, zodat die een antw terug geeft naar de zender.
  Sender = self(),
  fun(Msg) -> Sender ! {Ref, Msg} end.

test() ->
  Pid = spawn(fun() -> receive {_Dummy, [P | _ ], F } -> F(2 * P) end, ok end),
  msg:set_ack(Pid, dummy, [10]).
