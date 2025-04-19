const express = require('express');
const db = require('./db'); 
const router = express.Router();
const compileCode = require('../controllers/compiler');  // Používaj require, ak nie je nastavene 'type: "module"' v package.json

router.get('/compile/:filename', (req, res) => {
    const filename = req.params.filename;

    db.query('SELECT file_data FROM project_files WHERE file_name = ?', [filename], (err, results) => {
        if (err) {
            console.error('Database query error:', err);
            res.status(500).send('Database error');
            return;
        }
    
        if (results.length === 0) {
            res.status(404).send('File not found');
            return;
        }
    
        const codeBuffer = results[0].file_data;
        const code = codeBuffer.toString(); // prevedieme Buffer (BLOB) na reťazec
    
        compileCode(code, (err, result) => {
            if (err) {
                res.status(500).send(err);
                return;
            }
    
            res.status(200).send(result);
        });
    });
    
});

module.exports = router;
