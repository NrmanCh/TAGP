%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Nov 2018 13:55
%%%-------------------------------------------------------------------
-module(survivor).
-author("Changizi").

%% API
%%-export([]).

-export([start/0, entry/1, init/0]).

start() ->
  (whereis(survivor) =:= undefined) orelse unregister(survivor),
  register(survivor, spawn(?MODULE, init, [])).

entry(Data)->
  ets:insert(logboek, {{now(), self()}, Data}).

init() ->
  (ets:info(logboek) =:= undefined) orelse ets:delete(logboek),
  ets:new(logboek, [named_table, ordered_set, public]),
  loop().

loop() ->
  receive
    stop -> ok
  end.

