-module(playerwork).

-export([start/0,start_link/0,return_online_num/0]).

-export([send_data_players/1,send/1]).



-define(IP,"127.0.0.1").
-define(Port,8099).
-define(TCP_OPTIONS,[binary,{packet, 2},{keepalive, true},{reuseaddr, true},{nodelay, true}]).

-include("../include/players.hrl").



start_link() ->
	{ok,spawn_link(?MODULE,start,[])}.


start() ->
	erlang:register(?MODULE,self()),
	accept([]).



accept(OnLine) ->
	receive
		{add,Number} ->
			Len = length(OnLine),
			NewOnLine = add_players({?IP,?Port},lists:seq(Len+1,Len+Number),OnLine),
			accept(NewOnLine);
		{online} ->
			io:format("OnLineNum:~p~n",[return_online_num()]);
		stop ->
			ok
	end.



-ifndef(IF).
-define(IF(B,T,F), (case (B) of true->(T); false->(F) end)).
-endif.
%% 增加玩家
add_players(_,[],Acc) ->
	Acc;

add_players({IP,Port},[H|T],Acc) ->
	PcName = os:getenv("USERDOMAIN"),
	PcName1 = ?IF(PcName==false,os:getenv("HOSTNAME"),PcName),
	PlayersName = list_to_binary(PcName1 ++ integer_to_list(H)),
	PlayersPid2 = connect(PlayersName,{IP,Port}),
	add_players({IP,Port},T,[PlayersPid2|Acc]).





%% 链接服务器
connect(PlayersName,{IP, Port}) ->
	case gen_tcp:connect(IP, Port, ?TCP_OPTIONS) of
		{ok, Socket} ->
			Sendpid = send_data_players(Socket),
			PlayersPid = spawn(fun() -> client(#players{name=PlayersName,sid=Sendpid,socket=Socket}) end),
			ok = gen_tcp:controlling_process(Socket, PlayersPid),
			add_player_message(PlayersName,Sendpid,Socket),
			% io:format("he:~p~n",[PlayersPid]),
			% Data = <<1>>,
			% Sendpid ! {send, Data},
			PlayersPid;
		_ ->
			skip
	end.






%% 发数据给玩家
send_data_players(Socket) ->
	SendDataPid = spawn(fun() -> send(Socket) end),
	SendDataPid.


send(Socket) ->
	receive
		{send, _Bin} ->
			send(Socket);
		stop ->
			ok
	end.


%client
client(#players{socket=Socket,sid=Sendpid} = _Players) ->
	receive
		{tcp_closed,Socket} ->
			Sendpid ! stop,
			ok;
		stop ->
			Sendpid ! stop
	end.


add_player_message(PlayersName,Sendpid,Socket) ->
	Fun = fun() ->
			User_id = mnesia:dirty_update_counter(unique_id2,players,1),
			UserData = #players{id=User_id,name=PlayersName,sid=Sendpid,socket=Socket},
			mnesia:write(UserData)
		end,
	mnesia:transaction(Fun).



%% 返回在线人数
return_online_num() ->
	length(mnesia:dirty_all_keys(players)).
