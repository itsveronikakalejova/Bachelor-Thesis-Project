const express = require('express');
const router = express.Router();
const { shareProjectToDatabase } = require('../models/projectModel'); 

router.post('/share', (req, res) => {
    console.log("Request received:", req.body);  // Check if request is hitting this endpoint
  
    // Expect the correct keys in the request body
    const { projectName, userName, privilege } = req.body;
  
    // Log received data for debugging
    console.log("Received data:", req.body);
  
    // Ensure that all required fields are present
    if (!projectName || !userName || !privilege) {
      return res.status(400).json({ message: 'Missing required fields: projectName, userName, privilege.' });
    }

    // Call the function to share the project with correct parameters using callbacks
    shareProjectToDatabase(projectName, userName, privilege, (err, result) => {
        if (err) {
            console.error("Error sharing project:", err);
            return res.status(500).json({ message: 'Failed to share project', error: err.message });
        }

        console.log("Database result:", result);  // Check the result of the insert
        return res.status(200).json({
            message: 'Project shared successfully',
            data: result
        });
    });
});

module.exports = router;
