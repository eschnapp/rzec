    var glb_data_sigs;
    var glb_table;
    var glb_tbl_select_callback;

    var all_data_tables = new Array();
    var all_charts = new Array();
    var all_data_views = new Array();
    
    function init_script(){
        console.log("Initializing all the charts!!");
        init_google();
    };
    
    function init_google() {
      console.log("initializing the google visualization api...");
       google.load("visualization", "1", {packages:["table", "scatter", "corechart"], callback: init_google_complete});
       google.setOnLoadCallback(init_google_complete);
    };
    
    function init_google_complete(){
        console.log("google visualization api complete!");
        processAllCharts();
    };
    
    function processAllCharts() {
    
        var elements = document.getElementsByTagName("div");
        var charts = [];
        for( i = 0; i < elements.length; i++ ) {
            if(elements[i].hasAttribute("data-type")) {
                if((elements[i].getAttribute("data-type") == "chart") || (elements[i].getAttribute("data-type") == "table") ) {
                    charts.push(elements[i]);                
                    console.log("Found Chart at element with index " + i);   
                }
            }
        }
        
        console.log("Found " + charts.length + " charts - processing them now...");
        for( iu = 0; iu < charts.length; iu++ ) {
            // new version!!
            if( charts[iu].hasAttribute("data-name") == true ) {
                var funcName = "draw_" + charts[iu].getAttribute("data-name");
                window[funcName]();
            }        
            
            if( charts[iu].hasAttribute("data-sub") == true ) {
                var key = charts[iu].getAttribute("data-sub");
                console.log("Adding chart sub-handler for key " + key + " and name " + charts[iu].getAttribute("data-name"));
                if( !(key in all_sub_handlers) ) {
                    all_sub_handlers[key] = new Array();
                }
                
                all_sub_handlers[key].push(charts[iu].getAttribute("data-name"));
            }
        }
    }
   
    
    
    function onTableSelect() {
        var row = glb_table.getSelection();
        console.log("SELECTION: " + row[0]);
        
        //window.open("sig.q?sample_id="+row[0],"", {location: 0, menubar: 0, status : 0, titlebar: 0, toolbar: 0 });
    }
    


    

