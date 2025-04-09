const express = require('express');
const { getUsers } = require('./userService'); 

const router = express.Router();

router.get("/users", (req, res) => {
  getUsers((err, users) => {  
    if (err) {
      res.status(500).json({ error: "Chyba pri ziskavani pouzivatelov." });
    } else {
      res.json(users);  
    }
  });
});

module.exports = router;
