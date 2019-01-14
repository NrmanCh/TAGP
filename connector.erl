%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Nov 2018 13:48
%%%-------------------------------------------------------------------
-module(connector).
-author("Changizi").

%% API
-export([]).

-export([create/2, connect/2, disconnect/1, discard/1]).
-export([get_connected/1, get_ResInst/1, get_type/1]).

-export([init/2, test/0]). % for internal use only.

%%  ResInst_Pid : waar ben ik een connector van, ConnectTyp_Pid: wat is mijn conn_type
create(ResInst_Pid, ConnectTyp_Pid) ->
  spawn(?MODULE, init, [ResInst_Pid, ConnectTyp_Pid]).

init(ResInst_Pid, ConnectTyp_Pid) ->
  survivor:entry({connector_created_for, ResInst_Pid}),
  loop(ResInst_Pid, disconnected, ConnectTyp_Pid).

connect(Connector_Pid, C_Pid) ->
  Connector_Pid ! {connect, C_Pid}.

disconnect(Connector_Pid) ->
  Connector_Pid ! disconnect.

get_connected(Connector_Pid) ->
  msg:get(Connector_Pid, get_connected).

get_ResInst(Connector_Pid) ->
  msg:get(Connector_Pid, get_ResInst).


get_type(Connector_Pid) ->
  msg:get(Connector_Pid, get_type ).


discard(Connector_Pid) ->
  Connector_Pid ! discard.

% Connectors do not survive their ResInst, nor do they
% move/change from one ResInst to another.
%  dwz, dat een connector gemaakt wordt samen met een pijp

loop(ResInst_Pid, Connected_Pid, ConnectTyp_Pid) ->
  receive
    {connect, C_Pid} -> % Pid van de connector dat je mee wilt connecten
      survivor:entry({connection_made, self(), C_Pid, for , ResInst_Pid}),
      loop(ResInst_Pid, C_Pid, ConnectTyp_Pid);
    disconnect ->
      loop(ResInst_Pid, disconnected, ConnectTyp_Pid);
    {get_connected, ReplyFn} ->
      ReplyFn(Connected_Pid),
      loop(ResInst_Pid, Connected_Pid, ConnectTyp_Pid);
    {get_ResInst, ReplyFn} ->
      ReplyFn(ResInst_Pid),
      loop(ResInst_Pid, Connected_Pid, ConnectTyp_Pid);
    {get_type, ReplyFn} ->
      ReplyFn(ConnectTyp_Pid),
      loop(ResInst_Pid, Connected_Pid, ConnectTyp_Pid);
    discard ->
      survivor:entry(connector_discarded),
      stopped
  end.

test() ->
  C1_Pid = create(self(), dummy1_pid),
  C2_Pid = create(self(), dummy2_pid),
  connect(C1_Pid, C2_Pid),
  {C1_Pid, C2_Pid}.
