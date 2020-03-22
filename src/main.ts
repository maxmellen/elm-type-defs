(() => {
  type ElmInit = {
    flags: {
      title: string;
      sourceCode: string;
    };
    ports: {
      incoming: {
        localStorageGetResp: { value: string };
      };
      outgoing: {
        localStorageGetReq: { key: string };
        localStorageSet: { key: string; value: string };
        localStorageClear: null;
      };
    };
  };

  let elmDiv = document.createElement("div");
  document.body.appendChild(elmDiv);

  let script = document.getElementById("elm-d-ts")!;
  let lines = script.textContent!.split("\n").slice(1);
  let sourceCode = lines.map(l => l.slice(lines[0].search(/[^\s]/))).join("\n");

  let app = Elm.Main!.init<ElmInit>({
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
