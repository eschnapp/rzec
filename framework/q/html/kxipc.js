
var all_sockets = new Array();
var all_subs = new Array();
var all_sub_handlers = new Array();

function init_kx_ipc() {

    console.log("initializing all data subscriptions");
    var elements = document.getElementsByTagName("x-sub");
    var subs = [];
    for( i = 0; i < elements.length; i++ ) {
        subs.push(elements[i]);                
        console.log("Found x-sub at element with index " + i);       
    }
    
    console.log("Found " + subs.length + " subs - processing them now...");
    for( iu = 0; iu < subs.length; iu++ ) {
        if( subs[iu].hasAttribute("service") == false ) {
            console.log("cannot process subscription without service attribute, id: " + subs[iu].getAttribute("id"));
            continue;
        }
        if( subs[iu].hasAttribute("topic") == false ) {
            console.log("cannot process subscription without topic attribute, id: " + subs[iu].getAttribute("id"));
            continue;
        }
        if( subs[iu].hasAttribute("uri") == false ) {
            console.log("cannot process subscription without uri attribute, id: " + subs[iu].getAttribute("id"));
            continue;
        }        

        if( subs[iu].hasAttribute("filter") == false ) {
            console.log("cannot process subscription without filter attribute, id: " + subs[iu].getAttribute("id"));
            continue;
        } 
        
        var svc = subs[iu].getAttribute("service");
        var topic = subs[iu].getAttribute("topic");
        var uri = subs[iu].getAttribute("uri");
        var filter = subs[iu].getAttribute("filter");
        var key = svc + "." + topic;
        //all_subs[key] = new google.visualization.DataTable();
        
        var upd = function(packet) {
            var type = packet[0];
            var svc = packet[1];
            var topic = packet[2];
            var data = packet[3];            
            var key = svc + "." + topic;
            
            var ar = new Array();
            var Hrow = new Array();
            for( hdrK in data[0] ) {
                Hrow.push(hdrK);
            };
            ar.push(Hrow);
            for( rowK in data ) {
                var row = new Array();
                for( cellK in data[rowK] ) {
                    var v = data[rowK][cellK];
                    row.push(v);
                }
                ar.push( row );
            }

            var tbl = google.visualization.arrayToDataTable(ar);

  //          if( !(key in all_subs) ) {
  //              all_subs[key] = tbl;
  //          }
  //          
  //          tbl = all_subs[key];
            
              
            all_subs[key] = tbl;
            
            if( key in all_sub_handlers ) {
                for( h in all_sub_handlers[key] ) {
                    var nm = all_sub_handlers[key][h];
                    all_data_tables[nm] = tbl;
                    var fname = "redraw_" + nm;
                    window[fname]();
                }
            }
        };
        
        
        kxSubscribe(uri, svc, topic, filter, upd, upd);
    }
        
        

}

function kxSubscribe(wsUri, svc, topic, filter,recFunc, updFunc) {
    
    var packet = ["sub",svc,topic,filter];
    var payload = serialize(packet);
    var websocket = createWebsocket(wsUri, payload, recFunc, updFunc);
    
    }

function kxUnsubscribe(wsUri, svc, topic) {
    
    var packet = ["unsub",svc,topic];
    var payload = serialize(packet);
    var websocket = findWebsocket(wsUri);
    websocket.send( payload );
    }    

function findWebsocket(wsUri) { 
    if( wsUri in all_sockets ) {
        return all_sockets[wsUri];
        }
    }      
    
function createWebsocket(wsUri, onopen, recFunc, updFunc) { 
    
    if( wsUri in all_sockets ) {
        return all_sockets[wsUri];
        }
        
    websocket = new WebSocket(wsUri); 
    websocket.binaryType = 'arraybuffer';
    websocket.open_payload  = onopen;
    websocket.rec_func = recFunc;
    websocket.upd_func = updFunc;
    websocket.onopen = function(evt) { onWebsockOpen(this,evt) }; 
    websocket.onclose = function(evt) { onWebsockClose(this,evt) }; 
    websocket.onmessage = function(evt) { onWebsockMessage(this,evt) }; 
    websocket.onerror = function(evt) { onWebsockError(this,evt) }; 
    all_sockets[wsUri] = websocket;
    return websocket;
    }  

function onWebsockOpen(ws,evt) { 
    console.log("WebSocket OPEN event: " + ws.url.toString());
    ws.send(ws.open_payload);
    }  

function onWebsockClose(ws,evt) { 
    console.log("WebSocket CLOSE event: " + ws.url.toString());
    delete all_sockets[ws.url.toString()];
    }  

function onWebsockMessage(ws,evt) { 
    var payload = evt.data;
    var packet = deserialize(payload);
    if( packet.length > 1 ) {
        if( packet[0] == "update" ) {
            console.log("Received WebSocket UPDATE packet");
            ws.upd_func(packet);
        
        } else if( packet[0] == "recover" ) {
            console.log("Received WebSocket RECOVER packet");        
            ws.rec_func(packet);
        } else {
            console.log("Received WebSocket UNKNOWN packet, type: " + packet[0]);        
        
        }
    }
}  

function onWebsockError(ws,evt) { 
    console.log("WebSocket ERROR event: [" + ws.url.toString() + "] with Data: " + evt.data);
    }  

function doSend(message) { 
    
    }