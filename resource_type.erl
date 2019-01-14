%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Nov 2018 13:55
%%%-------------------------------------------------------------------
-module(resource_type).
-author("Changizi").

%% API
-export([]).

-export([create/2]).
-export([get_initial_state/3, get_connections_list/2, get_locations_list/2, get_condition_list/2]).

create(Selector, ParameterList) ->
  % e.g. called as follows:
  %   create(Module, func, [Arguments of function]
  % 	resource_type:create(pipeTyp, []).
  %
  % resource type creation must select a specific type
  % creation of an abstract (partially defined) type is
  % not possible. Returns {ok, ResTyp_Pid}.
  apply(Selector, create, ParameterList).

get_initial_state(ResTyp_Pid, ResInst_Pid, TypeOptions) ->	%%TypeOptions is a list
  io:format("ResType: ~p and ResInst: ~p ~n", [ResTyp_Pid, ResInst_Pid]),
  msg:get(ResTyp_Pid, initial_state, [ResInst_Pid, TypeOptions]).
%	{ok, State} = resource_type:get_initial_state(ResTyp_Pid, self(), []),

get_connections_list(ResTyp_Pid, State) ->
  msg:get(ResTyp_Pid, connections_list, State).

get_locations_list(ResTyp_Pid, State) ->
  msg:get(ResTyp_Pid, locations_list, State).

get_condition_list(ResTyp_Pid, State) ->
  msg:get(ResTyp_Pid, condition_list, State).

