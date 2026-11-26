import { createClient } from "npm:@supabase/supabase-js@2";
import * as pdfjs from "npm:pdfjs-dist@4.10.38/legacy/build/pdf.mjs";
import { strFromU8, unzipSync } from "npm:fflate@0.8.2";

const headers = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type", "Access-Control-Allow-Methods": "POST, OPTIONS" };
const response = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: { ...headers, "Content-Type": "application/json" } });
const env = (key: string) => Deno.env.get(key) ?? "";

function decodeXml(text: string) {
  return text.replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&#([0-9]+);/g, (_m, n) => String.fromCodePoint(Number(n))).replace(/&#x([0-9a-f]+);/gi, (_m, n) => String.fromCodePoint(parseInt(n, 16)));
}

async function extractText(file: Blob, mimeType: string, path: string) {
  const bytes = new Uint8Array(await file.arrayBuffer());
  const kind = `${mimeType} ${path}`.toLowerCase();
  if (kind.includes("text/plain") || kind.endsWith(".txt")) return { text: new TextDecoder("utf-8", { fatal: false }).decode(bytes), pageBreaks: [] as number[], pageCount: null as number | null };
  if (kind.includes("pdf") || kind.endsWith(".pdf")) {
    const pdf = await pdfjs.getDocument({ data: bytes, disableFontFace: true, isEvalSupported: false, useSystemFonts: true }).promise;
    let text = ""; const pageBreaks: number[] = [];
    for (let pageNo = 1; pageNo <= pdf.numPages; pageNo++) {
      const page = await pdf.getPage(pageNo); const content = await page.getTextContent();
      const pageText = content.items.map((item: { str?: string }) => item.str ?? "").join(" ").trim();
      if (pageNo > 1) { text += "\n\n"; pageBreaks.push(text.length); }
      text += pageText;
    }
    return { text, pageBreaks, pageCount: pdf.numPages };
  }
  if (kind.includes("wordprocessingml.document") || kind.endsWith(".docx")) {
    const files = unzipSync(bytes); const xmlBytes = files["word/document.xml"];
    if (!xmlBytes) throw new Error("DOCX document.xml was not found");
    const xml = strFromU8(xmlBytes); const paragraphs: string[] = []; let cursor = 0;
    while (true) {
      const start = xml.indexOf("<w:p", cursor); if (start < 0) break;
      const openEnd = xml.indexOf(">", start); const close = xml.indexOf("</w:p>", openEnd);
      if (openEnd < 0 || close < 0) break;
      const paragraph = xml.slice(openEnd + 1, close).replaceAll("<w:tab/>", "\t").replaceAll("<w:tab />", "\t").replaceAll("<w:br/>", "\n").replace(/<[^>]*>/g, "");
      paragraphs.push(decodeXml(paragraph)); cursor = close + 6;
    }
    return { text: paragraphs.join("\n"), pageBreaks: [] as number[], pageCount: null as number | null };
  }
  throw new Error("Only PDF, TXT, and DOCX documents are supported");
}

async function embedBatch(texts: string[]) {
  const key = env("GEMINI_API_KEY");
  if (!key) throw new Error("GEMINI_API_KEY is not configured");
  const requests = texts.map((text) => ({
    model: "models/gemini-embedding-2",
    content: { parts: [{ text }] },
    taskType: "RETRIEVAL_DOCUMENT",
    outputDimensionality: 1536,
  }));
  const res = await fetch("https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-2:batchEmbedContents", {
    method: "POST",
    headers: { "x-goog-api-key": key, "Content-Type": "application/json" },
    body: JSON.stringify({ requests }),
  });
  if (!res.ok) {
    const detail = await res.text();
    console.error("Gemini batch embedding error", res.status, detail.slice(0, 500));
    throw new Error(`Gemini embedding API returned ${res.status}`);
  }
  const embeddings = (await res.json())?.embeddings;
  if (!Array.isArray(embeddings) || embeddings.length !== texts.length) throw new Error("Gemini returned an invalid embedding batch");
  return embeddings.map((item: Record<string, unknown>) => {
    const vector = (item.embedding as Record<string, unknown> | undefined)?.values;
    if (!Array.isArray(vector) || vector.length !== 1536) throw new Error("Expected 1536-dimensional Gemini embeddings");
    return vector;
  });
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers });
  if (request.method !== "POST") return response({ error: "Method not allowed" }, 405);
  const auth = request.headers.get("Authorization"); const url = env("SUPABASE_URL"); const anon = env("SUPABASE_ANON_KEY");
  if (!auth?.startsWith("Bearer ") || !url || !anon) return response({ error: "Authentication required" }, 401);
  if (!env("GEMINI_API_KEY")) return response({ error: "Gemini provider secret is not configured" }, 503);
  const client = createClient(url, anon, { global: { headers: { Authorization: auth } }, auth: { persistSession: false, autoRefreshToken: false } });
  const { data: { user }, error: authError } = await client.auth.getUser();
  if (authError || !user) return response({ error: "Invalid session" }, 401);
  const { data: profile } = await client.from("profiles").select("role,status").eq("id", user.id).maybeSingle();
  if (profile?.role !== "owner" || profile.status !== "active") return response({ error: "Owner access required" }, 403);
  let body: { documentId?: unknown };
  try { body = await request.json(); } catch { return response({ error: "Invalid JSON" }, 400); }
  if (typeof body.documentId !== "string" || !/^[0-9a-f-]{36}$/i.test(body.documentId)) return response({ error: "Invalid documentId" }, 400);
  const { data: doc, error: docError } = await client.from("knowledge_documents").select("id,subject_id,lecture_id,status,mime_type,storage_path").eq("id", body.documentId).maybeSingle();
  if (docError || !doc) return response({ error: "Document not found" }, 404);
  if (!doc.storage_path || doc.storage_path.startsWith("/") || doc.storage_path.includes("..")) return response({ error: "Invalid document storage path" }, 400);
  const { data: subject } = await client.from("subjects").select("id").eq("id", doc.subject_id).maybeSingle();
  if (!subject) return response({ error: "Subject not found" }, 404);

  try {
    const { data: file, error: downloadError } = await client.storage.from("course-documents").download(doc.storage_path);
    if (downloadError || !file) throw new Error("Unable to download private course document");
    const extracted = await extractText(file, doc.mime_type, doc.storage_path);
    const cleaned = extracted.text.replaceAll("\u0000", "").replace(/[\t ]+\n/g, "\n").replace(/\n{3,}/g, "\n\n").trim();
    if (!cleaned || cleaned.length > 1_000_000) throw new Error("Extracted text is empty or exceeds the 1 MB processing limit");
    const chunks: Array<{ content: string; index: number; page_number: number | null }> = []; const size = 1400; const overlap = 180;
    for (let start = 0; start < cleaned.length && chunks.length < 800;) {
      let end = Math.min(start + size, cleaned.length);
      if (end < cleaned.length) { const cut = Math.max(cleaned.lastIndexOf("\n", end), cleaned.lastIndexOf(" ", end)); if (cut > start + Math.floor(size * 0.65)) end = cut; }
      const text = cleaned.slice(start, end).trim();
      if (text) chunks.push({ content: text, index: chunks.length, page_number: extracted.pageBreaks.filter((p) => p <= start).length + 1 });
      if (end >= cleaned.length) break; start = end - overlap;
    }
    if (chunks.length === 800 && cleaned.length > size * 800) throw new Error("Document exceeds the 800-chunk processing limit");
    await client.from("knowledge_documents").update({ status: "processing" }).eq("id", doc.id);
    const records: Array<Record<string, unknown>> = [];
    for (let i = 0; i < chunks.length; i += 32) {
      const batch = chunks.slice(i, i + 32);
      const vectors = await embedBatch(batch.map((chunk) => chunk.content));
      batch.forEach((chunk, j) => records.push({
        document_id: doc.id, subject_id: doc.subject_id, lecture_id: doc.lecture_id,
        chunk_index: chunk.index, page_number: chunk.page_number, content: chunk.content,
        embedding: JSON.stringify(vectors[j]),
      }));
    }
    await client.from("knowledge_chunks").delete().eq("document_id", doc.id);
    for (let i = 0; i < records.length; i += 100) {
      const { error } = await client.from("knowledge_chunks").insert(records.slice(i, i + 100));
      if (error) throw new Error("Unable to save knowledge chunks");
    }
    const { error: finishError } = await client.from("knowledge_documents").update({
      status: "ready", page_count: extracted.pageCount,
      metadata: { chunk_count: chunks.length, extracted_at: new Date().toISOString(), embedding_model: "gemini-embedding-2", embedding_dimensions: 1536 },
    }).eq("id", doc.id);
    if (finishError) throw new Error("Unable to mark document ready");
    return response({ documentId: doc.id, chunks: chunks.length, pageCount: extracted.pageCount, status: "ready", provider: "Gemini" });
  } catch (error) {
    await client.from("knowledge_documents").update({ status: "failed" }).eq("id", doc.id);
    console.error("ingest-knowledge failed", error instanceof Error ? error.message : "unknown error");
    return response({ error: "Document ingestion failed. Check Gemini API access and try again." }, 502);
  }
});
