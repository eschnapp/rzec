.boot.include (gdrive_root, "/framework/common.q");
.sample_sim.on_comp_start:{
	
	// look for the data source...
	srcfile: .sp.arg.required[`data_source_file];
	.sp.log.info "Loading data source file: ", (raze string srcfile);
	all_samples:: get hsym `$(raze string srcfile);
	sample_ids:: exec distinct sample_id from all_samples;
	.sp.log.info "Loaded ", (raze string count sample_ids), " sample records...";
	.sp.log.info "Schedueling the simulator timer...";
	next_sample_to_pub:: first sample_ids;
	 .sp.cron.add_timer[10000; -1; .sample_sim.on_timer_event];
	:1b;
	};


.sample_sim.on_timer_event:{[i;t]
	.sp.log.info "Timer event, publishing next sample: ", (raze string next_sample_to_pub);
	data: select from all_samples where sample_id = next_sample_to_pub;
	data: update time: .z.T, sample_time: .z.Z from (select sample_id, account_id: user_id, stroke_index: `int$stroke_index , time_index: `int$event_time, x, y, pressure, sz: size, tool_a_x: tlmj, tool_a_y: tlmn, tool_b_x: tcmj, tool_b_y: tcmn, valid: fake from data);
	.sp.log.info "Updating ", (raze string (count data)), " records.";
	.sp.re.exec[`SAMPLES_TP;`;(`.sp.tp.upd;`samples;data);-1];
	next_sample_to_pub:: sample_ids[(sample_ids?next_sample_to_pub)+1];
	if[(null next_sample_to_pub) = 1b; next_sample_to_pub:: first sample_ids]; 
	.sp.log.info "Update complete, next sample: ", (raze string next_sample_to_pub);
	};

.sp.comp.register_component[`samples_simulator_app;`common;.sample_sim.on_comp_start];
