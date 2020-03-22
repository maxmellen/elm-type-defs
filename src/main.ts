interface Flags {
  title: string;
}

type IncomingPorts = {
  localStorageGetResp: {
    value: string;
  };
};

type OutgoingPorts = {
  localStorageGetReq: {
    key: string;
  };
  localStorageSet: {
    key: string;
    value: string;
  };
};

let elmDiv = document.createElement("div");
document.body.appendChild(elmDiv);

let app = Elm.Main.init<Flags, IncomingPorts, OutgoingPorts>({
  node: elmDiv,
  flags: { title: "Elm Type Definitions" }
});

app.ports.localStorageGetReq.subscribe(({ key }) => {
  app.ports.localStorageGetResp.send({
    value: localStorage.getItem(key) || ""
  });
});

app.ports.localStorageSet.subscribe(({ key, value }) => {
  localStorage.setItem(key, value);
});
