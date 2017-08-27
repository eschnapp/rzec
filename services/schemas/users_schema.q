/ this schema must be used to run USERS_TP/RT/HIST svcs

users: ([] time: `time$();
           user_id: `$();
           steam_id: `$();
           discord_id: `$();
           steam_name: `$();
           discord_name: `$();          
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
