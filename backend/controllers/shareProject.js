const express = require('express');
const router = express.Router();
const { shareProjectToDatabase } = require('../models/projectModel'); 

router.post('/share', (req, res) => {
  
    const { projectName, userName, privilege } = req.body;
  
    if (!projectName || !userName || !privilege) {
      return res.status(400).json({ message: 'Missing required fields: projectName, userName, privilege.' });
    }

    shareProjectToDatabase(projectName, userName, privilege, (err, result) => {
        if (err) {
            console.error("Error sharing project:", err);
            return res.status(500).json({ message: 'Failed to share project', error: err.message });
        }

        console.log("Database result:", result); 
        return res.status(200).json({
            message: 'Project shared successfully',
            data: result
        });
    });
});

module.exports = router;
