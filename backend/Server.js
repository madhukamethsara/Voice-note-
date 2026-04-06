import express from "express";
import multer from "multer";
import fs from "fs";
import path from "path";
import OpenAI, { toFile } from "openai";
import dotenv from "dotenv";

dotenv.config();

const app = express();
app.use(express.json());


const uploadsDir = path.join(process.cwd(), "uploads");

if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}


const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
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


function buildModulePrompt(moduleName = "") {
  const commonPrompt = `
This is a university lecture recording.
Expect clear academic language, technical terminology, software engineering concepts,
database terms, mobile app development terms, and module codes.
Preserve important keywords accurately where possible.
Possible terms include:
OOP, inheritance, polymorphism, encapsulation, abstraction,
Flutter, Dart, Firebase, Firestore, Supabase, REST API,
SQL, MySQL, normalization, ER diagram, algorithm,
UI, UX, backend, frontend, API, authentication, IoT,
ESP32, RFID, sensor, machine learning, transcript, summary.
`.trim();

  const modulePrompts = {
    "software engineering":
      "Expect terms like UML, requirements, design patterns, architecture, testing, agile, scrum, use case, class diagram.",
    "information management and retrieval":
      "Expect terms like indexing, ranking, precision, recall, search engine, query processing, retrieval model, relevance.",
    "mobile application development":
      "Expect terms like Flutter, widgets, state management, Firebase, API integration, Android, iOS, navigation.",
    "iot":
      "Expect terms like ESP32, RFID, ultrasonic sensor, microcontroller, edge computing, MQTT, embedded systems.",
    "database":
      "Expect terms like SQL, normalization, foreign key, primary key, join, relation, schema, ERD.",
  };

  const normalized = moduleName.trim().toLowerCase();
  const moduleSpecificPrompt = modulePrompts[normalized] || "";

  return `${commonPrompt} ${moduleSpecificPrompt}`.trim();
}


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

    const language = (req.body.language || "en").trim();
    const moduleName = (req.body.moduleName || "").trim();

    console.log("Received file:", {
      originalname: req.file.originalname,
      filename: req.file.filename,
      mimetype: req.file.mimetype,
      size: req.file.size,
      path: req.file.path,
      language,
      moduleName,
    });

    const openAiFile = await toFile(
      fs.createReadStream(req.file.path),
      req.file.originalname || req.file.filename
    );

    const transcription = await client.audio.transcriptions.create({
      file: openAiFile,
      model: "gpt-4o-mini-transcribe",
      language,
      prompt: buildModulePrompt(moduleName),
    });

    const transcriptText = transcription.text?.trim() || "";

    console.log("Transcript done");

    return res.json({
      transcript: transcriptText,
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

    const { text } = req.body;

    if (!text || !text.trim()) {
      return res.status(400).json({ error: "Text is required" });
    }

    const prompt = `
You are an AI assistant helping university students.

Summarize the following lecture content clearly and concisely.
Keep key technical terms and concepts.

Text:
${text}
`;

    const response = await client.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.3,
    });

    const summary =
      response.choices?.[0]?.message?.content?.trim() || "";

    return res.json({ summary });
  } catch (error) {
    console.error("SUMMARY ERROR:", error);

    return res.status(500).json({
      error: "Failed to summarize",
      details: error?.message || "Unknown summary error",
    });
  }
});

app.post('/generate-daily-quiz', async (req, res) => {
  try {
    const { moduleName, content, questionCount = 20 } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({ error: 'Content is required' });
    }

    const prompt = `
You are an AI tutor for university students.

Based only on these exam revision summaries for the module "${moduleName}",
generate EXACTLY ${questionCount} multiple choice questions.

Rules:
- Exactly ${questionCount} questions
- Exactly 4 options per question
- Include correctAnswer
- Include a short explanation
- Return ONLY valid JSON

Format:
{
  "mcqs": [
    {
      "question": "Question text",
      "options": ["A", "B", "C", "D"],
      "correctAnswer": "Correct option text",
      "explanation": "Short explanation"
    }
  ]
}

Content:
${content}
`;

    const response = await client.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.4,
    });

    let raw = response.choices?.[0]?.message?.content?.trim() || "";

    // Clean markdown if exists
    if (raw.startsWith("```")) {
      raw = raw.replace(/^```[a-z]*\s*/i, "").replace(/\s*```$/i, "");
    }

    const parsed = JSON.parse(raw);

    if (!parsed.mcqs || !Array.isArray(parsed.mcqs)) {
      return res.status(500).json({ error: "Invalid MCQ format from AI" });
    }

    res.json(parsed);

  } catch (error) {
    res.status(500).json({ error: "Failed to generate MCQs" });
  }
});

app.listen(3000, "0.0.0.0", () => {
  console.log("Server running on port 3000");
});