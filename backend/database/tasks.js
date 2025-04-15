const express = require('express');
const db = require('./db');

const router = express.Router();

router.get('/my-tasks', (req, res) => {
  const username = req.query.userName;
  if (!username) {
    return res.status(400).json({ error: 'Username is required' });
  }

  db.query('SELECT * FROM tasks WHERE assigned_to = (SELECT id FROM users WHERE username = ?)', [username], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
});

router.post('/add-task', (req, res) => {
  const { task_name, description, status, project_name, userName, deadline } = req.body;

  if (!task_name || !description || !status || !project_name || !userName || !deadline) {
    return res.status(400).json({ error: 'Task name, description, status, project_name, userName, and deadline are required' });
  }

  const findProjectQuery = 'SELECT id FROM projects WHERE name = ?';
  db.query(findProjectQuery, [project_name], (err, projectResult) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    if (projectResult.length === 0) {
      return res.status(404).json({ error: 'Project not found' });
    }

    const projectId = projectResult[0].id;

    const findUserQuery = 'SELECT id FROM users WHERE username = ?';
    db.query(findUserQuery, [userName], (err, userResult) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      if (userResult.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }

      const userId = userResult[0].id;

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


router.delete('/delete-task/:taskId', (req, res) => {
  const { taskId } = req.params;
  
  if (!taskId) {
    return res.status(400).json({ error: 'Task ID is required' });
  }

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

router.get('/tasks-by-project', (req, res) => {
  const { projectName } = req.query;

  if (!projectName) {
    return res.status(400).json({ error: 'Project name is required' });
  }

  const findProjectQuery = 'SELECT id FROM projects WHERE name = ?';
  db.query(findProjectQuery, [projectName], (err, projectResult) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    if (projectResult.length === 0) {
      return res.status(404).json({ error: 'Project not found' });
    }

    const projectId = projectResult[0].id;

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

router.get('/project-id', (req, res) => {
  const { project_name } = req.query;

  if (!project_name) {
    return res.status(400).json({ error: 'Project name is required' });
  }

  const query = 'SELECT id FROM projects WHERE name = ?';
  db.query(query, [project_name], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: 'Project not found' });
    }

    return res.json({ project_id: results[0].id });
  });
});

router.put('/update-task-in-project', async (req, res) => {
  const { originalName, updatedName, description, deadline, assigned_to } = req.body;

  if (!originalName || !updatedName || !description || !deadline || !assigned_to) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  try {
    const getUserIdQuery = 'SELECT id FROM users WHERE username = ?';
    db.query(getUserIdQuery, [assigned_to], (err, userResult) => {
      if (err) {
        return res.status(500).json({ error: 'Error fetching user ID' });
      }

      if (userResult.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }

      const userId = userResult[0].id;

      const updateQuery = `
        UPDATE tasks 
        SET task_name = ?, description = ?, deadline = ?, assigned_to = ?
        WHERE task_name = ?
      `;

      db.query(updateQuery, [updatedName, description, deadline, userId, originalName], (err, result) => {
        if (err) {
          return res.status(500).json({ error: 'Error updating task' });
        }

        if (result.affectedRows === 0) {
          return res.status(404).json({ error: 'Task not found or not updated' });
        }

        res.status(200).json({ message: 'Task updated successfully' });
      });
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

router.put('/update-task-in-tasks', async (req, res) => {
  const { originalName, updatedName, description, deadline, project_name } = req.body;

  if (!originalName || !updatedName || !description || !deadline || !project_name) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  try {
    const getProjectIdQuery = 'SELECT id FROM projects WHERE name = ?';
    db.query(getProjectIdQuery, [project_name], (err, projectResult) => {
      if (err) {
        return res.status(500).json({ error: 'Error fetching project ID' });
      }

      if (projectResult.length === 0) {
        return res.status(404).json({ error: 'Project not found' });
      }

      const projectId = projectResult[0].id;

      const updateQuery = `
        UPDATE tasks 
        SET project_id = ?, task_name = ?, description = ?, deadline = ?
        WHERE task_name = ?
      `;

      db.query(updateQuery, [projectId, updatedName, description, deadline, originalName], (err, result) => {
        if (err) {
          return res.status(500).json({ error: 'Error updating task' });
        }

        if (result.affectedRows === 0) {
          return res.status(404).json({ error: 'Task not found or not updated' });
        }

        res.status(200).json({ message: 'Task updated successfully' });
      });
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});


module.exports = router;
