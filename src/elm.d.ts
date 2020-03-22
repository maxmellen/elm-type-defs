declare namespace Elm {
  type App = {};
}

declare var Elm: {
  Main: {
    init<Flags = void>(
      options: { node: HTMLElement } & (Flags extends void
        ? {}
        : { flags: Flags })
    ): Elm.App;
  };
};
