// const fs = require('fs');                   // pouzijeme na zapisanie C kodu do priebezneho suboru
// const path = require('path');               // pomaha spravovat cesty k suborom
// const { spawn } = require("child_process"); // spusta systemove prikazy

// // code = dany C kod prijaty od pouzivatela
// // callback = funckia, ktora bude volana ked kompilacia a spustenie skonci
// function compileAndRun(code, input, callback) {
//     // ulozime prijaty C kod do suboru temp_code.c
//     const filePath = path.join(__dirname, "temp_code.c");
//     fs.writeFileSync(filePath, code);

//     // spusti GCC kompilator na kompilovanie C kodu do spustitelneho suboru
//     const outputExecutable = path.join(__dirname, "temp_program");
//     const compile = spawn("gcc", [filePath, "-o", outputExecutable]);

//     // riesi chyby kompilacie
//     let compileError = "";
//     compile.stderr.on("data", (data) => {
//         compileError += data.toString();
//     });
//     // zistujeme, ci kompilacia bola uspesna
//     compile.on("close", (exitCode) => {
//         // zistujeme, ci kompilacia bola uspesna
//         if (exitCode !== 0) {
//             return callback({ error: "Compilation failed", details: compileError }, null);
//         }

//         // spustime program, len ak kompilacia prebehla uspesne
//         const run = spawn(outputExecutable);
//         let runOutput = "";
//         let runError = "";

//         // ak mame vstup, posli do stdin
//         if (input && input.trim() !== "") {
//             // ak mame viacej vstupov
//             run.stdin.write(input + "\n");
//         }
//         // ukoncime stdin
//         run.stdin.end();

//         // ak mame vystup, vlozime ho tu
//         run.stdout.on("data", (data) => {
//             runOutput += data.toString();
//         });

//         // riesi chyby pri spustani kodu
//         run.stderr.on("data", (data) => {
//             runError += data.toString();
//         });

//         // zistujeme ci spustenie bolo uspesne
//         run.on("close", (exitCode) => {
//             if (exitCode !== 0) {
//                 return callback({ error: "Execution failed", details: runError }, null);
//             }
//             // ako ano, vratime vystup
//             callback(null, { output: runOutput });
//         });
//     });
// }

// // exportujeme funkciu, aby sa dala pouzit aj v inych suboroch
// module.exports = compileAndRun;