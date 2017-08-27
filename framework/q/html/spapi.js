  function init_sp_api() {      
      var qaMode = false;
      var url = window.location.href;
      var apiRoot = 'endpoint-api-dot-forget-your-passwords.appspot.com/_ah/api';
      if( document.getElementsByName('qa_mode').length > 0 ) {
          apiRoot = 'endpoint-api-qa-dot-forget-your-passwords.appspot.com/_ah/api';
          qaMode = true;
      }

      var onready = function() {};
      if( window.hasOwnProperty('onSPApiReady') == true ) {
        console.log('calling onSPApiReady...');
        window['onSPApiReady']();
      }
      
      apiRoot = 'https://' + apiRoot;
      gapi.client.setApiKey('AIzaSyAKjCLMktdb3BMIyW5zG3UeZHdH5jaKwrM');
      gapi.client.load('ep_api', 'v3', onready, apiRoot);
    }
    
    function IsNumeric(n) {
	  return !isNaN(parseFloat(n)) && isFinite(n);
	}
    
    function spAuth(target, source, msg, onresult, onerror) {
        
        gapi.client.ep_api.sp_api.authentication_request({timeout:3000, source_id: source, target_id: target, info: msg }).
            then(function(resp) {
                var rid = resp.result.request_id;
                console.log('auth request complete - token: ' + rid);
                onresult(resp);
            }, function(reason) {
                console.log('Error: ' + reason.result.error.message);
                onerror(reason);
            });
    }
    
    function spCheckAuth(rid, onresult, onerror) {
        gapi.client.ep_api.sp_api.authentication_status_request({timeout:3000, request_id: rid}).
            then(function(resp) {
                console.log('auth status request complete - result: ' + resp.result.status);
                onresult(resp);
            }, function(reason) {
                console.log('Error: ' + reason.result.error.message);
                onerror(reason);
            });
    }
