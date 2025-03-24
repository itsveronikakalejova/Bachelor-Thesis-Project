const express = require('express');
const { db, getUsers } = require('./db');

const router = express.Router();

router.get("/users", (req, res) => {
    getUsers((err, users) => {
        if (err) {
            return res.status(500).json({ error: "Chyba pri ziskavani pouzivatelov." });
        }
        res.json(users);
    });
});

module.exports = router;
