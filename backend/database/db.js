// db.js
const mysql = require('mysql2/promise');

// Create the connection pool
const db = mysql.createPool({
  host: 'localhost',
  user: 'root',    // Modify with your MySQL username
  password: '',    // Modify with your MySQL password
  database: 'project_db',  // Modify with your database name
  waitForConnections: true,
  connectionLimit: 10,  // Adjust based on your needs
  queueLimit: 0
});

// Export the pool
module.exports = db;
