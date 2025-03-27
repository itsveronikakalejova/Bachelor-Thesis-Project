const express = require('express');
const db = require('./db');

const router = express.Router();

// Get tasks assigned to the specified username
router.get('/my-tasks', (req, res) => {
  const username = req.query.userName;
  if (!username) {
    return res.status(400).json({ error: 'Username is required' });
  }

  // Query the database for tasks assigned to this user
  db.query('SELECT * FROM tasks WHERE assigned_to = (SELECT id FROM users WHERE username = ?)', [username], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
});

// Add a new task
router.post('/add-task', (req, res) => {
    const { task_name, description, status, project_name, userName } = req.body;
    let taskDeadline = new Date().toISOString().slice(0, 19).replace('T', ' ');;

    // Validate the required fields
    if (!task_name || !description || !status || !project_name || !userName || !taskDeadline) {
      return res.status(400).json({ error: 'Task name, description, status, project_name, and userName are required' });
    }

    // Step 1: Find the project_id using the provided project_name
    const findProjectQuery = 'SELECT id FROM projects WHERE name = ?';
    db.query(findProjectQuery, [project_name], (err, projectResult) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      if (projectResult.length === 0) {
        return res.status(404).json({ error: 'Project not found' });
      }

      const projectId = projectResult[0].id;

      // Step 2: Find the user_id using the provided username
      const findUserQuery = 'SELECT id FROM users WHERE username = ?';
      db.query(findUserQuery, [userName], (err, userResult) => {
        if (err) {
          return res.status(500).json({ error: err.message });
        }

        if (userResult.length === 0) {
          return res.status(404).json({ error: 'User not found' });
        }

        const userId = userResult[0].id;

        // Step 3: Insert the new task using the found project_id and user_id (assigned_to)
        const insertTaskQuery = 'INSERT INTO tasks (project_id, task_name, description, status, assigned_to, deadline) VALUES (?, ?, ?, ?, ?, ?)';

        db.query(insertTaskQuery, [projectId, task_name, description, status, userId, taskDeadline], (err, result) => {
          if (err) {
            return res.status(500).json({ error: err.message });
          }
          res.status(201).json({ message: 'Task added successfully', taskId: result.insertId });
        });
      });
    });
});


// Delete a task
router.delete('/delete-task/:taskId', (req, res) => {
  const { taskId } = req.params;
  
  if (!taskId) {
    return res.status(400).json({ error: 'Task ID is required' });
  }

  // Delete the task from the database
  const query = 'DELETE FROM tasks WHERE id = ?';
  db.query(query, [taskId], (err, result) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Task not found' });
    }
    res.json({ message: 'Task deleted successfully' });
  });
});

module.exports = router;
