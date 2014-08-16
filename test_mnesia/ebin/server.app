{application,server,
             [{description,"This is test_backup server."},
              {vsn,"1.0"},
              {modules,[acceptor,backup_server,main,mnesia_db,playerwork,
                        rank_deal,server_app,server_sup]},
              {registered,[]},
              {applications,[kernel,stdlib]},
              {mod,{server_app,[]}},
              {start_phases,[]}]}.
