const express = require("express");
// const compileAndRun = require("./compiler"); // Kompilácia C kódu

const router = express.Router();

// Úvodný endpoint
router.get("/", (req, res) => {
    res.send("Welcome to the Project Sharing Platform API!");
});

// // Endpoint na kompiláciu kódu
// router.post("/submit_code", (req, res) => {
//     const { code, input } = req.body;

//     if (!code) {
//         return res.status(400).json({ message: "Code is required" });
//     }

//     console.log("Received code:", code);
//     console.log("Received input:", input);

//     compileAndRun(code, input, (error, result) => {
//         if (error) {
//             return res.status(400).json({ message: error.error, details: error.details });
//         }
//         res.json({ message: "Execution successful", output: result.output });
//     });
// });

module.exports = router