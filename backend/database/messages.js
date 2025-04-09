const express = require('express');
const db = require('./db'); 
const router = express.Router();

router.post('/sendMessage', (req, res) => {
  const { projectName, message, userName } = req.body;

  const getProjectIdQuery = 'SELECT id FROM projects WHERE name = ?';
  db.query(getProjectIdQuery, [projectName], (err, projectResult) => {
    if (err) {
      return res.status(500).send('Error fetching project');
    }
    if (projectResult.length === 0) {
      return res.status(404).send('Project not found');
    }
    const projectId = projectResult[0].id;

    const getUserIdQuery = 'SELECT id FROM users WHERE username = ?';
    db.query(getUserIdQuery, [userName], (err, userResult) => {
      if (err) {
        return res.status(500).send('Error fetching user');
      }
      if (userResult.length === 0) {
        return res.status(404).send('User not found');
      }
      const userId = userResult[0].id;

      const insertMessageQuery = 'INSERT INTO messages (project_id, user_id, message) VALUES (?, ?, ?)';
      db.query(insertMessageQuery, [projectId, userId, message], (err, result) => {
        if (err) {
          return res.status(500).send('Error saving message');
        }
        res.status(200).send('Message saved');
      });
    });
  });
});


router.get('/getMessages', (req, res) => {
    const projectName = req.query.projectName;
  
    if (!projectName) {
      return res.status(400).send('Project name is required');
    }
  
    const queryProjectId = 'SELECT id FROM projects WHERE name = ?';
  
    db.query(queryProjectId, [projectName], (err, result) => {
      if (err) {
        return res.status(500).send('Error fetching project ID');
      }
      if (result.length === 0) {
        return res.status(404).send('Project not found');
      }
  
      const projectId = result[0].id;
  
      const queryMessages = 'SELECT m.message, u.username FROM messages m JOIN users u ON m.user_id = u.id WHERE m.project_id = ? ORDER BY m.created_at ASC';
  
      db.query(queryMessages, [projectId], (err, result) => {
        if (err) {
          return res.status(500).send('Error fetching messages');
        }
        res.status(200).json(result); 
      });
    });
  });
  ;
  
  

module.exports = router;
