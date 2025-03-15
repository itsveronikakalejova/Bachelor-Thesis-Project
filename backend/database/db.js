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

// funkcia na ziskanie zoznamu pouzivatelov
const getUsers = (callback) => {
    const sql = "SELECT username FROM users";
    db.query(sql, (err, results) => {
        if (err) {
            console.error("Chyba pri ziskavani pouzivatelov:", err);
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
