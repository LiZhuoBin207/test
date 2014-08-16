-module(server_sup).

-behaviour(supervisor).

-export([start_link/0,init/1]).

-define(PORT,8099).

-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).
-define(CHILD2(I, Type), {I, {I, start_link, [?PORT]}, permanent, 5000, Type, [I]}).


start_link() ->
	supervisor:start_link({local,?MODULE},?MODULE,[]).


init([]) ->
	mnesia_db:start(),
	{ok, {{one_for_one, 20, 10}, [
		?CHILD(backup_server, worker),
		?CHILD(rank_deal, worker),
		?CHILD2(acceptor, worker),
		?CHILD(playerwork, worker)
	]}}.






	