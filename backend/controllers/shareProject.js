const { shareProjectToDatabase } = require('../models/projectModel'); 
const express = require('express');
const router = express.Router();
const db = require('../database/db');

router.post('/share', async (req, res) => {
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

    const userId = userRows[0].id;
    const projectId = projectRows[0].id;

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
