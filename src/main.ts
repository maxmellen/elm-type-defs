(() => {
  type ElmInit = {
    flags: {
      title: string;
      filenames: string[];
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

  let app = Elm.Main!.init<ElmInit>({
    node: elmDiv,
    flags: {
      title: "Elm Type Definitions",
      filenames: ["elm.d.ts", "main.ts", "Main.elm"]
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
