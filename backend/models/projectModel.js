const db = require('../database/db');

function shareProjectToDatabase(projectName, userName, privilege, callback) {
  const findUserIdQuery = `SELECT id FROM users WHERE username = ?`;
  const findProjectIdQuery = `SELECT id FROM projects WHERE name = ?`;

  db.query(findUserIdQuery, [userName], (err, userResult) => {
    if (err) {
      console.error("Error fetching user:", err);
      return callback(err, null); 
    }

    if (userResult.length === 0) {
      const error = new Error(`User with username '${userName}' not found`);
      console.error(error.message);
      return callback(error, null);
    }

    db.query(findProjectIdQuery, [projectName], (err, projectResult) => {
      if (err) {
        console.error("Error fetching project:", err);
        return callback(err, null); 
      }

      if (projectResult.length === 0) {
        const error = new Error(`Project with name '${projectName}' not found`);
        console.error(error.message);
        return callback(error, null);
      }

      const userId = userResult[0].id;
      const projectId = projectResult[0].id;

      const role = privilege === 'admin' ? 'admin' : 'editor'; 

      const insertQuery = `INSERT INTO project_users (user_id, project_id, role) VALUES (?, ?, ?)`;

      console.log("Executing query:", insertQuery);
      console.log("With values:", [userId, projectId, role]);

      db.query(insertQuery, [userId, projectId, role], (err, result) => {
        if (err) {
          console.error("Error inserting into project_users:", err);
          return callback(err, null);  
        }

        console.log("Insert result:", result);
        return callback(null, result);  
      });
    });
  });
}

module.exports = { shareProjectToDatabase };
