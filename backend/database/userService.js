// userService.js
const db = require('./db');  // Assuming you're using the db connection/pool

const getUsers = async () => {
  try {
    const sql = "SELECT username FROM users";
    const [rows] = await db.query(sql);  // Query execution using async/await
    const users = rows.map(user => user.username);  // Extracting usernames
    return users;
  } catch (err) {
    console.error("Error fetching users:", err);
    throw err;  // Re-throw error to be handled by the calling code
  }
};

// Correctly export the getUsers function
module.exports = { getUsers };
