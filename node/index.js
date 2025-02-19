const express = require("express");
const cors = require("cors");
const fs = require("fs");
const { exec, spawn } = require("child_process");

const app = express();
app.use(cors());
app.use(express.json());

app.post("/submit_code", (req, res) => {
    const { code, input } = req.body; // Prijímame kód a vstup
    const filePath = "program.c";
    const executable = "program.exe"; // Pre Windows

    // Uloženie kódu do súboru
    fs.writeFileSync(filePath, code);

    // Kompilácia C kódu
    exec(`gcc ${filePath} -o ${executable}`, (error, stdout, stderr) => {
        if (error) {
            return res.json({ success: false, output: stderr }); // Chyba kompilácie
        }

        // Ak je kompilácia úspešná, spustíme program
        const process = spawn(`./${executable}`);

        let output = "";

        // Pošleme vstup do stdin
        process.stdin.write(input + "\n");
        process.stdin.end();

        // Získame výstup zo stdout
        process.stdout.on("data", (data) => {
            output += data.toString();
        });

        // Ak sú chyby, pridáme ich do výstupu
        process.stderr.on("data", (data) => {
            output += data.toString();
        });

        // Po skončení procesu pošleme výsledok späť do Flutteru
        process.on("close", () => {
            res.json({ success: true, output });
        });
    });
});

app.listen(2000, () => {
    console.log("Server running on port 2000");
});
