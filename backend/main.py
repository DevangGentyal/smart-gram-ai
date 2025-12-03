## This Main Module Gets AI response for the Query based on Knowledgebase

# Import Packages
import os
import json
import re
from fastapi import FastAPI, Header, HTTPException, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv 
from langchain import hub
from langchain_community.embeddings import CohereEmbeddings as OriginalCohereEmbeddings
import cohere
from langchain_community.vectorstores import Chroma
from langchain.chat_models import init_chat_model
from langchain.prompts import ChatPromptTemplate, SystemMessagePromptTemplate
from langchain_core.documents import Document
from langgraph.graph import START, StateGraph
from typing_extensions import List, TypedDict
from basic_llm import build_simple_graph 
from rag_llm import build_rag_graph
from rag_llm import setRagSystemPrompt
from vectorize import vectorize, devectorize

# Input Query
query = "Benifit of PM-KISAN yojana?"
past_msgs = [
    {"role": "user", "content": "Hello"},
    {"role": "assistant", "content": "Hi! How can I help you today?"},
]
formatted_history = "\n".join([f"{m['role'].capitalize()}: {m['content']}" for m in past_msgs])

# Load ENV Keys
load_dotenv()
os.environ["GOOGLE_API_KEY"] = os.getenv("GOOGLE_API_KEY")
os.environ["COHERE_API_KEY"] = os.getenv("COHERE_API_KEY")

# Load LLM
llm = init_chat_model("gemini-2.5-flash",model_provider="google_genai")

class FixedCohereEmbeddings(OriginalCohereEmbeddings):
    """Patched version to bypass missing 'user_agent' bug in older LangChain."""
    def __init__(self, **kwargs):
        # Force creation of a proper Cohere client manually
        if "client" not in kwargs:
            api_key = kwargs.get("cohere_api_key") or os.getenv("COHERE_API_KEY")
            if not api_key:
                raise ValueError("COHERE_API_KEY not found. Please set the key.")
            kwargs["client"] = cohere.Client(api_key)
        super().__init__(**kwargs)
        
    @classmethod
    def validate_environment(cls, values): 
        values["user_agent"] = "LangChainFixedCohere/0.3"
        return values

# Load VectorStore and RAG prompt/
persist_dir = ("knowledgebase")
collection_name = "knowledgebaseV1"
# embedder = SentenceTransformerEmbeddings(model_name="all-MiniLM-L6-V2")
new_embedder = FixedCohereEmbeddings(model="embed-multilingual-v3.0")
vector_store = Chroma(
    persist_directory=persist_dir,
    collection_name=collection_name,
    embedding_function=new_embedder
)

# Propmt Templates
basic_system_prompt_content = """
ROLE: 
You are **Smart Gram AI**, a female multilingual assistant created by **I.T.E. Software Solutions Pune**. You speak politely, simply, and clearly, suitable for rural citizens.

TASK: 
Classify each user query and provide the correct output JSON.

LANGUAGE DETECTION AND RESPONSE:
- Detect if the user message is in English, Hindi, or Marathi
- **CRITICAL**: Your "ans" field MUST be in the EXACT SAME language as the user's query
- If user writes in English → respond in English
- If user writes in Hindi → respond in Hindi  
- If user writes in Marathi → respond in Marathi
- NEVER mix languages or respond in a different language than the user used

DEFINITIONS:
- basic → small talk, greetings, questions about yourself, app usage, casual conversation
- rag → factual queries requiring knowledge base lookup

BEHAVIOR FOR BASIC QUERIES:
- type = "basic"
- language = "English" or "Hindi" or "Marathi" (whichever the user used)
- ans = your response in the SAME language as the user's query
- ragQuery = original user query in user's language
- enhancedRagQuery = ""

BEHAVIOR FOR RAG QUERIES:
- type = "rag"
- language = "English" or "Hindi" or "Marathi" (whichever the user used)
- ans = ""
- ragQuery = original user query in user's language
- enhancedRagQuery = rewrite query in English for better document retrieval

CRITICAL LANGUAGE MATCHING RULES:
- Match the user's language EXACTLY
- If they say "Hello" → respond "Hello! How can I help you?"
- If they say "नमस्ते" → respond "नमस्ते! मैं आपकी कैसे मदद कर सकती हूँ?"
- If they say "नमस्कार" → respond "नमस्कार! मी तुम्हाला कशी मदत करू शकते?"

OUTPUT RULES:
- Output ONLY raw JSON
- No markdown, no code blocks, no ```json
- JSON must be valid and complete

JSON Structure:
{{
  "type": "basic" or "rag",
  "language": "English" or "Hindi" or "Marathi",
  "ans": "<response_in_exact_user_language_or_empty>",
  "ragQuery": "<original_user_query>",
  "enhancedRagQuery": "<enhanced_english_query_or_empty>"
}}
"""

basic_system_prompt = SystemMessagePromptTemplate.from_template(basic_system_prompt_content)


# Build Graphs
basic_graph = build_simple_graph(llm, basic_system_prompt)
rag_graph = build_rag_graph(vector_store, llm)


app = FastAPI()
API_TOKEN = "12345678"

# Request Input Schema 
class QueryRequest(BaseModel):
    query: str
    chat_history: list = []

 
 
# Handling CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    # allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

# JSON cleaner Util
def extract_and_fix_json(text: str):
    if not text:
        return {}

    # Remove code block indicators ```json ... ```
    cleaned = re.sub(r"```json|```", "", text).strip()

    # Remove trailing commas before } or ]
    cleaned = re.sub(r",(\s*[}\]])", r"\1", cleaned)

    # Extract JSON if there is text around it
    json_match = re.search(r"\{.*\}", cleaned, re.DOTALL)
    if json_match:
        cleaned = json_match.group(0)

    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        return {}

 
@app.post("/main")
def main(request: QueryRequest, authorization: str = Header(None)):
    # if authorization != f"Bearer {API_TOKEN}":
    #     raise HTTPException(status_code=401, detail="Unauthorized")

    query = request.query
    past_msgs = request.chat_history
    print(past_msgs)
    formatted_history = "\n".join([f"{m['role'].capitalize()}: {m['content']}" for m in past_msgs])

    # Call Basic LLM first
    # basic_graph = build_simple_graph(llm, basic_system_prompt)
    response = basic_graph.invoke({"question": query, "chat_history": formatted_history})
    print("--Basic Response--\n ",str(response))
    raw_output = response["answer"]

    parsed_output = extract_and_fix_json(raw_output)

    if "language" not in parsed_output:
        print("JSON parse failed. raw output was:", raw_output)
        parsed_output = {"type": "rag", "ans": "", "language": "Hindi"}  # fallback

    language_detected = parsed_output["language"]
    
    # Jump to RAG if not basic
    if parsed_output["type"] == "basic":
        print("\n\n---- Basic LLM Call ----")
        return {"answer": parsed_output["ans"],"language":language_detected}
    else:
        print("\n\n---- RAG LLM Call ----")
        
        rag_query = parsed_output["enhancedRagQuery"]
        rag_system_prompt_content = f"""
        ROLE:
        You are **Smart Gram AI**, a female multilingual voice assistant created by **I.T.E. Software Solutions Pune**.
        
        TASK:
        Answer the user's question using ONLY the information provided in the context below.
        
        LANGUAGE REQUIREMENT - CRITICAL:
        - The user has asked their question in a specific language (English, Hindi, or Marathi)
        - You MUST respond in the EXACT SAME language they used
        - Look at the user's query carefully and match their language precisely
        - If user query is in English → answer in English
        - If user query is in Hindi → answer in Hindi (हिंदी में जवाब दें)
        - If user query is in Marathi → answer in Marathi (मराठीत उत्तर द्या)
        
        CONTEXT RULES:
        1. Use ONLY the context provided below to answer
        2. If the context doesn't contain the answer, say:
           - In English: "I don't know based on the information I have."
           - In Hindi: "मुझे दी गई जानकारी के आधार पर यह नहीं पता।"
           - In Marathi: "मला दिलेल्या माहितीच्या आधारे हे माहित नाही।"
        3. Do NOT hallucinate or add information not in the context
        4. Keep your tone warm, respectful, and simple
        5. Explain in rural-friendly language suitable for village communities
        
        PERSONALITY:
        - Warm and helpful Indian female assistant
        - Patient and understanding
        - Uses simple, clear language
        - Respectful and friendly
        
        OUTPUT:
        - Respond in the SAME language as the user's question
        - Keep it concise and clear
        - Use simple words that rural citizens can understand
        - Do not include any metadata or notes
        """

        rag_system_prompt = SystemMessagePromptTemplate.from_template(rag_system_prompt_content)
        setRagSystemPrompt(rag_system_prompt)
        
        response = rag_graph.invoke({"question": rag_query, "chat_history": formatted_history})
        return {"answer": response["answer"],"language":language_detected}

@app.post("/update")
async def update(
    action: str = Form(...),
    file_id: str = Form(...),
    file_name: str = Form(...),
    file_type: str = Form(...),
    pdf_file: UploadFile | None = None,  # Optional for delete
    authorization: str = Header(None)
):
    uploads_dir = "uploads"
    os.makedirs(uploads_dir, exist_ok=True)

    if action == "add" and pdf_file:
        # Check if doc already exists
        result = vector_store.get(where={"file_id": file_id}, include=["metadatas"])
        if result and len(result["ids"]) > 0:
            print("File Already Exists")
            return {"status": "PDF already Added"}
        
        # Save the PDF locally
        file_path = os.path.join(uploads_dir, f"{file_id}_{pdf_file.filename}")
        contents = await pdf_file.read()
        with open(file_path, "wb") as f:
            f.write(contents)

        # Add to VectorStore
        await vectorize(file_path, file_id, vector_store)
        return {"status": "PDF added and vectorized"}

    elif action == "delete":
        file_path = ""
        if file_name:
            file_path = os.path.join(uploads_dir, f"{file_id}_{file_name}.{file_type}")
            print("Deleting: ",file_path)
            if os.path.exists(file_path):
                os.remove(file_path)
                
        # Remove from VectorStore
        await devectorize(file_path,file_id, vector_store)
        return {"status": "PDF deleted!"}
    
    
