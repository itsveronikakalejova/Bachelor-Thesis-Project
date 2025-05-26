const express = require('express');
const router = express.Router();
const db = require('../database/db');

// funkcia na zdielanie projektu s pouzivatelom s konkretnym pravom
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

      db.query(insertQuery, [userId, projectId, role], (err, result) => {
        if (err) {
          console.error("Error inserting into project_users:", err);
          return callback(err, null);  
        }
        return callback(null, result);  
      });
    });
  });
}

// route na zdielanie projektu s inym pouzivatelom
// pouzite v shareDialog.dart
router.post('/', async (req, res) => {
  const { projectName, userName, privilege } = req.body;

  if (!projectName || !userName || !privilege) {
    return res.status(400).json({ message: 'Missing required fields: projectName, userName, privilege.' });
  }

  try {
    const [userRows] = await db.promise().query(
      'SELECT id FROM users WHERE username = ?', [userName]
    );

    if (userRows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    const [projectRows] = await db.promise().query(
      'SELECT id FROM projects WHERE name = ?', [projectName]
    );

    if (projectRows.length === 0) {
      return res.status(404).json({ message: 'Project not found' });
    }

    shareProjectToDatabase(projectName, userName, privilege, (err, result) => {
      if (err) {
        console.error("Error sharing project:", err);
        return res.status(500).json({ message: 'Failed to share project', error: err.message });
      }

      return res.status(200).json({
        message: 'Project shared successfully',
        data: result,
      });
    });
  } catch (err) {
    console.error("Unexpected server error:", err);
    return res.status(500).json({ message: 'Internal server error' });
  }
});

module.exports = router;
