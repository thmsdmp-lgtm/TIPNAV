
fetch("./ui/index.html")
    .then(response => response.text())
    .then(html => {
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, "text/html");

        // Append HTML-2's body elements to HTML-1
        document.body.append(...doc.body.children);
    })
    .catch(error => console.error("Failed to load UI:", error));
