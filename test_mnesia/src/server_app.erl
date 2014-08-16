-module(server_app).

-behaviour(application).

-export([stop/1,start/2]).






start(_StartType, _StartArgs) ->
	server_sup:start_link().


stop(_State) ->
	ok.