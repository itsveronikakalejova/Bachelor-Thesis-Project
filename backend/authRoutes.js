const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('./db'); // Napojenie na MySQL
const router = express.Router();

// Registrácia používateľa
router.post('/register', async (req, res) => {
    const { username, email, password } = req.body;
    if (!username || !email || !password) return res.status(400).json({ message: "Všetky polia sú povinné." });

    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        db.query("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)",
            [username, email, hashedPassword],
            (err, results) => {
                if (err) return res.status(500).json({ message: "Chyba pri registrácii", error: err });
                res.status(201).json({ message: "Úspešná registrácia!" });
            });
    } catch (err) {
        res.status(500).json({ message: "Interná chyba servera" });
    }
});

// Prihlásenie používateľa
router.post('/login', (req, res) => {
    const { username, password } = req.body;
    db.query("SELECT * FROM users WHERE username = ?", [username], async (err, results) => {
        if (err || results.length === 0) return res.status(401).json({ message: "Neplatné prihlasovacie údaje" });

        const user = results[0];
        const isPasswordValid = await bcrypt.compare(password, user.password_hash);
        if (!isPasswordValid) return res.status(401).json({ message: "Neplatné heslo" });

        const token = jwt.sign({ id: user.id, username: user.username }, "SECRET_KEY", { expiresIn: "1h" });
        res.json({ message: "Prihlásenie úspešné", token });
    });
});

module.exports = router;