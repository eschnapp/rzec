.view.mainframe:{[request]

//    .sp.h.sdk.body_attribs[(`background;`$"background-size")!("bg.jpg";"cover")]
    .sp.html.response[`title]: "SP Research and Development Platform";
    .sp.h.sdk.define_style["html, body";
             (("border";"1px none  black");
              ("height";"100vh");
              ("width";"100vw");
              ("background";"url(bg.jpg);");
              ("background-size";"100% 100%"))];

    .sp.h.sdk.define_func["openWnd(url)"] "{
                    // window.open(url,\"subframe\", \"location: 0, menubar: 0, status : 0, titlebar: 0, toolbar: 0 \");
                    document.getElementsByName('subframe')[0].src = url;
                   }";

    .sp.h.sdk.define_func["onSPApiReady()"] "{
                    window.subframe.initSpComplete();
                    }";

    icol: "#48a0dc";
    if[ .sp.ns.client.zone in (`research`test`qa); icol: "red"; ];


    omframe:
    .sp.h.sdk.style[(("border";raze ("4px solid ", icol));
                     ("border-radius";"20px");
                     ("position";"absolute");
                     ("background";"white");
                     ("padding";"10px 20px 10px 10px");
                     ("left";"15vw");
                     ("top";"15vh"))]
    .sp.h.sdk.size["70vw";"70vh"]
    .sp.h.sdk.create[`div];

    .sp.h.sdk.add_item[omframe]
    .sp.h.sdk.size["100%";"100%"]
    .sp.h.sdk.add_attrib["src";"welcome.q"]
    .sp.h.sdk.add_attrib["name";"subframe"]
    .sp.h.sdk.style[(("border";"1px none red");
                     ("position";"relative");
                     ("display";"inline-block");
                     ("margin";"1px"))]
    .sp.h.sdk.create[`iframe];

    osb:
    .sp.h.sdk.style[(("border";"1px none green");
                     ("position";"relative");
                     ("display";"inline-block");
                     ("width";"14vw");
                     ("float";"left");
                     ("top";"15vh");
                     ("height";"70vh"))]
    .sp.h.sdk.create[`div];

    .sp.h.sdk.add_item[osb]
    .sp.h.sdk.inner_html["Realtime Monitor"]
    .sp.h.sdk.add_attrib["class";"btn"]
    .sp.h.sdk.add_attrib["disabled";"true"]
    .sp.h.sdk.add_event[`onclick;"openWnd('livemon.q');"]
    .sp.h.sdk.create[`button];

    .sp.h.sdk.add_item[osb]
    .sp.h.sdk.inner_html["Feature Overview"]
    .sp.h.sdk.add_attrib["class";"btn"]
    .sp.h.sdk.add_attrib["disabled";"true"]
    .sp.h.sdk.add_event[`onclick;"openWnd('fo.q');"]
    .sp.h.sdk.create[`button];

    .sp.h.sdk.add_item[osb]
    .sp.h.sdk.inner_html["User Params Editor"]
    .sp.h.sdk.add_attrib["class";"btn"]
    .sp.h.sdk.add_attrib["disabled";"true"]
    .sp.h.sdk.add_event[`onclick;"openWnd('user.q');"]
    .sp.h.sdk.create[`button];

    .sp.h.sdk.add_item[osb]
    .sp.h.sdk.inner_html["Sample Explorer"]
    .sp.h.sdk.add_attrib["class";"btn"]
    .sp.h.sdk.add_attrib["disabled";"true"]
    .sp.h.sdk.add_event[`onclick;"openWnd('main.q');"]
    .sp.h.sdk.create[`button];

    .sp.h.sdk.add_item[osb]
    .sp.h.sdk.inner_html["System Configuration"]
    .sp.h.sdk.add_attrib["class";"btn"]
    .sp.h.sdk.add_attrib["disabled";"true"]
    .sp.h.sdk.add_event[`onclick;"openWnd('cfgedit.q');"]
    .sp.h.sdk.create[`button];

    .sp.h.sdk.add_item[osb]
    .sp.h.sdk.inner_html["Algo"]
    .sp.h.sdk.add_attrib["class";"btn"]
    .sp.h.sdk.add_attrib["disabled";"true"]
    .sp.h.sdk.add_event[`onclick;"openWnd('model.q');"]
    .sp.h.sdk.create[`button];

    if[(last `$(system "hostname")) = `research;
        .sp.h.sdk.add_attrib["name";"qa_mode"]
        .sp.h.sdk.create[`div];
    ];

    };

.sp.html.handlers[`mainframe.q]: `.view.mainframe;