%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%% Based on the Paolo Oliveira's:
%%% A simple, pure erlang implementation of a module for <b>Raspberry Pi's General Purpose
%%% Input/Output</b> (GPIO), using the standard Linux kernel interface for user-space, sysfs,
%%% available at <b>/sys/class/gpio/</b>.
%%% source: https://github.com/paoloo/gpio
%%% Modified to a gen_server, by Changizi
%%% @end
%%% Created : 09. Dec 2018 15:54
%%%-------------------------------------------------------------------
-module(gpio).
-author("Changizi").
-behaviour(gen_server).

%% API
-export([start_init/2, stop/1, read/1, write/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).


start_init(Pin, Direction) ->
  {ok, ServerPid} = gen_server:start_link(?MODULE, {Pin, Direction}, []).

% @doc: Stop using and release the Pin referenced as file descriptor Ref.
stop(ServerPid) ->
  gen_server:call(ServerPid, {stop}).

% @doc: Read from an initialized Pin referenced as the file descriptor Ref.
read(ServerPid) ->
  gen_server:call(ServerPid, {recv}).

% @doc: Write value Val to an initialized Pin referenced as the file descriptor Ref.
write(ServerPid, Val) ->
  gen_server:call(ServerPid, {send, Val}).



%%% gen_server callbacks

init({Pin, Direction}) ->
  %survivor:entry(pipeTyp_created),
  Ref = configure(Pin, Direction),
  %RefPWM = configurePWM0(),
  %io:format("RefPWM: ~p~n", [RefPWM]),
  survivor:entry(gpio_gen_server_created),
  {ok, #{pin=>Pin, ref=>Ref}}.  %%initialize State with a map


handle_call({send, Val}, _From, #{ref :=Ref}=State)->
  file:position(Ref, 0),
  file:write(Ref, integer_to_list(Val)),
  {reply, State, State};

handle_call({recv}, _From, #{ref :=Ref}=State)->
  file:position(Ref, 0),
  {ok, Data} = file:read(Ref, 1),
  {reply, Data, State};

handle_call(terminate, _From, State) ->
  {stop, normal, ok, State}.

handle_cast({stop}, #{ref :=Ref, pin :=Pin}=State) ->
  file:close(Ref),
  release(Pin),
  {noreply, State}.

terminate(normal, _State) ->
  io:format("Server shutdown ~n"),
  ok.

handle_info(Msg, State) ->
  io:format("Unexpected message: ~p~n",[Msg]),
  {noreply, State}.

code_change(_OldVsn, State, _Extra) ->
%% No change planned. The function is there for the behaviour,
%% but will not be used. Only a version on the next
  {ok, State}.




%%% Internal functions
configure(Pin, Direction) ->

  DirectionFile = "/sys/class/gpio/gpio" ++ integer_to_list(Pin) ++ "/direction",

  % Export the GPIO pin
  {ok, RefExport} = file:open("/sys/class/gpio/export", [append]),
  file:write(RefExport, integer_to_list(Pin)),
  file:close(RefExport),

  % It can take a moment for the GPIO pin file to be created.
  case filelib:is_file(DirectionFile) of
    true -> ok;
    false -> receive after 1000 -> ok end
  end,

  {ok, RefDirection} = file:open(DirectionFile, [append]),
  case Direction of
    in -> file:write(RefDirection, "in");
    out -> file:write(RefDirection, "out")
  end,
  file:close(RefDirection),
  {ok, RefVal} = file:open("/sys/class/gpio/gpio" ++ integer_to_list(Pin) ++ "/value", [read, write]),
  RefVal. %% RefVal is a process, controls the open file

release(Pin) ->
  {ok, RefUnexport} = file:open("/sys/class/gpio/unexport", [append]),
  file:write(RefUnexport, integer_to_list(Pin)),
  file:close(RefUnexport).

configurePWM0() ->
  % Export the GPIO18 pin
  {ok, RefExportPWM} = file:open("/sys/class/pwm/pwmchip0/export", [append]),
  file:write(RefExportPWM, integer_to_list(0)),
  file:close(RefExportPWM),
  DirectionFilePWM = "sys/class/pwm/pwmchip0/pwm0",
  % It can take a moment for the GPIO pin file to be created.
  case filelib:is_file(DirectionFilePWM) of
    true -> ok;
    false -> receive after 1000 -> ok end
  end,
  {ok, RefPeriod} = file:open("sys/class/pwm/pwmchip0/pwm0/period", [read, write]),
  RefPeriod, %% RefPeriod is a process, controls the open file
  {ok, RefDutyCycle} = file:open("sys/class/pwm/pwmchip0/pwm0/duty_cycle", [read, write]),
  RefDutyCycle, %% RefDutyCycle is a process, controls the open file
  {ok, RefEnable} = file:open("sys/class/pwm/pwmchip0/pwm0/enable", [read, write]),
  RefEnable. %% RefVal is a process, controls the open file

%%%%% gen_server callbacks
%%
%%init({Pin, Direction}) ->
%%  survivor:entry(pipeTyp_created),
%%  Ref = configure(Pin, Direction),
%%  {ok, #{pin=>Pin, ref=>Ref}}.  %%initialize State with a map
%%
%%
%%handle_call({send, Val}, _From, #{ref :=Ref}=State)->
%%  file:position(Ref, 0),
%%  {ok, NewRef} = file:write(Ref, integer_to_list(Val)),
%%  {reply, maps:get(ref, State), maps:update(ref, NewRef, State)};
%%
%%handle_call({recv}, _From, #{ref :=Ref}=State)->
%%  file:position(Ref, 0),
%%  {ok, Data} = file:read(Ref, 1),
%%  {reply, maps:get(ref, State), maps:update(ref, NewRef, State)}.
%%
%%
%%handle_cast({add, {Key, Val}}, State) ->
%%
%%  { noreply, maps:put(Key, Val, State) }.
