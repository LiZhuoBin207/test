-module(main).

-export([start/0,add/1,online_num/0]).
-export([stop/0]).

start() ->
	%% 启动监控树程序
	ok = application:start(server).
stop() ->
	ok = application:stop(server).




add(Num) ->
	playerwork ! {add,Num}.

online_num() ->
	playerwork ! {online}.


