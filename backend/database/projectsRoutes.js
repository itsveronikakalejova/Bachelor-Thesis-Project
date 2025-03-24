const express = require('express');
const db= require('./db');
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

// Save or update text input as longblob
router.post('/projects/:projectId/saveText', (req, res) => {
    const { projectId } = req.params;
    const { text, uploadedBy, fileName } = req.body;

    const checkFileSql = "SELECT id FROM project_files WHERE project_id = ? AND file_name = ?";
    db.query(checkFileSql, [projectId, fileName], (err, results) => {
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
            db.query(insertFileSql, [projectId, fileName, 'text/x-c', Buffer.from(text), uploadedBy], (err, results) => {
                if (err) {
                    console.error("Error saving text input:", err);
                    return res.status(500).json({ error: 'Failed to save text input' });
                }
                res.status(201).json({ message: 'Text input saved successfully', fileId: results.insertId });
            });
        }
    });
});

// Add a new file to a project
router.post('/projects/:projectId/files', (req, res) => {
    const { projectId } = req.params;
    const { fileName, fileType, fileData, uploadedBy } = req.body;

    const insertFileSql = "INSERT INTO project_files (project_id, file_name, file_type, file_data, uploaded_by) VALUES (?, ?, ?, ?, ?)";
    db.query(insertFileSql, [projectId, fileName, fileType, Buffer.from(fileData), uploadedBy], (err, results) => {
        if (err) {
            console.error("Error adding file:", err);
            return res.status(500).json({ error: 'Failed to add file' });
        }
        res.status(201).json({ message: 'File added successfully', fileId: results.insertId });
    });
});

// Fetch project files for a specific project
router.get('/projects/:projectId/files', (req, res) => {
    const { projectId } = req.params;
    const sql = "SELECT id, file_name, file_type, uploaded_by FROM project_files WHERE project_id = ?";
    db.query(sql, [projectId], (err, results) => {
        if (err) {
            console.error("Error fetching project files:", err);
            return res.status(500).json({ error: 'Failed to fetch project files' });
        }
        res.json(results);
    });
});

// Fetch the content of a specific file
router.get('/projects/:projectId/files/:fileId', (req, res) => {
    const { projectId, fileId } = req.params;
    const sql = "SELECT file_data FROM project_files WHERE project_id = ? AND id = ?";
    db.query(sql, [projectId, fileId], (err, results) => {
        if (err) {
            console.error("Error fetching file content:", err);
            return res.status(500).json({ error: 'Failed to fetch file content' });
        }
        if (results.length > 0) {
            res.json({ fileData: results[0].file_data.toString() });
        } else {
            res.status(404).json({ error: 'File not found' });
        }
    });
});

module.exports = router;