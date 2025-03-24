const db = require('../database/db');  // Assuming this imports the callback-based db connection

function shareProjectToDatabase(projectName, userName, privilege, callback) {
  const findUserIdQuery = `SELECT id FROM users WHERE username = ?`;
  const findProjectIdQuery = `SELECT id FROM projects WHERE name = ?`;

  // Step 1: Get the userId and projectId
  db.query(findUserIdQuery, [userName], (err, userResult) => {
    if (err) {
      console.error("Error fetching user:", err);
      return callback(err, null);  // Pass error to callback if there's a query failure
    }

    if (userResult.length === 0) {
      const error = new Error(`User with username '${userName}' not found`);
      console.error(error.message);
      return callback(error, null);
    }

    db.query(findProjectIdQuery, [projectName], (err, projectResult) => {
      if (err) {
        console.error("Error fetching project:", err);
        return callback(err, null);  // Pass error to callback if there's a query failure
      }

      if (projectResult.length === 0) {
        const error = new Error(`Project with name '${projectName}' not found`);
        console.error(error.message);
        return callback(error, null);
      }

      const userId = userResult[0].id;
      const projectId = projectResult[0].id;

      // Step 2: Map privilege to role
      const role = privilege === 'admin' ? 'admin' : 'editor';  // Example role mapping

      const insertQuery = `INSERT INTO project_users (user_id, project_id, role) VALUES (?, ?, ?)`;

      console.log("Executing query:", insertQuery);
      console.log("With values:", [userId, projectId, role]);

      // Step 3: Insert into project_users table
      db.query(insertQuery, [userId, projectId, role], (err, result) => {
        if (err) {
          console.error("Error inserting into project_users:", err);
          return callback(err, null);  // Pass error to callback if insertion fails
        }

        console.log("Insert result:", result);
        return callback(null, result);  // Pass result to callback on success
      });
    });
  });
}

module.exports = { shareProjectToDatabase };
