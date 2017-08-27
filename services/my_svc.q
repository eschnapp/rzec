.boot.include gdrive_root, "//development//qcore//core.q"
.boot.include gdrive_root, "//development//qcore//common.q"
.boot.include gdrive_root, "//development//models//my_sample_lib.q"


.my_svc.on_comp_start:{[]

    .sp.log.info "STARTING THE SEVICE YO!!!!!!!!!!!!!!!!!";


    :1b;
    };

.my_svc.get_sample_by_user:{[aid]

	: select from .my_lib.my_table where account_id = aid;

  };










.sp.comp.register_component[`my_svc;`common`core`my_lib;.my_svc.on_comp_start];
