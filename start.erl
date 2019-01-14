%%%-------------------------------------------------------------------
%%% @author Changizi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. Nov 2018 16:12
%%%-------------------------------------------------------------------
-module(start).
-author("Changizi").

%% API
-export([run/0]).

%% BCM name for the GPIOs
-define(BCM4, 4).
-define(BCM17, 17).
-define(BCM27, 27).
-define(BCM22, 22).
-define(BCM20, 20).
-define(BCM21, 21).


run() ->
  survivor:start(),
  observer:start(),
  {ok, WireType} = resource_type:create(wireType, []),
  {ok, WireInst_1} = resource_instance:create(wireInst, [self(), WireType]),
  {ok, WireInst_2} = resource_instance:create(wireInst, [self(), WireType]),
  {ok, WireInst_3} = resource_instance:create(wireInst, [self(), WireType]),
  {ok, WireInst_4} = resource_instance:create(wireInst, [self(), WireType]),
  {ok, WireInst_5} = resource_instance:create(wireInst, [self(), WireType]),
  {ok, WireInst_6} = resource_instance:create(wireInst, [self(), WireType]),
  %{ok, WireInst_3} = resource_instance:create(wireInst, [self(), WireType]),
  
  {ok, LedType_1} = resource_type:create(ledType, []),
  {ok, LedInst_1} = resource_instance:create(ledInst, [self(), LedType_1, WireInst_1,
    ?BCM4, fun(X)-> ledType:gpio(X) end]),
  {ok, LedInst_2} = resource_instance:create(ledInst, [self(), LedType_1, WireInst_2,
    ?BCM17, fun(X)-> ledType:gpio(X) end]),
  {ok, LedInst_3} = resource_instance:create(ledInst, [self(), LedType_1, WireInst_3,
    ?BCM27, fun(X)-> ledType:gpio(X) end]),
  %{ok, Fan_Inst} = resource_instance:create(ledInst, [self(), LedType_1, WireInst_6,
    %?BCM20, fun(X)-> ledType:gpio(X) end]),
    
  
  {ok, ButtonType_1} = resource_type:create(buttonType, []),
  {ok, ButtonInst_1} = resource_instance:create(buttonInst, [self(), ButtonType_1, WireInst_4,
    ?BCM22, fun(X)-> buttonType:gpio(X) end]),
  {ok, ButtonInst_2} = resource_instance:create(buttonInst, [self(), ButtonType_1, WireInst_5,
    ?BCM21, fun(X)-> buttonType:gpio(X) end]),
  Connect = resource_instance:connect([WireInst_1, WireInst_2, WireInst_3, WireInst_4, WireInst_6]),
  timer:sleep(100),
  resource_instance:subscribe(ButtonInst_1, [LedInst_1]),
  resource_instance:subscribe(ButtonInst_1, [LedInst_2]),
  resource_instance:subscribe(ButtonInst_1, [LedInst_3]),
  
  %% here, C_list = the first connector in the circuit
  {ok, C_list} = resource_instance:list_connectors(WireInst_1),
  [C|_C_list] = C_list,
  {ok, ConnectivityType} = resource_type:create(connectivityType, []),
  {ok, ConnectivityInst} = resource_instance:create(connectivityInst, [C, ConnectivityType]),
  Res = connectivityInst:get_resource_circuit(ConnectivityInst),
  Res.
  
  %io:format("C:~p~n", [C]).
  
  
  
  
  
relais([WireInst_1, WireInst_2, WireInst_3, WireInst_4, WireInst_5]) ->
  resource_instance:disconnect([WireInst_1, WireInst_2, WireInst_3, WireInst_4, WireInst_5]).
  %{ok, Fan_Inst} = resource_instance:create(ledInst, [self(), LedType_1, WireInst_6,
    %?BCM20, fun(X)-> ledType:gpio(X) end]),
   
    

