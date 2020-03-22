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

  type Flags<T extends Init> = T extends Init<infer F> ? F : never;

  type Ports<T extends Init> = T extends Init<any, infer In, infer Out>
    ? IncomingPorts<In> & OutgoingPorts<Out>
    : never;

  type Init<Flags = void, In = {}, Out = {}> = (Flags extends void
    ? {}
    : { flags: Flags }) &
    (keyof (IncomingPorts<In> & OutgoingPorts<Out>) extends never
      ? {}
      : {
          ports: (keyof In extends never ? {} : { incoming: In }) &
            (keyof Out extends never ? {} : { outgoing: Out });
        });

  type App<Ports> = keyof Ports extends never ? {} : { ports: Ports };

  type Module = {
    init<T extends Init>(
      options: { node: HTMLElement } & (Flags<T> extends void
        ? {}
        : { flags: Flags<T> })
    ): App<Ports<T>>;
  };
}

declare var Elm: {
  [module: string]: Elm.Module | undefined;
};
