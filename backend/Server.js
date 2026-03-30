import express from "express";
import multer from "multer";
import fs from "fs";
import path from "path";
import OpenAI, { toFile } from "openai";
import dotenv from "dotenv";

dotenv.config();

const app = express();
app.use(express.json());

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/");
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || ".m4a";
    const uniqueName = `${Date.now()}${ext}`;
    cb(null, uniqueName);
  },
});

const upload = multer({ storage });

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

app.get("/", (req, res) => {
  res.send("Backend is running");
});

app.post("/transcribe", upload.single("file"), async (req, res) => {
  let uploadedPath = null;

  try {
    console.log("=== /transcribe HIT ===");

    if (!req.file) {
      console.log("No file uploaded");
      return res.status(400).json({ error: "No file uploaded" });
    }

    uploadedPath = req.file.path;

    console.log("Received file:", {
      originalname: req.file.originalname,
      filename: req.file.filename,
      mimetype: req.file.mimetype,
      size: req.file.size,
      path: req.file.path,
    });

    const openAiFile = await toFile(
      fs.createReadStream(req.file.path),
      req.file.originalname || req.file.filename
    );

    const transcription = await client.audio.transcriptions.create({
      file: openAiFile,
      model: "whisper-1",
      response_format: "text",
    });

    console.log("Transcript done:", transcription);

    return res.json({
      transcript: transcription ?? "",
    });
  } catch (error) {
    console.error("TRANSCRIBE ERROR FULL:", error);

    return res.status(500).json({
      error: "Transcription failed",
      details: error?.message || "Unknown transcription error",
    });
  } finally {
    if (uploadedPath) {
      fs.unlink(uploadedPath, (unlinkErr) => {
        if (unlinkErr) {
          console.error("Failed to delete uploaded temp file:", unlinkErr);
        }
      });
    }
  }
});

app.post("/summarize", async (req, res) => {
  try {
    console.log("=== /summarize HIT ===");
    console.log("Request body:", req.body);

    const { text } = req.body;

    if (!text || !text.trim()) {
      return res.status(400).json({ error: "No text provided" });
    }

    const response = await client.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content:
              "You are an assistant that summarizes university lecture notes clearly and concisely.",
        },
        {
          role: "user",
          content: `Summarize this lecture in a short, clear way:\n\n${text}`,
        },
      ],
      temperature: 0.5,
    });

    const summary =
        response.choices[0]?.message?.content?.trim() || "No summary generated";

    console.log("Summary done:", summary);

    return res.json({
      summary,
    });
  } catch (error) {
    console.error("SUMMARY ERROR FULL:", error);

    return res.status(500).json({
      error: "Summary failed",
      details: error?.message || "Unknown error",
    });
  }
});

app.listen(3000, "0.0.0.0", () => {
  console.log("Server running on port 3000");
});