const express = require("express");
const cors = require("cors");

const app = express();

app.use(cors());
app.use(express.json());

app.post("/submit_code", (req, res) => {
    const { code } = req.body;
    if (!code) {
        return res.status(400).json({ message: "Code is required" });
    }

    console.log("Received code:", code);
    res.json({ message: "Code received successfully", receivedCode: code });
});

app.listen(2000, () => {
    console.log("Server running on port 2000");
});