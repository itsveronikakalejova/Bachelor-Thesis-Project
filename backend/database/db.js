const mysql = require('mysql2');

const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '', 
    database: 'project_db'
});

db.connect(err => {
    if (err) console.error("Chyba pripojenia k DB:", err);
    else console.log("Pripojene k MySQL.");
});

module.exports = db;
