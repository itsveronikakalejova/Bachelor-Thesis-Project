const express = require("express");
const http = require("http");
const cors = require("cors");
const routes = require("./controllers/routes");
const { initializeSocket } = require("./controllers/socket"); 
const bodyParser = require('body-parser');
const authRoutes = require('./database/authRoutes');
const projectsRoutes = require('./database/projectsRoutes');
const userRoutes = require('./database/userRoutes'); 
const shareProjectRoutes = require('./controllers/shareProject'); 
const tasksRoutes = require('./database/tasks');

const app = express();
const server = http.createServer(app);
app.use(cors({
    origin: "*",
    methods: ["GET", "POST"],
}));
app.use(express.json());
app.use(routes); 
app.use(bodyParser.json());
app.use('/auth', authRoutes);
app.use('/', projectsRoutes);
app.use('/api', userRoutes); 
app.use(shareProjectRoutes); 
app.use('/tasks', tasksRoutes);

initializeSocket(server); 

server.listen(3000, () => console.log("Server bezi na porte 3000."));
