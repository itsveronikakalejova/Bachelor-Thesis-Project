// const path = require('path');
// const { spawn } = require('child_process');

// io.on('connection', (socket) => {
//     let processInstance;

//     socket.on('runBinary', (filename) => {
//         const binaryPath = path.join(__dirname, 'compiled', filename);

//         processInstance = spawn(binaryPath);

//         processInstance.stdout.on('data', (data) => {
//             socket.emit('output', data.toString());
//         });

//         processInstance.stderr.on('data', (data) => {
//             socket.emit('output', data.toString());
//         });

//         socket.on('input', (data) => {
//             processInstance.stdin.write(data + '\n');
//         });

//         processInstance.on('close', () => {
//             socket.emit('output', '[Process finished]');
//         });

//         socket.on('disconnect', () => {
//             if (processInstance) processInstance.kill();
//         });
//     });
// });
