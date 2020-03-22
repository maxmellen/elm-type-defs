declare namespace Elm {
  type IncomingPorts<T> = {
    [P in keyof T]: {
      send(message: T[P]): void;
    };
  };

  type OutgoingPorts<T> = {
    [P in keyof T]: {
      subscribe(handler: (message: T[P]) => void): void;
      unsubscribe(handler: (message: T[P]) => void): void;
    };
  };

  type Ports<In, Out> = IncomingPorts<In> & OutgoingPorts<Out>;

  type App<In, Out> = keyof Ports<In, Out> extends never
    ? {}
    : { ports: Ports<In, Out> };
}

declare var Elm: {
  Main: {
    init<Flags = void, IncomingPorts = {}, OutgoingPorts = {}>(
      options: { node: HTMLElement } & (Flags extends void
        ? {}
        : { flags: Flags })
    ): Elm.App<IncomingPorts, OutgoingPorts>;
  };
};
