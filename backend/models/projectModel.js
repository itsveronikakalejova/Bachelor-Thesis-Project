const db = require('../database/db');  // Assuming this imports the promise-based db connection

async function shareProjectToDatabase(projectName, userName, privilege) {
  const findUserIdQuery = `SELECT id FROM users WHERE username = ?`;
  const findProjectIdQuery = `SELECT id FROM projects WHERE name = ?`;

  try {
    // Step 1: Get the userId and projectId
    const [userResult] = await db.query(findUserIdQuery, [userName]);
    const [projectResult] = await db.query(findProjectIdQuery, [projectName]);

    if (userResult.length === 0) {
      throw new Error("User not found");
    }

    if (projectResult.length === 0) {
      throw new Error("Project not found");
    }

    const userId = userResult[0].id;
    const projectId = projectResult[0].id;

    // Step 2: Map privilege to role
    const role = "editor";
    // Step 3: Insert into project_users table
    const insertQuery = `INSERT INTO project_users (user_id, project_id, role) VALUES (?, ?, ?)`;

    console.log("Executing query:", insertQuery);
    console.log("With values:", [userId, projectId, role]);

    const [result] = await db.query(insertQuery, [userId, projectId, role]);

    console.log("Insert result:", result);
    return result;  // Return result of query execution

  } catch (error) {
    console.error("Error executing query:", error);
    throw error;  // Throw error if there's an issue with the query execution
  }
}

module.exports = { shareProjectToDatabase };
