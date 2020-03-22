let p = document.createElement("p");
p.textContent = "Hello, TypeScript";
document.body.appendChild(p);

let elmDiv = document.createElement("div");
document.body.appendChild(elmDiv);

interface Flags {
  foo: string;
  bar: number;
}

let app = Elm.Main.init<Flags>({
  node: elmDiv,
  flags: { foo: "foobar", bar: 42 }
});
