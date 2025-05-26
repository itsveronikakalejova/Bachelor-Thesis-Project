const express = require("express");
const http = require("http");
const cors = require("cors");
const bodyParser = require('body-parser');

const { initializeSocket } = require("./socket/socketInitialization"); 

const authRoutes = require('./routes/authRoutes');
const projectsRoutes = require('./routes/projectsRoutes');
const shareRoutes = require('./routes/shareRoutes'); 
const tasksRoutes = require('./routes/tasksRoutes');
const messagesRoutes = require('./routes/messagesRoutes');
const compileRoutes = require('./routes/compileRoutes');

const app = express();
const server = http.createServer(app);

app.use(cors({
    origin: "*",
    methods: ["GET", "POST"],
}));

app.use(express.json());
app.use(bodyParser.json());
app.use('/auth', authRoutes);
app.use('/', projectsRoutes);
app.use('/share', shareRoutes); 
app.use('/tasks', tasksRoutes);
app.use('/messages', messagesRoutes);
app.use('/compile', compileRoutes);

initializeSocket(server); 

server.listen(3000, () => console.log("Server runs on port 3000."));
