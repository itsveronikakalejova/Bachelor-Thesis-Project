const express = require('express');     // webovy ramec pre API poziadavky
const cors = require('cors');           // middleware, pre Flutter aplikaciu
const routes = require('./routes');     // importuje cesty, kde su vsetky API endpointy

const app = express();                  // inicializujeme Express aplikaciu
app.use(cors());                        // povoli cross-origin poziadavky
app.use(express.json());                // pracuje s JSON poziadavkami, flutter do backendu
app.use(routes);                        // pripajame cesty

// zapneme server, ktory caka na prichadzajuce ziadosti
app.listen(2000, () => {
    console.log("Server running on port 2000");
});