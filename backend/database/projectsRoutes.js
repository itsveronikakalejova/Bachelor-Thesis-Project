const express = require('express');
const { db } = require('./db');
const router = express.Router();

// Fetch projects for a specific user
router.get('/projects', (req, res) => {
    const { username } = req.query;
    const findUserSql = "SELECT id FROM users WHERE username = ?";
    db.query(findUserSql, [username], (err, userResults) => {
        if (err || userResults.length === 0) {
            console.error("Error finding user:", err);
            return res.status(500).json({ error: 'Failed to find user' });
        }
        const ownerId = userResults[0].id;
        const sql = "SELECT * FROM projects WHERE owner_id = ?";
        db.query(sql, [ownerId], (err, results) => {
            if (err) {
                console.error("Error fetching projects:", err);
                return res.status(500).json({ error: 'Failed to fetch projects' });
            }
            res.json(results);
        });
    });
});

// Add a new project
router.post('/projects', (req, res) => {
    const { name, username } = req.body;
    const findUserSql = "SELECT id FROM users WHERE username = ?";
    db.query(findUserSql, [username], (err, userResults) => {
        if (err || userResults.length === 0) {
            console.error("Error finding user:", err);
            return res.status(500).json({ error: 'Failed to find user' });
        }
        const ownerId = userResults[0].id;
        const insertProjectSql = "INSERT INTO projects (name, owner_id) VALUES (?, ?)";
        db.query(insertProjectSql, [name, ownerId], (err, projectResults) => {
            if (err) {
                console.error("Error adding project:", err);
                return res.status(500).json({ error: 'Failed to add project' });
            }
            res.status(201).json({ id: projectResults.insertId, name, ownerId });
        });
    });
});

// Delete a project
router.delete('/projects/:id', (req, res) => {
    const { id } = req.params;
    const sql = "DELETE FROM projects WHERE id = ?";
    db.query(sql, [id], (err, results) => {
        if (err) {
            console.error("Error deleting project:", err);
            return res.status(500).json({ error: 'Failed to delete project' });
        }
        res.status(200).json({ message: 'Project deleted successfully' });
    });
});

router.post('/projects/:projectId/saveText', (req, res) => {
    const { projectId } = req.params;
    const { text, uploadedBy } = req.body;

    const checkFileSql = "SELECT id FROM project_files WHERE project_id = ? AND file_name = 'text_input.txt'";
    db.query(checkFileSql, [projectId], (err, results) => {
        if (err) {
            console.error("Error checking for existing file:", err);
            return res.status(500).json({ error: 'Failed to check for existing file' });
        }

        if (results.length > 0) {
            // File exists, update it
            const fileId = results[0].id;
            const updateFileSql = "UPDATE project_files SET file_data = ?, uploaded_by = ? WHERE id = ?";
            db.query(updateFileSql, [Buffer.from(text), uploadedBy, fileId], (err, results) => {
                if (err) {
                    console.error("Error updating file:", err);
                    return res.status(500).json({ error: 'Failed to update file' });
                }
                res.status(200).json({ message: 'Text input updated successfully' });
            });
        } else {
            // File does not exist, create it
            const insertFileSql = "INSERT INTO project_files (project_id, file_name, file_type, file_data, uploaded_by) VALUES (?, ?, ?, ?, ?)";
            db.query(insertFileSql, [projectId, 'text_input.txt', 'text/plain', Buffer.from(text), uploadedBy], (err, results) => {
                if (err) {
                    console.error("Error saving text input:", err);
                    return res.status(500).json({ error: 'Failed to save text input' });
                }
                res.status(201).json({ message: 'Text input saved successfully', fileId: results.insertId });
            });
        }
    });
});

module.exports = router;