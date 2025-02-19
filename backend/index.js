const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const app = express();
app.use(cors());
app.use(express.json());

app.post('/submit_code', (req, res) => {
    const { code } = req.body;
    if (!code) {
        return res.status(400).json({ message: "Code is required" });
    }

    console.log("Received code:", code);

    // Save the C code to a temporary file
    const filePath = path.join(__dirname, 'temp_code.c');
    fs.writeFileSync(filePath, code);

    // Compile the C code using GCC
    const outputExecutable = path.join(__dirname, 'temp_program');
    const compileCommand = `gcc ${filePath} -o ${outputExecutable} 2>&1`;

    exec(compileCommand, (compileError, compileStdout, compileStderr) => {
        if (compileError) {
            console.error(`Compilation error: ${compileStderr}`);
            return res.status(400).json({ message: "Compilation failed", error: compileStderr });
        }

        // Run the compiled program
        exec(outputExecutable, (runError, runStdout, runStderr) => {
            if (runError) {
                console.error(`Runtime error: ${runStderr}`);
                return res.status(400).json({ message: "Execution failed", error: runStderr });
            }

            // Return the program output
            res.json({ message: "Execution successful", output: runStdout });
        });
    });
});

app.listen(2000, () => {
    console.log("Server running on port 2000");
});