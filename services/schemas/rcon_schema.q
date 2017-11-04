/ this schema must be used to run USERS_TP/RT/HIST svcs

events : ( [] time:`time$();
	server_id:`$();
	msg:();
	identifier:`int$()); 

chat:  ([] time: `time$();
            msg: ();
            userid: `$();
            username: ();
            color: ();
            server_time: `long$());

bans: ([] time: `time$();
        steamid: `$();
        grp: `$();
        username: ();
        notes: ());

playerlist: ([] time: `time$();
                steamid: `$();
                owner_steamid: `$();
                username: ();
                ping: `int$();
                address: `$();
                connected_s: `long$();
                violation: `float$();
                health:  `float$());

serverinfo: ([] time: `time$();
                hostname: `$();
                max_players: `int$();
                players: `int$();
                queued: `int$();
                joining: `int$();
                entity_count: `int$();
                game_time: `datetime$();
                uptime: `long$();
                map: `$();
                framerate: `float$();
                memory: `int$();
                collections: `int$();
                nw_in: `long$();
                nw_out: `long$();
                restarting: `boolean$();
                saved: `datetime$());

stats:([]   time: `time$();
            steamid: `$();
            username: ();
            upd_time: `time$();
            kills: `int$();
            deaths: `int$();
            suicides: `int$();
            player: ();
            building: ();
            entity: ());       
