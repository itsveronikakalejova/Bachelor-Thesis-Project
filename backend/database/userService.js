const db = require('./db');  // Predpokladáme, že používate pripojenie/pool db

const getUsers = (callback) => {
  const sql = "SELECT username FROM users";
  db.query(sql, (err, rows) => {
    if (err) {
      console.error("Error fetching users:", err);
      return callback(err, null);  // Callback with error if query fails
    }
    const users = rows.map(user => user.username);  // Extracting usernames
    callback(null, users);  // Pass the results to the callback
  });
};

// Správny export funkcie
module.exports = { getUsers };
