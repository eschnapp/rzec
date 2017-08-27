.boot.include (gdrive_root, "/framework/common.q");
.boot.include (gdrive_root, "/framework/cache.q");

.gpl.on_comp_start: {
   .auth_svc.states:: (`pending`completed`expired`rejected!`int$(0 1 2 3));
   .gpl.roles:: ( ([] func_name: `$(); required_roles: () ) upsert (
               (`get_user_info; (enlist `role.domain.data; enlist `role.system.admin) );
               (`create_subdomain; (enlist `role.domain.admin.subdomains; enlist `role.system.admin) );
               (`delete_subdomain; (enlist `role.domain.admin.subdomains; enlist `role.system.admin) );
               (`get_permissions; (enlist `role.domain.admin.users; enlist `role.system.admin) );
               (`get_domains; (enlist `role.domain.admin.subdomains; enlist `role.system.admin) );
               (`report_issue; (enlist `role.domain.member; enlist `role.domain.data; enlist `role.system.admin) );
               (`reset_user; (enlist enlist `role.system.admin) );
               (`reset_sample; (enlist enlist `role.system.admin) );
               (`add_role; (enlist `role.domain.admin.users; enlist `role.system.admin) );
               (`get_trends; (enlist `role.domain.data; enlist `role.system.admin) );
               (`get_sample_info; (enlist `role.domain.data; enlist `role.system.admin) );
               (`get_sample; (enlist `role.domain.data; enlist `role.system.admin) );
               (`get_system_info; (enlist `role.domain.status; enlist `role.system.admin) );
               (`open_issue; (enlist `role.domain.member; enlist `role.domain.data; enlist `role.system.admin) );
               (`create_subdomain; (enlist `role.domain.admin.subdomains; enlist `role.system.admin) );
               (`secure_domain; (enlist `role.system.admin; enlist `role.domain.admin.subdomains) );
               (`remove_role; (enlist `role.domain.admin.users; enlist `role.system.admin) );
               (`get_requests; (enlist `role.domain.admin.users; enlist `role.system.admin) );
               (`auth_status_request; enlist (enlist `role.domain.member))
               ) );
   .gpl.ret_values::(`d1`d2)!(`dummy;0b);
    :1b;
  };

.gpl.chk_and_exec:{ [hdl_k; func_nm; tkn; params]
       func: "[.gpl.chk_and_exec] : ";

       my_hdl_k:: hdl_k;
       my_func_name:: func_nm;
       my_tkn:: tkn;
       my_params:: params;

       ctx:: .gpl.validate_token tkn;
       roles:: select role by domain from .gpl.get_roles[ ctx[`uid] ];
       req_roles:: last exec required_roles from .gpl.roles where func_name = func_nm;
       allowed_domains: .gpl.get_allowed_domains[roles; req_roles];
    my_allowed_domains:: allowed_domains;
       // TODO: if null allowed_domains or empty list throw exception as access denied/no roles match.
       if[ all (null allowed_domains) or (0=count allowed_domains);
        .sp.exception to_json[ API_ERRORS[`USR_NOT_PERMISSIONED]; "Access denied. No roles matched!" ];
         ];

       res: ( ( value (".prv.", (raze string func_nm)) ) [ ctx; allowed_domains ] ) . params; // create the func to be called.
       .gpl.ret_values[func_nm]: res;

       .sp.log.info func, "looking for pending request...";
       hdl: .gae.pending_requests[hdl_k];
      // TODO: check for valid hdl
       if[ 0 >= hdl; .sp.exception func, "Invalid handle."];

       .sp.log.info func, "sending async result...";
       (neg hdl) (hdl_k;(res));
       .sp.log.info func, "complete";
     };

.gpl.validate_token: { [tkn]
       func:"[ .gpl.validate_token] : ";
       // TODO: check token against request_tp by request_id. Return row. If not found/expired/rejected, throw exception
       t: select from .sp.cache.tables.requests where request_id = tkn;
       $[ 0 >= count t; .sp.exception func, "No User found with this token: ", (raze string tkn); t:last (0!t)];
       if[ (last t`status) in (.auth_svc.states`expred; .auth_svc.states`rejected); .sp.exception func, "token : ", (raze string tkn), " expired/rejected" ];
       :t;
     };

.gpl.get_roles:{ [uid]
       // get all roles from user_permissions table
       :select from .sp.cache.tables.user_permissions where user_id=uid;
     } ;

.gpl.match_roles: { [req; found]
       :any { all x in y }[;found] each req;
     };

.gpl.get_allowed_domains : { [roles; req_roles]
       : raze { [req; found] :$[all .gpl.match_roles[req; found[`role] ]; found[`domain]; () ] } [req_roles; ] each 0!roles;
     };

.gpl.get_domain_members: { [domains]
       // for each domain, return all user ids that has role .domain.member
       :select from (select by user_id, role, domain from .sp.cache.tables.user_permissions) where domain in domains;
     } ;

// change the user_permissions table schema: source_name = domain, func = role -- DONE

//select func by source_name from (select by user_id, source_name, func from user_permissions) where user_id = `$"etay@6"
//(enlist `role.domain.data; enlist `role.system.admin)

.sp.comp.register_component[`gpl;enlist `common;.gpl.on_comp_start];

