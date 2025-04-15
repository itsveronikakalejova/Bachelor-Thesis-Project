const { Server } = require("socket.io");

let documents = {}; 

const activeFiles = new Map();

function initializeSocket(server) {
    const io = new Server(server, {
        cors: {
            origin: "*",
            methods: ["GET", "POST"]
        }
    });
    io.on('connection', (socket) => {
        socket.on('open-file', (fileId) => {
          if (!activeFiles.has(fileId)) {
            activeFiles.set(fileId, new Set());
          }
          activeFiles.get(fileId).add(socket.id);
          socket.join(`file-${fileId}`); 
        });
      
        socket.on('close-file', (fileId) => {
          if (activeFiles.has(fileId)) {
            activeFiles.get(fileId).delete(socket.id);
          }
          socket.leave(`file-${fileId}`);
        });
      
        socket.on('file-update', ({ fileId, content }) => {
          socket.to(`file-${fileId}`).emit('file-changed', { fileId, content });
        });
      });
}

module.exports = { initializeSocket };
