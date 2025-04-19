const fs = require('fs');
const path = require('path');
const { spawn } = require("child_process");

function compileCode(code, callback) {
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
            return callback({ error: "Compilation failed", details: compileError }, null);
        }
        callback(null, { message: "Compilation successful" });
    });
}

module.exports = compileCode;