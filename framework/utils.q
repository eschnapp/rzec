to_json: { [err_code; msg]
    .sp.log.error "EXCEPTION: err_code [", (raze string err_code), "] err_id [", (raze string err_id:(-1?0Ng)[0]), "] msg [", (raze string msg);
    :.j.j (`error_code`error_id`message)!(err_code; err_id; msg);
  };
