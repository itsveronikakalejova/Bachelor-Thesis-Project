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
  const { task_name, description, status, project_name, userName, deadline } = req.body;

  // Validate the required fields
  if (!task_name || !description || !status || !project_name || !userName || !deadline) {
    return res.status(400).json({ error: 'Task name, description, status, project_name, userName, and deadline are required' });
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

      db.query(insertTaskQuery, [projectId, task_name, description, status, userId, deadline], (err, result) => {
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

router.put('/update-status', (req, res) => {
    const { taskName, newStatus } = req.body;

    if (!taskName || !newStatus) {
        return res.status(400).json({ error: 'Task name and new status are required' });
    }

    // First, find the task by taskName
    db.query(
        'SELECT id FROM tasks WHERE task_name = ?',
        [taskName],
        (err, results) => {
            if (err) {
                console.error(err);
                return res.status(500).json({ error: 'Failed to find task' });
            }

            if (results.length === 0) {
                return res.status(404).json({ error: 'Task not found' });
            }

            const taskId = results[0].id;

            // Now that we have the task ID, update the task status
            db.query(
                'UPDATE tasks SET status = ? WHERE id = ?',
                [newStatus, taskId],
                (err, result) => {
                    if (err) {
                        console.error(err);
                        return res.status(500).json({ error: 'Failed to update task status' });
                    }

                    if (result.affectedRows > 0) {
                        res.status(200).json({ message: 'Task status updated successfully' });
                    } else {
                        res.status(404).json({ error: 'Failed to update task status' });
                    }
                }
            );
        }
    );
});

router.delete('/delete-task', async (req, res) => {
    try {
        const { taskName } = req.body;
        if (!taskName) {
            return res.status(400).json({ error: "Task name is required" });
        }

        const deleteQuery = 'DELETE FROM tasks WHERE task_name = ?';
        db.query(deleteQuery, [taskName], (err, result) => {
            if (err) {
                console.error(err);
                return res.status(500).json({ error: "Database error" });
            }
            res.status(200).json({ message: "Task deleted successfully" });
        });
    } catch (error) {
        res.status(500).json({ error: "Server error" });
    }
});

// Get all tasks associated with a specific project name
router.get('/tasks-by-project', (req, res) => {
  const { projectName } = req.query;

  if (!projectName) {
    return res.status(400).json({ error: 'Project name is required' });
  }

  // First, find the project ID using the provided project name
  const findProjectQuery = 'SELECT id FROM projects WHERE name = ?';
  db.query(findProjectQuery, [projectName], (err, projectResult) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    if (projectResult.length === 0) {
      return res.status(404).json({ error: 'Project not found' });
    }

    const projectId = projectResult[0].id;

    // Now, fetch all tasks associated with this project ID
    const fetchTasksQuery = `
      SELECT tasks.id, tasks.task_name, tasks.description, tasks.status, tasks.deadline, users.username AS assigned_to
      FROM tasks
      JOIN users ON tasks.assigned_to = users.id
      WHERE tasks.project_id = ?
    `;

    db.query(fetchTasksQuery, [projectId], (err, taskResults) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json(taskResults);
    });
  });
});

router.get('/project-info', (req, res) => {
  const { taskId } = req.query;

  if (!taskId) {
    return res.status(400).json({ error: 'Task ID is required' });
  }

  const getProjectIdQuery = 'SELECT project_id FROM tasks WHERE id = ?';
  db.query(getProjectIdQuery, [taskId], (err, projectIdResult) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    if (projectIdResult.length === 0) {
      return res.status(404).json({ error: 'Task not found or has no project assigned' });
    }

    const projectId = projectIdResult[0].project_id;

    const getProjectNameQuery = 'SELECT name FROM projects WHERE id = ?';
    db.query(getProjectNameQuery, [projectId], (err, projectNameResult) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      if (projectNameResult.length === 0) {
        return res.status(404).json({ error: 'Project not found' });
      }

      res.json({
        project_id: projectId,
        project_name: projectNameResult[0].name
      });
    });
  });
});

 

module.exports = router;
