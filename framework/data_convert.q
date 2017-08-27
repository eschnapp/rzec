// This file has utility functions to serialize and de-serialize data. We get data in as byte stream and send out data as byte stream. 

.boot.include (gdrive_root, "/framework/core.q");

.sp.dc.on_comp_start:{ []
	func:"[.sp.dc.on_comp_start] : ";
	.sp.log.info func, "component dc - Data Convert - is ready";
	:1b
  };

// TODO : Implement encrypt / decrypt functions later!
.sp.dc.decrypt: { [d] :d };

.sp.dc.encrypt: { [d] :d };
  
.sp.dc.serialize:{ [d] :-8!(.sp.dc.encrypt d) };

.sp.dc.de_serialize: { [d]
		if[ 4h <> type d; d: "x"$d];
		:-9!(.sp.dc.decrypt d) };


.sp.dc.b64_enc:{ a: raze { 56_ vs[0b;x] } each (`long$x); b: 6 cut a; c: { t: ((8 - (count x))#(0b)),x; sv[0b;t] } each b; d: {9_ .Q.x10 x} each (`long$c); : raze d; };


.sp.comp.register_component[`dc; `core; .sp.dc.on_comp_start];
  
		
		
		
		
	
	
