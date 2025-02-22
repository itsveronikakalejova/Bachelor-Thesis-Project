const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { spawn } = require("child_process");

const app = express();
app.use(cors());
app.use(express.json());


app.post("/submit_code", (req, res) => {
    const { code } = req.body;
    if (!code) {
        return res.status(400).json({ message: "Code is required" });
    }

    console.log("Received code:", code);

    const filePath = path.join(__dirname, "temp_code.c");
    fs.writeFileSync(filePath, code);

    const outputExecutable = path.join(__dirname, "temp_program");
    const compile = spawn("gcc", [filePath, "-o", outputExecutable]);

    let compileError = "";
    compile.stderr.on("data", (data) => {
        compileError += data.toString();
    });

    compile.on("close", (code) => {
        if (code !== 0) {
            console.error("Compilation error:", compileError);
            return res.status(400).json({ message: "Compilation failed", error: compileError });
        }

        console.log("Compilation successful");

        const run = spawn(outputExecutable);
        let runOutput = "";
        let runError = "";

        run.stdout.on("data", (data) => {
            runOutput += data.toString();
        });

        run.stderr.on("data", (data) => {
            runError += data.toString();
        });

        run.on("close", (code) => {
            if (code !== 0) {
                console.error("Runtime error:", runError);
                return res.status(400).json({ message: "Execution failed", error: runError });
            }

            res.json({ message: "Execution successful", output: runOutput });
        });
    });
});


app.listen(2000, () => {
    console.log("Server running on port 2000");
});