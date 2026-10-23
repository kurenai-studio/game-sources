import express from "express";

const app = express();
app.use(express.json());
app.use(express.static("public"));

app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

const port = Number(process.env.PORT) || 3004;
app.listen(port, () => console.log(`Listening on http://localhost:${port}`));