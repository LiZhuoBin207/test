-module(mnesia_db).

-export([start/0,create_schema/0,create_table/0,stop/0]).

-include ("../include/db.hrl").
-include("../include/level_top.hrl").
-include("../include/log.hrl").
-include("../include/players.hrl").
-include("../include/backup_times.hrl").

-record(unique_id,{
	item,
	uid
}).



-record(unique_id2,{
	item2,
	uid2
}).




start() ->
	case application:get_env(mnesia,dir) of
		{ok,DbDir} ->
			pass;
		undefined ->
			stopped = mnesia:stop(),
			DbDir = "C:/Users/it/Desktop/myFirstRepo/test_mnesia/data/Mnesia." ++ atom_to_list(node()),
			ok = application:set_env(mnesia, dir, DbDir),
			ok = mnesia:start()
	end,

	case filelib:is_dir(DbDir) of
		false ->
			ok = filelib:ensure_dir(DbDir),
			create_schema();
		_ ->
			case file:list_dir(DbDir) of
				{ok,[]} ->
					create_schema();
				{ok,[_|_]} ->
					pass
			end
	end,
	create_table(),
	ok = mnesia:wait_for_tables([db,unique_id,unique_id2,level_top,log,players],1000),
	ok.

stop() ->
	stopped = mnesia:stop().

create_schema() ->
	stopped = mnesia:stop(),
	ok = mnesia:create_schema([node()]),
	ok = mnesia:start().



create_table() ->
	Nodes = [node()],
	mnesia:create_table(db,[
			{type,set},
			{disc_only_copies,Nodes},
			{attributes,record_info(fields,db)}
		]),
	mnesia:create_table(unique_id,[
			{type,set},
			{disc_only_copies,Nodes},
			{attributes,record_info(fields,unique_id)}
		]),
	mnesia:create_table(unique_id2,[
			{type,set},
			{disc_only_copies,Nodes},
			{attributes,record_info(fields,unique_id2)}
		]),
	mnesia:create_table(level_top,[
		{type,set},
		{disc_only_copies,Nodes},
		{attributes,record_info(fields,level_top)}
	]),
	mnesia:create_table(log,[
		{type,bag},
		{disc_only_copies,Nodes},
		{attributes,record_info(fields,log)}
	]),
	mnesia:create_table(players,[
		{type,set},
		{disc_only_copies,Nodes},
		{attributes,record_info(fields,players)}
	]),
	mnesia:create_table(backup_times,[
		{type,set},
		{disc_only_copies,Nodes},
		{attributes,record_info(fields,backup_times)}
	]).

