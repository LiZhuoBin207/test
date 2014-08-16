-module(rank_deal).



-behaviour(gen_server).

-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3,start_link/0]).
-export([user_level_is_top100/2,return_top10/0]).



%-define(SUPER_CHILD(Sup,Mod),supervisor:start_child(Sup,{Mod,{Mod, start_link, []},permanent, 10000, worker, [Mod]})).
% start() ->
% 	?SUPER_CHILD(server_sup,?MODULE).

-include("../include/level_top.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

-record(state,{}).



start_link() ->
	gen_server:start_link({local,?MODULE},?MODULE,[],[]).


init([]) ->
	{ok,#state{}}.


handle_call(get_top10,_From,State) ->
	Value = return_top10(),
	{reply,Value,State};

handle_call(_Request,_From,State) ->
	Reply = ok,
	{reply,Reply,State}.

handle_cast(_Msg,State) ->
	{noreply,State}.

handle_info(test,State) ->
	{noreply,State};

handle_info({is_top,UserId,CurrentLevel},State) ->
	user_level_is_top100(UserId,CurrentLevel),
	{noreply,State};

handle_info(_Msg,State) ->
	{noreply,State}.

terminate(_Reason,_State) ->
	ok.

code_change(_,State,_) ->
	{ok,State}.




%% 判断当前用户的等级是否可以进入top100
user_level_is_top100(UserId,CurrentLevel) ->
	Len = length(mnesia:dirty_all_keys(level_top)),
	if
		Len == 100 ->
			F = ets:fun2ms(fun(#level_top{id=Ids,level=Level}) -> {Level,Ids} end),
			ListLevel = mnesia:dirty_select(level_top,F),
			ListLevelSort = lists:sort(ListLevel),
			{MinNum,Id} = lists:nth(1,ListLevelSort),
			if
				CurrentLevel > MinNum ->
					Oid = {level_top,Id},
					F2 = fun() ->
							mnesia:delete(Oid)
					end,
					mnesia:transaction(F2),
					NewData = #level_top{id=UserId,level=CurrentLevel},
					ok = mnesia:dirty_write(NewData);
				true ->
					pass
			end;
		true ->
			NewData = #level_top{id=UserId,level=CurrentLevel},
			ok = mnesia:dirty_write(NewData)
	end.	



%% 返回leveltop10
return_top10() ->
	F = ets:fun2ms(fun(#level_top{id=Ids,level=Level})-> {Level,Ids} end),
	ListLevel = mnesia:dirty_select(level_top,F),
	ListLevelSort = lists:sort(ListLevel),
	lists:sublist(ListLevelSort,1,10).




