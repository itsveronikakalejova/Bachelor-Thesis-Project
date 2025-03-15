const { Server } = require("socket.io");

let documents = {}; 

function initializeSocket(server) {
    const io = new Server(server, {
        cors: {
            origin: "*",
            methods: ["GET", "POST"]
        }
    });

    io.on("connection", (socket) => {
        console.log("Pripojeny pouzivatel:", socket.id);

        socket.on("join-document", (docId) => {
            socket.join(docId);
            if (!documents[docId]) {
                documents[docId] = { content: "" };
            }
            socket.emit("load-document", documents[docId].content);
        });

        socket.on("update-document", ({ docId, content }) => {
            if (documents[docId]) {
                documents[docId].content = content;
                socket.to(docId).emit("update-document", content);
            }
        });

        socket.on("disconnect", () => {
            console.log("Odpojeny pouzivatel:", socket.id);
        });
    });
}

module.exports = { initializeSocket };
