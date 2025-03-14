const mysql = require('mysql2');

const db = mysql.createConnection({
    host: 'localhost',
    user: 'root', // Tvoj MySQL používateľ
    password: '', // Tvoje MySQL heslo
    database: 'project_db' // Tvoja databáza
});

db.connect(err => {
    if (err) console.error("Chyba pripojenia k DB:", err);
    else console.log("Pripojené k MySQL");
});

module.exports = db;
