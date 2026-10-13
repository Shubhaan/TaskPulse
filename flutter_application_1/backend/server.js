const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');

const app = express();
app.use(cors());
app.use(express.json());

// 1. Configure Database Connection
const pool = mysql.createPool({
    host: 'localhost',
    user: 'root', 
    password: '', 
    database: 'daymark_db',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    dateStrings: true // <--- THIS FIXES THE TIMEZONE BUG
});

pool.getConnection()
    .then(connection => {
        console.log('Connected to MySQL Database (daymark_db) successfully!');
        connection.release();
    })
    .catch(err => {
        console.error('Database connection failed:', err.message);
    });

// 2. Authentication Route
app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        const [users] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
        
        if (users.length === 0) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }
        
        const user = users[0];
        res.json({
            token: 'dummy_jwt_token_123',
            user: { id: user.id, email: user.email }
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Database error' });
    }
});

// 3. Fetch Tasks Route
app.get('/api/tasks', async (req, res) => {
    try {
        const [tasks] = await pool.query('SELECT * FROM tasks WHERE user_id = 1');
        res.json(tasks);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Database error' });
    }
});

// 4. Add Task Route
app.post('/api/tasks', async (req, res) => {
    try {
        const { title, category, task_time, task_date, user_id } = req.body;
        
        const [result] = await pool.query(
            'INSERT INTO tasks (title, category, task_time, done, task_date, user_id) VALUES (?, ?, ?, 0, ?, ?)',
            [title, category, task_time, task_date, user_id]
        );
        
        const [newTask] = await pool.query('SELECT * FROM tasks WHERE id = ?', [result.insertId]);
        res.json(newTask[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Database error' });
    }
});

// 5. Update Task Status Route
app.patch('/api/tasks/:id', async (req, res) => {
    try {
        const taskId = req.params.id;
        const { done } = req.body;
        const doneStatus = done ? 1 : 0; 

        await pool.query('UPDATE tasks SET done = ? WHERE id = ?', [doneStatus, taskId]);
        const [updatedTask] = await pool.query('SELECT * FROM tasks WHERE id = ?', [taskId]);
        
        res.json(updatedTask[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Database error' });
    }
});

// 6. Start Server
const PORT = 8000;
app.listen(PORT, () => {
    console.log(`Server running on http://127.0.0.1:${PORT}`);
});