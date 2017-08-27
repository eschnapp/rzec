/ this schema must be used to run USERS_TP/RT/HIST svcs


chatlog: ([] time: `time$();
             server_id: `$();
             user_id: `$();
             nametag: `$();
             servertime: `$();
             servertag: `$());


killfeed: ([] time: `time$();
              server_id: `$();
              user_id: `$();
              killed_by: `$();
              weapon: `$();
              distance: `$());


custom_events: ([] time: `time$();
                   server_id: `$();
                   event_tag: `$();
                   event_user: `$();
                   event_data: `$());



playerlog: ([] time: `time$();
               server_id: `$();
               user_id: `$();
               active: `boolean$();
               last_connected: `datetime$();
               hours_on_server: `int$());

