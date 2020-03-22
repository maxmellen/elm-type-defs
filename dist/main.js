"use strict";
(() => {
    let elmDiv = document.createElement("div");
    document.body.appendChild(elmDiv);
    let sourceFiles = ["elm.d.ts", "main.ts", "Main.elm"].map(name => {
        let extension = name.match(/\.(\w+)$/)[1];
        console.log({ name, matches: name.match(/\.(\w+)$/), extension });
        let mode = (() => {
            switch (extension) {
                case "ts":
                    return "javascript";
                case "elm":
                    return "elm";
                default:
                    throw new Error(`Unexpected file extension (.${extension}).`);
            }
        })();
        let elementId = name.toLowerCase().replace(/\./g, "-");
        let content = readEmbeddedSourceCode(elementId);
        return { name, content, mode };
    });
    let app = Elm.Main.init({
        node: elmDiv,
        flags: { title: "Elm Type Definitions", sourceFiles }
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
    function readEmbeddedSourceCode(elementId) {
        let scriptElement = document.getElementById(elementId);
        if (!scriptElement) {
            throw new Error(`Could not find script tag #${elementId}.`);
        }
        let lines = scriptElement.textContent.split("\n").slice(1);
        let indent = lines[0].search(/[^\s]/);
        return lines.map(l => l.slice(indent)).join("\n");
    }
})();
