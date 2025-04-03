const express = require('express');
const db = require('./db'); // Predpokladám, že máte vlastné pripojenie k databáze
const router = express.Router();

// Endpoint na odosielanie správy
router.post('/sendMessage', (req, res) => {
  const { projectName, message, userName } = req.body;

  // Najprv nájdeme ID projektu podľa názvu
  const getProjectIdQuery = 'SELECT id FROM projects WHERE name = ?';
  db.query(getProjectIdQuery, [projectName], (err, projectResult) => {
    if (err) {
      return res.status(500).send('Error fetching project');
    }
    if (projectResult.length === 0) {
      return res.status(404).send('Project not found');
    }
    const projectId = projectResult[0].id;

    // Potom nájdeme ID používateľa podľa mena
    const getUserIdQuery = 'SELECT id FROM users WHERE username = ?';
    db.query(getUserIdQuery, [userName], (err, userResult) => {
      if (err) {
        return res.status(500).send('Error fetching user');
      }
      if (userResult.length === 0) {
        return res.status(404).send('User not found');
      }
      const userId = userResult[0].id;

      // Uložíme správu do databázy
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
  
    // Overte, či je parameter projectName prítomný
    if (!projectName) {
      return res.status(400).send('Project name is required');
    }
  
    // Najprv získajte ID projektu na základe názvu
    const queryProjectId = 'SELECT id FROM projects WHERE name = ?';
  
    db.query(queryProjectId, [projectName], (err, result) => {
      if (err) {
        return res.status(500).send('Error fetching project ID');
      }
      if (result.length === 0) {
        return res.status(404).send('Project not found');
      }
  
      const projectId = result[0].id;
  
      // Potom získať správy pre daný projectId
      const queryMessages = 'SELECT m.message, u.username FROM messages m JOIN users u ON m.user_id = u.id WHERE m.project_id = ? ORDER BY m.created_at ASC';
  
      db.query(queryMessages, [projectId], (err, result) => {
        if (err) {
          return res.status(500).send('Error fetching messages');
        }
        res.status(200).json(result); // Vraciame výsledky ako JSON
      });
    });
  });
  ;
  
  

module.exports = router;
