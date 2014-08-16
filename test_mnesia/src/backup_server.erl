-module(backup_server).

-behaviour(gen_server).

-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3,start_link/0]).
-export([get_currentday_0_time/1,get_current_time/0,get_current_data/1]).
-export([go/0,go2/0,go3/0]).
-export([data_backup/1]).


-include ("../include/db.hrl").
-include("../include/level_top.hrl").
-include("../include/log.hrl").

-include("../include/players.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-include("../include/backup_times.hrl").

%-define(SUPER_CHILD(Sup,Mod),supervisor:start_child(Sup,{Mod,{Mod, start_link, []},permanent, 10000, worker, [Mod]})).

-define(ADD,50).
-define(READ,20).
-define(UPDATA,23).
-define(DELETE,21).
-define(UPDATA_LEVEL,3).
-define(RECORDLOG,50).
-define(GO,2000).
-define(DATA,<<1>>).
-define(DIFF_SECONDS_0000_1900, 62167219200).

-define(BACKUPDIR2,"C:/Users/it/Desktop/myFirstRepo/test_mnesia/data/backup").




-record(state,{}).


%%  查看监控树下的进程：supervisor:which_children(server_sup)


% start() ->
% 	?SUPER_CHILD(server_sup,?MODULE).


start_link() ->
	gen_server:start_link({local,?MODULE},?MODULE,[],[]).



init([]) ->
	io:format("init-----------------------------------------------------------~n"),
	process_flag(trap_exit,true),
	% Nodes = [node()],
	% ok = mnesia:create_schema(Nodes),
	% ok = mnesia:start(),
	% mnesia:create_table(db,[
	% 		{type,set},
	% 		{disc_only_copies,Nodes},
	% 		{attributes,record_info(fields,db)}
	% 	]),
	% mnesia:create_table(unique_id,[
	% 		{type,set},
	% 		{disc_only_copies,Nodes},
	% 		{attributes,record_info(fields,unique_id)}
	% 	]),
	Times = init_data(),
	%io:format("Ti----------------------~p~n",[Times]),
	erlang:send_after(1000,self(),lookup),
	erlang:send_after(1000,self(),updata),
	erlang:send_after(1000,self(),add),
	erlang:send_after(1000,self(),delete),
	erlang:send_after(1000,self(),update_level),
	erlang:send_after(1000,self(),recordlog),
	erlang:send_after(1000*10,self(),{backup,Times}),
	% erlang:send_after(1000,self(),kills),

	{ok,#state{}}.





handle_call(_Request, _From, State) ->
	Reply = ok,
	{reply, Reply, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.
 
handle_info(going, State) ->
	go(),
	erlang:send_after(1000,self(),going),
	{noreply, State};

handle_info(lookup, State) ->
	Num = ?READ,
	do(Num),
	{noreply, State};
	
handle_info(updata, State) ->
	Num = ?UPDATA,
	do(Num),
	{noreply, State};

handle_info(delete, State) ->
	Num = ?DELETE,
	do(Num),
	{noreply, State};

% handle_info(kills, State) ->
% 	return_total_keys(),


handle_info(add, State) ->
	Num = ?ADD,
	do(Num),
	{noreply, State};

handle_info(update_level, State) ->
	Num = ?UPDATA_LEVEL,
	do(Num),
	{noreply, State};

handle_info(recordlog,State) ->
	Num = ?RECORDLOG,
	do(Num),
	{noreply,State};


handle_info({backup,Times}, State) ->
	spawn(fun() -> data_backup(Times) end),
	NextTimes = Times + 1,
	T = #backup_times{num=NextTimes},
	ok = mnesia:dirty_write(T),
	erlang:send_after(1000*10,self(),{backup,NextTimes}),
	{noreply, State};

handle_info({'EXIT', _Pid, _Msg}, State) ->
	%% 每一次进程的退出都会经过这里
    {noreply, State};


handle_info(_Msg, State) ->
	{noreply, State}.



terminate(_Reason, _State) ->
	ok.

code_change(_, State, _) ->
	{ok, State}.


init_data() ->
	case mnesia:dirty_read(backup_times,1) of
		[] ->
			1;
		[Data] ->
			Data#backup_times.num
	end.



do(Num) ->
	if
		Num == ?READ ->
			read(Num),
			erlang:send_after(1000,self(),lookup);
		Num == ?UPDATA ->
			updata(Num),
			erlang:send_after(1000,self(),updata);
		Num == ?ADD ->
			add(Num),
			erlang:send_after(1000,self(),add);
		Num == ?DELETE ->
			delete(Num),
			erlang:send_after(1000,self(),delete); 
		Num == ?UPDATA_LEVEL ->
			update_level(Num),
			erlang:send_after(1000,self(),update_level);
		Num == ?RECORDLOG ->
			record_log(Num),
			erlang:send_after(1000,self(),recordlog);
		true ->
			pass
	end.


%% 数据备份

%% mnesia:restore("d:/backup.log",[]).恢复数据库的方法


data_backup(Times) ->
	% io:format("Times:~p~n",[Times]),
	% CurrentTime = get_current_time(),
	% Today12dian = get_currentday_0_time(CurrentTime),
	% case CurrentTime == Today12dian of
	% 	true ->
	% 		mnesia:backup("C:/Users/it/Desktop/myFirstRepo/test_mnesia/data/backup.log");
	% 	_ ->
	% 		erlang:send_after(1000,self(),backup)
	% end.
	BackupDir = ?BACKUPDIR2 ++ integer_to_list(Times) ++ ".log",
	mnesia:backup(BackupDir).




go() ->	
	OnlineList = reture_online_pid(),
	Len2 = length(OnlineList),
	if
		Len2 >= 1 andalso Len2 =< 2000->
			Num = random:uniform(Len2),
			CurrentPid = lists:nth(Num,OnlineList),
			CurrentPid ! {send,?DATA},
			main:add(5);
		Len2 > 2000 ->
			Num = random:uniform(Len2),
			CurrentPid = lists:nth(Num,OnlineList),
			CurrentPid ! {send,?DATA};
		Len2 < 1 ->
			main:add(50);
		true ->
			pass
	end.

go2() ->
	backup_server ! updata,
	backup_server ! add,
	backup_server ! delete,
	backup_server ! update_level,
	backup_server ! recordlog.

go3() ->
	backup_server ! lookup,
	backup_server ! updata,
	backup_server ! delete,
	backup_server ! update_level.



%% level
update_level(Number) when Number > 0 ->
	random:seed(now()),	 
	Id = random:uniform(10000),
	L = random:uniform(100),
	% List = [44,47,99,22],
	% L = lists:nth(random:uniform(4),List),
	if
		L == 44 orelse 77->
			exit(kill);
		true ->
			case mnesia:dirty_read(db,Id) of
				[Data] ->
					NewData = Data#db{level=L},
					ok = mnesia:dirty_write(NewData);
				[] ->
					pass
			end,
			catch rank_deal ! {is_top,Id,L},
			NewNumber = Number - 1,
			if
				NewNumber >= 1 ->
					spawn_link(fun() -> update_level(NewNumber) end);
				true ->
					pass
			end
	end.


%% 修改数据
updata(Number) when Number >0 ->
	random:seed(now()),	 
	Id = random:uniform(10000),
	NewName = Id + 1,
	case mnesia:dirty_read(db,Id) of
		[Data] ->
			NewData = Data#db{name=NewName},
			ok = mnesia:dirty_write(NewData);
		[] ->
			pass
	end,
	NewNumber = Number - 1 ,
	if
		NewNumber >= 1 ->
			spawn(fun() -> updata(NewNumber) end);
		true ->
			pass
	end.


%% 删除数据
delete(Number) when Number > 0 ->
	random:seed(now()),
	Id = random:uniform(10000),
	Oid = {db,Id},
	F = fun() ->
			mnesia:delete(Oid)
	end,
	mnesia:transaction(F).



%% 查询数据
read(Number) when Number > 0 ->
	random:seed(now()),
	Id = random:uniform(10000),
	case mnesia:dirty_read(db,Id) of
		[_] ->
			pass;
		[] ->
			pass
	end,
	NewNumber = Number - 1,
	if 
		NewNumber >= 1 ->
			spawn(fun() -> read(NewNumber) end);
		true ->
			pass
	end. 


%% 增加数据
add(Number) when Number > 0 ->
	Len = reture_db_allkeys(),
	if
		Len > 500000 ->
			pass;
		true ->
			random:seed(now()),	 
			NewName = random:uniform(1000000),
			Fun = fun() ->
					User_id = mnesia:dirty_update_counter(unique_id,db,1),
					UserData = #db{userid=User_id,name=NewName},
					mnesia:write(UserData)
				end,
				mnesia:transaction(Fun),
			NewNumber = Number -1 ,
			if
				NewNumber >= 1 ->
					spawn(fun() -> add(NewNumber) end);
				true ->
					pass
			end
	end.


%% 用户日志
record_log(Number) ->
	Len = reture_log_allkeys(),
	if
		Len > 100000 ->
			pass;
		true ->
			random:seed(now()),
			UserId = random:uniform(100000),
			ExitId = random:uniform(100),
			if
				ExitId == 44 ->
					exit(kill);
				true ->
					ExitTime = get_current_time(),
					LoginTime = ExitTime - 1000*60*30,
					OnlineTime = ExitTime - LoginTime,
					ExitReason = normal,
					Log = #log{userid=UserId,logintime=LoginTime,exittime=ExitTime,onlinetime=OnlineTime,exitreason=ExitReason},
					ok = mnesia:dirty_write(Log),
					NewNumber = Number -1,
					if
						NewNumber >= 1 ->
							spawn_link(fun() -> record_log(NewNumber) end);
						true ->
							pass
					end
			end
	end.



reture_db_allkeys() ->
	AllKeys = mnesia:dirty_all_keys(db),
	length(AllKeys).



reture_log_allkeys() ->
	AllKeys = mnesia:dirty_all_keys(log),
	length(AllKeys).





%% 返回在线人的pid
reture_online_pid() ->
	F = ets:fun2ms(fun(#players{sid=Sid}) -> Sid end),
	mnesia:dirty_select(players,F).





% %% 返回所有的记录数
% return_total_keys() ->
% 	length(mnesia:dirty_all_keys(log)) + length(mnesia:dirty_all_keys(db)).


% %% 查询等级排行前十的用户
% get_level_top10() ->
% 	gen_server:call(create_random,get_top10).

	

%% 当前时间 以秒为单位
get_current_time() ->
	{M,S,_} = os:timestamp(),
	M * 1000000 + S.




%% 获取当天的 0点的秒值
get_currentday_0_time(Seconds) ->
	{{_Y,_M,_D}, Time} = get_current_data(Seconds),
	%%获取从凌晨0点，到现在的秒数
	Diff = calendar:time_to_seconds(Time),
	%% 获取当天的0点
	Seconds - Diff.






%% 获取当前的日期
get_current_data(Seconds) ->
	DateTime = calendar:gregorian_seconds_to_datetime(Seconds + ?DIFF_SECONDS_0000_1900),
	calendar:universal_time_to_local_time(DateTime).
