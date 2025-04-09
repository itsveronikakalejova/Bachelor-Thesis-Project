const db = require('./db'); 

const getUsers = (callback) => {
  const sql = "SELECT username FROM users";
  db.query(sql, (err, rows) => {
    if (err) {
      console.error("Error fetching users:", err);
      return callback(err, null);  
    }
    const users = rows.map(user => user.username);  
    callback(null, users);  
  });
};

module.exports = { getUsers };
