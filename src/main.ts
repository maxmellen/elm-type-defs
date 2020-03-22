(() => {
  type ElmInit = {
    flags: {
      title: string;
      sourceFiles: { name: string; content: string }[];
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

  let sourceFiles = ["elm.d.ts", "main.ts"].map(name => {
    let elementId = name.replace(/\./g, "-");
    let content = readEmbeddedSourceCode(elementId);
    return { name, content };
  });

  let app = Elm.Main!.init<ElmInit>({
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

  function readEmbeddedSourceCode(elementId: string) {
    let scriptElement = document.getElementById(elementId);
    if (!scriptElement) {
      throw new Error(`Could not find script tag #${elementId}.`);
    }
    let lines = scriptElement.textContent!.split("\n").slice(1);
    let indent = lines[0].search(/[^\s]/);
    return lines.map(l => l.slice(indent)).join("\n");
  }
})();
