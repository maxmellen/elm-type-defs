"use strict";
(() => {
    let elmDiv = document.createElement("div");
    document.body.appendChild(elmDiv);
    let script = document.getElementById("elm-d-ts");
    let lines = script.textContent.split("\n").slice(1);
    let sourceCode = lines.map(l => l.slice(lines[0].search(/\b/))).join("\n");
    let app = Elm.Main.init({
        node: elmDiv,
        flags: { title: "Elm Type Definitions", sourceCode }
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
