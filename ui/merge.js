
const iframe = document.createElement("iframe");

iframe.src = "./index.html";

Object.assign(iframe.style, {
    position: "fixed",
    inset: "0",
    width: "100%",
    height: "100%",
    border: "none",
    zIndex: "1000",
    background: "transparent"
});

document.body.appendChild(iframe);
