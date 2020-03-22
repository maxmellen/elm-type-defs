let p = document.createElement("p");
p.textContent = "Hello, TypeScript";
document.body.appendChild(p);

let elmDiv = document.createElement("div");
document.body.appendChild(elmDiv);

let app = Elm.Main.init({ node: elmDiv });
console.log(app);
