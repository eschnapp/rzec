/ this schema must be used to run USERS_TP/RT/HIST svcs

users: ([] time: `time$();
           user_id: `$();
           steam_id: `$();
           discord_id: `$();
           steam_name: `$();
           discord_name: `$();          
           steam_profile_state: `$();
           steam_profile_visibility: `$();
           steam_profile_url: `$();
           steam_avatar: `$();
           steam_online_state: `$();
           steam_last_logoff: `long$();
           steam_state_code: `$();
           steam_country_code: `$();
           commu_banned: `boolean$();
           vac_banned: `boolean$();
           vacban_count: `int$();
           days_since_ban: `int$();
           gameban_count: `int$();
           ecoban_state: `$();
           deleted: `boolean$());


friendships:([] time: `time();
                src_user_id: `$();
                tgt_user_id: `$();
                deleted: `boolean$());

user_roles: ([] time: `time$();
           user_id: `$();
           role: `$();
           deleted: `boolean$());

roles: ([] time: `time$();
           role: `$();
           access_level: `$();
           deleted: `boolean$());

points: ([] time: `time$();
            user_id: `$();
            point_count: `$());
