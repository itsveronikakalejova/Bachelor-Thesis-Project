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

// Funkcia na získanie zoznamu používateľov
const getUsers = (callback) => {
    const sql = "SELECT username FROM users"; // Získame mená používateľov
    db.query(sql, (err, results) => {
        if (err) {
            console.error("Chyba pri získavaní používateľov:", err);
            callback(err, null);
        } else {
            const users = results.map(user => user.username);
            callback(null, users);
        }
    });
};

module.exports = {
    db,
    getUsers
};
