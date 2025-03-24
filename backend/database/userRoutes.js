// userRoutes.js
const express = require('express');
const { getUsers } = require('./userService');  // Destructure to get the getUsers function

const router = express.Router();

router.get("/users", (req, res) => {
  getUsers((err, users) => {  // Pass a callback to getUsers
    if (err) {
      res.status(500).json({ error: "Chyba pri ziskavani pouzivatelov." });
    } else {
      res.json(users);  // Respond with the list of users
    }
  });
});

module.exports = router;
