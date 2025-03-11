const express = require('express');             // webovy ramec pre API poziadavky
const compileAndRun = require('./compiler');    // funkcia z compiler.js

const router = express.Router();                // definujeme cesty osobitne a pripajame k hlavnemu serveru

//tato cesta prijima kod z frontendu a kompiluje ho
router.post("/submit_code", (req, res) => {
    const { code, input } = req.body;
    // ak nie je prijaty ziaden kod, vratime chybu
    if (!code) {
        return res.status(400).json({ message: "Code is required" });
    }

    // logy
    console.log("Received code:", code);
    console.log("Received input:", input);

    // posleme C kod do GCC kompilatora
    compileAndRun(code, input, (error, result) => {
        // riesime chyby pri kompilacii/spustani
        if (error) {
            return res.status(400).json({ message: error.error, details: error.details });
        }
        // posli vystup spat do Flutter aplikacie
        res.json({ message: "Execution successful", output: result.output });
    });
});

// exportuj cestu aby sa dala pouzit v index.js
module.exports = router;