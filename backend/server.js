const express = require("express");
const http = require("http");
const cors = require("cors");
const routes = require("./routes"); // API endpointy
const { initializeSocket } = require("./socket"); // Socket.IO logika
const bodyParser = require('body-parser');
const authRoutes = require('./authRoutes');

const app = express();
const server = http.createServer(app);
app.use(cors({
    origin: "*",  // Alebo špecifické povolené domény
    methods: ["GET", "POST"],
}));
app.use(express.json());
app.use(routes); // Registrácia API endpointov
app.use(bodyParser.json());
app.use('/auth', authRoutes);

initializeSocket(server); // Inicializácia Socket.IO

server.listen(3000, () => console.log("Server running on port 3000"));
