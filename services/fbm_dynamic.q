.sp.fbm.dynamic.on_comp_start: {
    
    :1b;
    };
    
    
.sp.comp.register_component[`fbm_dynamic;`core;.sp.fbm.dynamic.on_comp_start];

.sp.fbm.dynamic.validate_samples:{[samples]
    if[ not all `stroke_index`x`y`account_id`sample_id`time_index in cols samples;
        :0b];
    :1b;
    };

.sp.fbm.dynamic.extractfeature:{[signature]
    if[not `action in cols signature;
        signature:update action:{r:(count x)#2;r:?[(x<>prev x) or (y<>prev y);0;r];r:?[(x<>next x) or (y<>next y);1;r];r}[sample_id;stroke_index] from signature
    ];

    delete action,time_index,x,y,dt,dx,dy,et,v,vx,vy,d,vmin,vyavg,vymin,vymax,vxmax,vxavg,xmin,xmax,ymin,ymax,xstart,xend,length from 
    update xstddev: sqrt var each x,ystddev: sqrt var each y from /41,42
    update aspectratio:(xmax - xmin)%ymax - ymin from /40
    update xstartmin:xstart-xmin,xendmax:xend-xmax,xendmin:xend-xmin from /37,38,39
    update lenarearatio:length%area from /36
    update length:sum each d from
    update area:(xmax - xmin)*ymax - ymin from /35
    update tmaxx:({first x where y=z} ./: flip (et;x;xmax))%ts from /34
    update tminx:({first x where y=z} ./: flip (et;x;xmin))%ts from /33
    update xmax:max each x,xmin:min each x,ymax:max each y,ymin:min each y,xstart:first each x, xend:last each x from 
    update vxmaxvymin:vxmax-vymin from /32
    update vymaxmin:vymax-vymin from /31
    update vxmaxmin:vxmax-vxmin from /30
    update vymaxavg:vymax-vyavg from /29
    update vxmaxavg:vxmax-vxavg from /28
    update vyavg:avg each vy,vymax:max each vy,vymin:min each vy from
    update vyzeroc:{sum x=0} each vy from /27
    update vxzeroc:{sum x=0} each vx from /26
    update vynegavg:{avg x where x<0} each vy from /25
    update vyposavg:{avg x where x>0} each vy from /24
    update vxnegavg:{avg x where x<0} each vx from /23
    update vxposavg:{avg x where x>0} each vx from /22
    update vynegt:{sum x where y<0} ./: flip (dt;vy) from /21
    update vypost:{sum x where y>0} ./: flip (dt;vy) from /20
    update vxnegt:{sum x where y<0} ./: flip (dt;vx) from /19
    update vxpost:{sum x where y>0} ./: flip (dt;vx) from /18
    update dirdown1uplast:{dx:(last x where z=1)-first x where z=0;dy:(last y where z=1)-first y where z=0;{pi:4*atan[1];((pi+(2*atan[1]*1-signum x)+atan y%x) mod (8*atan[1]))-pi}[dx;dy]} ./: flip (x;y;action) from /17
    update dir2:{dx:(next x) where z=0;dy:(next y) where z=0;{pi:4*atan[1];((pi+(2*atan[1]*1-signum x)+atan y%x) mod (8*atan[1]))-pi}[first 1_dx;first 1_dy]} ./: flip (dx;dy;action) from /16
    update dirdown1up2:{dx:(first 1_x where z=1)-first x where z=0;dy:(first 1_y where z=1)-first y where z=0;{pi:4*atan[1];((pi+(2*atan[1]*1-signum x)+atan y%x) mod (8*atan[1]))-pi}[dx;dy]} ./: flip (x;y;action) from /15
    update dirdown1down2:{{pi:4*atan[1];((pi+(2*atan[1]*1-signum x)+atan y%x) mod (8*atan[1]))-pi}[first 1_deltas x where z=0;first 1_deltas y where z=0]} ./: flip (x;y;action) from /14
    update dir1:{dx:(next x) where z=0;dy:(next y) where z=0;{pi:4*atan[1];((pi+(2*atan[1]*1-signum x)+atan y%x) mod (8*atan[1]))-pi}[first dx;first dy]} ./: flip (dx;dy;action) from /13
    /update tdown1:{first x where y=z} ./: flip (et;action;1) from /extra
    update etdown2:{first 1_x where y=z} ./: flip (et;action;0) from /12
    update numstroke:{count x where y=z} ./: flip (et;action;1) from /11
    update tavg:{avg -1_x} each dt from /10
    update numpoint:count each et from /9 
    update vxmint:{sum x where y=z} ./: flip (dt;vx;vxmin) from /8
    update vxavg:avg each vx,vxmax:max each vx,vxmin:min each vx from /x,x,7
    update tw:{sum x where y<>z} ./: flip (dt;action;1) from /6
    update ts:last each et from /5
    update tmove1:{first x where y=z} ./: flip (dt;action;2) from /4
    update vmaxt:{sum x where y=z} ./: flip (dt;v;vmax) from /3
    update vavg:avg each v,vmax:max each v,vmin:min each v from /1,2,?
    update vy:{a:where z<>1;(1_x a)%1_y a} ./: flip (dy;dt;action) from 
    update vx:{a:where z<>1;(1_x a)%1_y a} ./: flip (dx;dt;action) from 
    update v:{a:where z<>1;(1_x a)%1_y a} ./: flip (d;dt;action) from 
    update dt:deltas each et from 
    update et:{x-first x} each time_index from
    update d:{sqrt[(x*x)+y*y]} ./: flip (dx;dy) from 
    update dx:{0,1_deltas x} each x,dy:{0,1_deltas x} each y from 
    select 
        action,time_index,x,y
        by account_id,sample_id 
        from
        select min action,avg x, avg y by account_id,sample_id,time_index from
        // select avg action,avg x, avg y by account_id,sample_id,time_index from 
        select from signature
    };

    
.sp.fbm.dynamic.avg_all:{[feature]
    select 
    avg  vavg,
    avg  vmax,
    avg  vmaxt,
    avg  tmove1,
    avg  ts,
    avg  tw,
    avg  vxmin,
    avg  vxmint,
    avg  numpoint, 
    avg  tavg,
    avg  numstroke,
    avg  etdown2,
    avg  dir1,
    avg  dirdown1down2,
    avg  dirdown1up2,
    avg  dir2,
    avg  dirdown1uplast,
    avg  vxpost,
    avg  vxnegt,
    avg  vypost,
    avg  vynegt,
    avg  vxposavg,
    avg  vxnegavg,
    avg  vyposavg,
    avg  vynegavg,
    avg  vxzeroc,
    avg  vyzeroc,
    avg  vxmaxavg,
    avg  vymaxavg,
    avg  vxmaxmin,
    avg  vymaxmin,
    avg  vxmaxvymin,
    avg  tminx,
    avg  tmaxx,
    avg  area,
    avg  lenarearatio,
    avg  xstartmin,
    avg  xendmax,
    avg  xendmin,
    avg  aspectratio,
    avg  xstddev,
    ystddev: avg  ystddev
    from feature
    };

.sp.fbm.dynamic.feature_func:{[feature;func]
    :.sp.fbm.dynamic.feature_func_grp[feature;func;(enlist `account_id)!enlist `account_id];
    };    
    
.sp.fbm.dynamic.feature_func_grp:{[feature;func;grp]
    c: (cols feature) except `account_id`sample_id;
    kys: c;
    vals: flip ((count c)#value func;(count c)#(c));
    if[-1h = type grp; if[0b = grp; kys: `account_id,c; vals: ((enlist `account_id),flip ((count c)#value func;(count c)#(c)))]];
    : ?[feature;();grp;kys!vals];   
    };    
    
.sp.fbm.dynamic.feature_min:{[feature]
    :.sp.fbm.dynamic.feature_func[feature;"min"];
    };
            
.sp.fbm.dynamic.feature_max:{[feature]
    :.sp.fbm.dynamic.feature_func[feature;"max"];
    };
    
.sp.fbm.dynamic.feature_mean:{[feature]
    :.sp.fbm.dynamic.feature_func[feature;"avg"];
    };

.sp.fbm.dynamic.feature_var:{[feature]
    :.sp.fbm.dynamic.feature_func[feature;"var"];
    };  

/ .sp.fbm.dynamic.feature_sigma:{[feature]
/     :1!.sp.fbm.dynamic.feature_func[.sp.fbm.dynamic.feature_var[feature];"sqrt"];    
/     };

/ not sure why previously i didnt gorup sigma by user but must do it otherwise u cant train multiple users... 
.sp.fbm.dynamic.feature_sigma:{[feature]
    :1!.sp.fbm.dynamic.feature_func_grp[.sp.fbm.dynamic.feature_var[feature];"sqrt";0b];    
    };

/     
/ .sp.fbm.dynamic.verify:{[signature;threshold]
/     sid:first exec sample_id from signature;
/     s:select from signature where sample_id=sid;
/     usr:first exec user_id from s;
/     feature:extractfeature s;
/     template:featuremean extractfeature select from `.[`export_data] where event_time<>0,user_id=usr,sample_id<>sid;
/     sigma:featuresigma extractfeature select from `.[`export_data] where event_time<>0,user_id=usr,sample_id<>sid;
/     t:([] feature:key first feature;v:"f"$value first feature);
/     t:t lj ([feature:key first template] u:value first template);
/     t:t lj ([feature:key first sigma] s:value first sigma);
/     t:update z:(v-u)%s from t;
/     select feature:1+i,pass,v,u,s,z from update pass:threshold>=abs z from t
/     };
     
