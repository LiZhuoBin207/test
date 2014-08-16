-module(acceptor).


-export([start_link/1]).
-export([start/1,wait/1]).

-define(TCP_OPTIONS,[binary,{packet, 2},{keepalive, true},{reuseaddr, true},{nodelay, true}]).



start_link(Port) ->
	{ok,spawn_link(?MODULE,start,[Port])}.


start(Port) ->
	{ok, L} = gen_tcp:listen(Port,?TCP_OPTIONS),
	wait(L).


wait(L) ->
	{ok, _Socket} = gen_tcp:accept(L),
	%gen_tcp:send(Socket,<<1>>),
	wait(L).
