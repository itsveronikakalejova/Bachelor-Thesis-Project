const express = require("express");
const compileAndRun = require("./compiler");

const router = express.Router();

router.post("/submit_code", (req, res) => {
    const { code, input } = req.body;

    if (!code) {
        return res.status(400).json({ message: "Kod je povinny." });
    }

    console.log("Prijaty kod:", code);
    console.log("Prijaty input:", input);

    compileAndRun(code, input, (error, result) => {
        if (error) {
            return res.status(400).json({ message: error.error, details: error.details });
        }
        res.json({ message: "Spustenie uspesne.", output: result.output });
    });
});

module.exports = router