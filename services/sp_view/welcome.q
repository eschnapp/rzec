
.view.welcome:{[request]

    .sp.h.sdk.define_style["@font-face";(
                          ("font-family";" 'Roboto';");
                          ("font-style";" normal;");
                          ("font-weight";" 400;");
                          ("src";" local('Roboto Regular'),
       local('Roboto-Regular'),
       url(http://themes.googleusercontent.com/static/fonts/roboto/v11/2UX7WLTfW3W8TclTUvlFyQ.woff)
       format('woff');"))];

    .sp.h.sdk.define_func["initSpComplete()"] "{
                       var btn = document.getElementsByName('spDoAuthBtn')[0];
                       btn.innerHTML = 'Sign In';
                       btn.disabled = false; 
                   }";

    .sp.h.sdk.define_func["onSPApiReady()"] "{
                        initSpComplete();
                   }";

    .sp.h.sdk.define_func["processTimer(rid)"] "{
                        console.log('timer hit, checking auth request ' + rid);    
                        spCheckAuth(rid, 
                            function(resp) {
                                var res = resp.result.status;         
                                if( res == 'pending' ) {
                                    console.log('status is pending, waiting for another round...');
                                    var timer = window.setTimeout(function() {processTimer(rid) }, 5000);            
                                    return;
                                }
                        
                                if( res == 'expired' ) {
                                    console.log('request expired!!');
                                    alert('request expired!');
                                    var btn = document.getElementsByName('spDoAuthBtn')[0]; 
                                    btn.innerHTML = 'Retry'
                                    btn.disabled = false;
                                    return;
                                }

                                // SUCCESS
                                if( resp.result.value < 80.0 ) {
                                    console.log('weak attempt!!');
                                    alert('request rejected!');
                                    var btn = document.getElementsByName('spDoAuthBtn')[0]; 
                                    btn.innerHTML = 'Retry'
                                    btn.disabled = false;
                                    return;
                                }

                                var allbtns = window.parent.document.getElementsByClassName('btn');
                                for( var btn in allbtns ) {
                                    allbtns[btn].disabled = false;
                                    var bbtn = document.getElementsByName('spDoAuthBtn')[0]; 
                                    bbtn.innerHTML = 'Signed In'
                                    bbtn.disabled = true;
                                }
                            }, 
                            function(reason) {
                                console.log('Error: ' + reason.result.error.message);
                                alert(reason.result.error.message);
                                var btn = document.getElementsByName('spDoAuthBtn')[0]; 
                                btn.innerHTML = 'Retry'
                                btn.disabled = false;

                            });
                       }";

    .sp.h.sdk.define_func["spDoAuth()"] "{
                        var uid = document.getElementsByName('spUserId')[0].value;
                        if( uid.length <= 0 || uid.indexOf('@') == -1 ) {
                            alert('user is is not correctly formatted!');
                            return;
                        }
                        
                        console.log('spDoAuth- calling spapi.spAuth');
                        spAuth(uid,'signpass.spview','SPView Login', 
                            function(resp) {
                                var rid = resp.result.request_id;
                                console.log('auth request complete - token: ' + rid); 
                                var btn = document.getElementsByName('spDoAuthBtn')[0]; 
                                btn.innerHTML = 'Authenticating...'
                                btn.disabled = true;
                                window.setTimeout(function() {processTimer(rid) }, 5000);                                                                
                            }, 
                            function(reason) {
                                console.log('Error: ' + reason.result.error.message);
                                alert(reason.result.error.message);
                            });
                   }";

    .sp.h.sdk.style[(("border";"1px none red");
                     ("color";"#48a0dc");
                     ("font-size";"80px");
                     ("font-family";"Roboto");
                     ("text-shadow";"rgb(71, 71, 71) 3px 5px 2px");
                     ("position";"absolute");
                     ("text-align";"center");
                     ("width";"99%");
                     ("top";"10%"))]
    .sp.h.sdk.inner_html["Greetings of Joy!"]
    .sp.h.sdk.create[`div];

    .sp.h.sdk.style[(("border";"1px none red");
                     ("color";"#48a0dc");
                     ("font-size";"30px");
                     ("font-family";"Roboto");
                     ("text-shadow";"rgb(71, 71, 71) 1px 1px 1px");
                     ("position";"absolute");
                     ("text-align";"center");
                     ("width";"99%");
                     ("top";"30%"))]
    .sp.h.sdk.inner_html["Welcome to the SignPass Research and Operations Platform. Please Sign-in to Begin."]
    .sp.h.sdk.create[`div];

    otmp:
    .sp.h.sdk.style[(("border";"1px none red");
                     ("color";"#48a0dc");
                     ("font-size";"30px");
                     ("font-family";"Roboto");
                     ("text-shadow";"rgb(71, 71, 71) 1px 1px 1px");
                     ("position";"absolute");
                     ("text-align";"center");
                     ("width";"99%");
                     ("top";"40%"))]
    .sp.h.sdk.create[`div];

    ospd:
    .sp.h.sdk.add_item[otmp]
    .sp.h.sdk.style[(("border";"2px solid red");
                     ("border-radius";"40px");
                     ("color";"#48a0dc");
                     ("font-size";"30px");
                     ("font-family";"Roboto");
                     ("text-shadow";"rgb(71, 71, 71) 1px 1px 1px");
                     ("text-align";"center");
                     ("margin-left";"25%");
                     ("padding-top";"10px");
                     ("padding-bottom";"10px");
                     ("width";"50%"))]
    .sp.h.sdk.create[`div];

    .sp.h.sdk.add_item[ospd]
    .sp.h.sdk.style[(("border-radius";"20px");            
                     ("font-size";"30px");
                     ("align-content";"center");
                     ("text-align";"center");
                     ("width";"80%"))]
    .sp.h.sdk.add_attrib["name";"spUserId"]
    .sp.h.sdk.add_attrib["type";"text"]
    .sp.h.sdk.create[`input];

    .sp.h.sdk.add_item[ospd]
    .sp.h.sdk.style[(enlist ("width";"80%"))]
    .sp.h.sdk.inner_html["Initializng Api..."]
    .sp.h.sdk.add_attrib["class";"btn"]
    .sp.h.sdk.add_attrib["disabled";"true"]
    .sp.h.sdk.add_attrib["name";"spDoAuthBtn"]
    .sp.h.sdk.add_event[`onclick;"spDoAuth();"]
    .sp.h.sdk.create[`button];

    if[(last `$(system "hostname")) = `spdev1;
        .sp.h.sdk.add_attrib["name";"qa_mode"]
        .sp.h.sdk.create[`div];
    ];


    };

.sp.html.handlers[`welcome.q]: `.view.welcome;
