const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { db, getUsers } = require('./db');
const router = express.Router();

// registracia pouzivatela
router.post('/register', async (req, res) => {
    const { username, email, password } = req.body;
    if (!username || !email || !password) return res.status(400).json({ message: "Vsetky polia su povinne." });

    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        db.query("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)",
            [username, email, hashedPassword],
            (err, results) => {
                if (err) return res.status(500).json({ message: "Chyba pri registracii.", error: err });
                res.status(201).json({ message: "Uspesna registracia." });
            });
    } catch (err) {
        res.status(500).json({ message: "Interna chyba servera." });
    }
});

// prihlasenie pouzivatela
router.post('/login', (req, res) => {
    const { username, password } = req.body;
    db.query("SELECT * FROM users WHERE username = ?", [username], async (err, results) => {
        if (err || results.length === 0) return res.status(401).json({ message: "Neplatne prihlasovacie udaje." });

        const user = results[0];
        const isPasswordValid = await bcrypt.compare(password, user.password_hash);
        if (!isPasswordValid) return res.status(401).json({ message: "Neplatne heslo." });

        const token = jwt.sign({ id: user.id, username: user.username }, "SECRET_KEY", { expiresIn: "1h" });
        res.json({ message: "Prihlasenie uspesne.", token });
    });
});

module.exports = router;