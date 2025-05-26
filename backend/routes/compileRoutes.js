const express = require('express');
const db = require('../database/db'); 
const router = express.Router();
const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");

router.post("/submit-code", (req, res) => {
    const { code } = req.body;

    if (!code) {
        return res.status(400).json({ message: "Code is required." });
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
            console.error("Error while compiling:", compileError);
            return res.status(400).json({
                message: "Compilation failed.",
                success: false,
                error: compileError
            });
        }

        return res.json({
            message: "Compilation was successful.",
            success: true
        });
    });
});

module.exports = router;
