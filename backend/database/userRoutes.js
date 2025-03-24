// userRoutes.js
const express = require('express');
const { getUsers } = require('./userService');  // Destructure to get the getUsers function

const router = express.Router();

router.get("/users", async (req, res) => {
  try {
    const users = await getUsers();  // Calling the async function
    res.json(users);  // Respond with the list of users
  } catch (err) {
    res.status(500).json({ error: "Chyba pri ziskavani pouzivatelov." });
  }
});

module.exports = router;
