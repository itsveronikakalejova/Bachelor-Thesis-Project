const express = require("express");
const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");
const router = express.Router();

router.post("/submit-code", (req, res) => {
    const { code } = req.body;

    if (!code) {
        return res.status(400).json({ message: "Kód je povinný." });
    }

    const filePath = path.join(__dirname, "temp_code.c");
    fs.writeFileSync(filePath, code);

    const outputExecutable = path.join(__dirname, "temp_program");
    const compile = spawn("gcc", [filePath, "-o", outputExecutable]);

    let compileError = "";
    compile.stderr.on("data", (data) => {
        compileError += data.toString();
    });

    compile.on("close", (exitCode) => {
        if (exitCode !== 0) {
            console.error("Chyba pri kompilácii:", compileError);
            return res.status(400).json({
                message: "Kompilácia zlyhala.",
                success: false,
                error: compileError
            });
        }

        console.log("Kompilácia prebehla úspešne.");
        return res.json({
            message: "Kompilácia bola úspešná.",
            success: true
        });
    });
});

module.exports = router;
