"use strict";
(() => {
    let elmDiv = document.createElement("div");
    document.body.appendChild(elmDiv);
    let app = Elm.Main.init({
        node: elmDiv,
        flags: {
            title: "Elm Type Definitions",
            filenames: ["elm.d.ts", "main.ts", "Main.elm", "not_found.txt"]
        }
    });
    app.ports.localStorageGetReq.subscribe(({ key }) => {
        app.ports.localStorageGetResp.send({
            value: localStorage.getItem(key) || ""
        });
    });
    app.ports.localStorageSet.subscribe(({ key, value }) => {
        localStorage.setItem(key, value);
    });
    app.ports.localStorageClear.subscribe(() => {
        localStorage.clear();
    });
})();
