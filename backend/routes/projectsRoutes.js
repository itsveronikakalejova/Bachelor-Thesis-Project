const express = require('express');
const db= require('../database/db');
const router = express.Router();

// zobrazi vsetky projekty, ktore pouzivatel vytvoril alebo ma k nim pristup
// pouzite v projects.dart
router.get('/projects', (req, res) => {
    const { username } = req.query;

    const findUserSql = "SELECT id FROM users WHERE username = ?";
    db.query(findUserSql, [username], (err, userResults) => {
        if (err || userResults.length === 0) {
            console.error("Error finding user:", err);
            return res.status(500).json({ error: 'Failed to find user' });
        }
        const userId = userResults[0].id;

        const sql = `
            SELECT p.id, p.name, 
                CASE 
                    WHEN pa.role = 'owner' THEN 'owner'
                    ELSE 'editor'
                END AS role
            FROM projects p
            LEFT JOIN project_users pa ON p.id = pa.project_id
            WHERE pa.user_id = ? OR p.owner_id = ?;
        `;
        
        db.query(sql, [userId, userId], (err, results) => {
            if (err) {
                console.error("Error fetching projects:", err);
                return res.status(500).json({ error: 'Failed to fetch projects' });
            }

            const projectsWithRoles = results.map(project => ({
                id: project.id,
                name: project.name,
                role: project.role
            }));

            res.json(projectsWithRoles);
        });
    });
});

// prida projekt do databazy
// pouzite v projects.dart
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

// vymaze projekt na zaklade id
// pouzite v projects.dart
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

// ulozi textovy subor z konkretneho projektu do databazy
// pouzite v project.dart
router.post('/project/:projectId/saveText', (req, res) => {
    const { projectId } = req.params;
    const { text, uploadedBy, fileName } = req.body;

    const checkFileSql = "SELECT id FROM project_files WHERE project_id = ? AND file_name = ?";
    db.query(checkFileSql, [projectId, fileName], (err, results) => {
        if (err) {
            console.error("Error checking for existing file:", err);
            return res.status(500).json({ error: 'Failed to check for existing file' });
        }

        if (results.length > 0) {
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

// prida projektovy subor do databazy
// pouzite v project.dart
router.post('/project/:projectId/files', (req, res) => {
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

// zobrazi vsetky subory projektu
// pouzite v project.dart
router.get('/project/:projectId/files', (req, res) => {
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

// zobrazi obsah suboru v projekte
// pouzite v project.dart
router.get('/project/:projectId/files/:fileId', (req, res) => {
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

// zobrazi typ suboru v projekte na zaklade nazvu suboru fileName
// pouzite v project.dart
router.get('/project/:projectId/file-type/:fileName', (req, res) => {
    const { projectId, fileName } = req.params;
    const sql = "SELECT file_type FROM project_files WHERE project_id = ? AND file_name = ?";
    
    db.query(sql, [projectId, fileName], (err, results) => {
        if (err) {
            console.error("Error fetching file type:", err);
            return res.status(500).json({ error: 'Failed to fetch file type' });
        }
        
        if (results.length > 0) {
            res.json({ 
                fileId: fileName,
                fileType: results[0].file_type 
            });
        } else {
            res.status(404).json({ error: 'File not found' });
        }
    });
});

// zobrazi nazov projektu na zaklade id
router.get('/project/:projectId', (req, res) => {
    const { projectId } = req.params;
    const sql = "SELECT name FROM projects WHERE id = ?";
    db.query(sql, [projectId], (err, results) => {
        if (err) {
            console.error("Error fetching project name:", err);
            return res.status(500).json({ error: 'Failed to fetch project name.' });
        }
        if (results.length > 0) {
            res.json({ name: results[0].name });
        } else {
            res.status(404).json({ error: 'Project not found' });
        }
    });
});

// zisti kto je vlastnikom projektu na zaklade nazvu projektu
// pouzite v projects.dart
router.get('/projects/owner/:projectName', (req, res) => {
    const { projectName } = req.params;

    if (!projectName) {
        return res.status(400).json({ error: 'Project name is required' });
    }

    const getProjectSql = 'SELECT owner_id FROM projects WHERE name = ?';
    db.query(getProjectSql, [projectName], (err, projectResults) => {
        if (err) {
            console.error("Error fetching project:", err);
            return res.status(500).json({ error: 'Failed to fetch project' });
        }
        if (projectResults.length === 0) {
            return res.status(404).json({ error: 'Project not found' });
        }

        const ownerId = projectResults[0].owner_id;

        const getOwnerSql = 'SELECT username FROM users WHERE id = ?';
        db.query(getOwnerSql, [ownerId], (err, ownerResults) => {
            if (err) {
                console.error("Error fetching owner:", err);
                return res.status(500).json({ error: 'Failed to fetch project owner' });
            }
            if (ownerResults.length === 0) {
                return res.status(404).json({ error: 'Owner not found' });
            }

            res.status(200).json({ ownerName: ownerResults[0].username });
        });
    });
});

// zisti kto ma pristup k projektu na zaklade nazvu projektu
// pouzite v project.dart
router.get('/project-users/users-with-access', (req, res) => {
    const { project_name } = req.query;
  
    if (!project_name) {
      return res.status(400).json({ error: 'Missing project_name' });
    }
  
    const projectQuery = 'SELECT id, owner_id FROM projects WHERE name = ?';
    db.query(projectQuery, [project_name], (err, projectResult) => {
      if (err) {
        return res.status(500).json({ error: 'Database error', details: err.message });
      }
  
      if (projectResult.length === 0) {
        return res.status(404).json({ error: 'Project not found' });
      }
  
      const projectId = projectResult[0].id;
      const ownerId = projectResult[0].owner_id;
  
      const ownerQuery = 'SELECT username FROM users WHERE id = ?';
      db.query(ownerQuery, [ownerId], (err, ownerResult) => {
        if (err) {
          return res.status(500).json({ error: 'Database error (owner)', details: err.message });
        }
  
        const ownerUsername = ownerResult.length > 0 ? ownerResult[0].username : null;
  
        const editorsQuery = `
          SELECT users.username
          FROM project_users
          JOIN users ON project_users.user_id = users.id
          WHERE project_users.project_id = ?
        `;
  
        db.query(editorsQuery, [projectId], (err, editorsResult) => {
          if (err) {
            return res.status(500).json({ error: 'Database error (editors)', details: err.message });
          }
  
          const usersWithAccess = [];
  
          if (ownerUsername) {
            usersWithAccess.push({ username: ownerUsername, role: 'owner' });
          }
  
          editorsResult.forEach((row) => {
            usersWithAccess.push({ username: row.username, role: 'editor' });
          });
  
          return res.json(usersWithAccess);
        });
      });
    });
  });
  
// zobrazi nazov projektu na zaklade id
// pouzite v tasks.dart
router.get('/projects/:projectId', (req, res) => {
    const { projectId } = req.params;
    const sql = "SELECT name FROM projects WHERE id = ?";
    db.query(sql, [projectId], (err, results) => {
        if (err) {
            console.error("Error fetching project details:", err);
            return res.status(500).json({ error: 'Failed to fetch project details' });
        }
        if (results.length > 0) {
            res.json({ name: results[0].name });
        } else {
            res.status(404).json({ error: 'Project not found' });
        }
    });
});

// zobrazi projekty, ktore vytvoril uzivatel alebo ma k nim pristup
// pouzite v tasks.dart
router.get('/project-list/list-my-projects', (req, res) => {
    const { username } = req.query;
  
    if (!username) {
      return res.status(400).json({ error: 'Username is required' });
    }
  
    const query = `
      SELECT DISTINCT p.name 
      FROM projects p
      LEFT JOIN project_users pu ON pu.project_id = p.id
      JOIN users u ON u.id = pu.user_id OR u.id = p.owner_id
      WHERE u.username = ?;
    `;
  
    db.query(query, [username], (err, results) => {
      if (err) {
        return res.status(500).json({ error: 'Error fetching projects' });
      }
  
      if (results.length === 0) {
        return res.status(404).json({ message: 'No projects found for this user' });
      }
  
      res.json(results);
    });
  });
  
// vymaze subor z projektu na zaklade id suboru
// pouzite v project.dart
router.delete('/project/delete-file/:fileId', (req, res) => {
    const { projectId, fileId } = req.params;
  
    const sql = "DELETE FROM project_files WHERE id = ?";
    db.query(sql, [fileId], (err, results) => {
      if (err) {
        console.error("Error deleting file:", err);
        return res.status(500).json({ error: 'Failed to delete file' });
      }
  
      if (results.affectedRows === 0) {
        return res.status(404).json({ message: 'File not found or already deleted' });
      }
  
      res.status(200).json({ message: 'File deleted successfully' });
    });
  });
  
// aktualizuje nazov suboru na zaklade id suboru
// pouzite v project.dart
router.put('/project/update-file/:fileId', (req, res) => {
    const { fileId } = req.params;
    const { newName } = req.body;

    if (!newName) {
        return res.status(400).json({ error: 'New file name is required' });
    }

    const sql = "UPDATE project_files SET file_name = ? WHERE id = ?";
    db.query(sql, [newName, fileId], (err, result) => {
        if (err) {
            console.error("Error updating file name:", err);
            return res.status(500).json({ error: 'Failed to update file name' });
        }
        res.status(200).json({ message: 'File name updated successfully' });
    });
});

// aktualizuje nazov projektu na zaklade stareho nazvu projektu
// pouzite v projects.dart
router.put('/projects/update-name/:projectName', (req, res) => {
    const { projectName } = req.params;
    const { newName } = req.body;

    if (!projectName || !newName) {
        return res.status(400).json({ error: 'Missing required fields: projectName or newName' });
    }

    const findProjectSql = 'SELECT id FROM projects WHERE name = ?';
    db.query(findProjectSql, [projectName], (err, results) => {
        if (err) {
            console.error('Error finding project:', err);
            return res.status(500).json({ error: 'Database error while finding project' });
        }

        if (results.length === 0) {
            return res.status(404).json({ error: 'Project not found' });
        }

        const projectId = results[0].id;
        const updateNameSql = 'UPDATE projects SET name = ? WHERE id = ?';
        db.query(updateNameSql, [newName, projectId], (err, updateResult) => {
            if (err) {
                console.error('Error updating project name:', err);
                return res.status(500).json({ error: 'Failed to update project name' });
            }

            return res.status(200).json({ message: 'Project name updated successfully' });
        });
    });
});


module.exports = router;