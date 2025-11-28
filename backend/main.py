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
from langchain_community.embeddings import SentenceTransformerEmbeddings
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
You are a classifier to determine whether the user question is a "basic" type or "rag" type.
Definitions:
- basic → greetings, small talk, general questions that do NOT need any document.
- rag → knowledge-based, information-seeking, or anything that may require the knowledge base.

Rules:
1. If the query is basic → set "type" to "basic" AND write the answer yourself.
2. If the query is rag → set "type" to "rag" and leave "ans" empty.
3. If the query is rag → also rewrite and enhance the query to make it clearer and more specific for document search.
4. Detect the user's language (Hindi/Marathi/English).
5. Output must be valid JSON only. No explanations. No markdown.

JSON Structure:
{{
  "type": "basic" or "rag",
  "language": "<detected_language>",
  "ans": "<basic_answer_or_empty>",
  "ragQuery": "<original_user_query>",
  "enhancedRagQuery": "<improved_query_or_empty>"
}}

Now process the user query strictly using the above rules.
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
    cleaned_text = re.sub(r",(\s*[}\]])", r"\1", raw_output.strip())

    try:
        parsed_output = json.loads(cleaned_text)
    except json.JSONDecodeError:
        parsed_output = {"type": "rag", "ans": ""}

    # Jump to RAG if not basic
    if parsed_output["type"] == "basic":
        print("\n\n---- Basic LLM Call ----")
        return {"answer": parsed_output["ans"]}
    else:
        print("\n\n---- RAG LLM Call ----")
        
        rag_query = parsed_output["enhancedRagQuery"]
        language_detected = parsed_output["language"]
        rag_system_prompt_content = f"""
        You are SmartGram AI, a helpful assistant for village citizens.

        Rules:
        1. Use ONLY the information provided in the context to answer.
        2. If the answer is not fully supported by the context, say "I don't know".
        3. Use simple, clear language suitable for villagers.
        4. Do NOT add extra details not present in the context.
        5. Answer strictly in the user's language: {language_detected}.


        User Question is in {language_detected}

        Now give the final answer in {language_detected}.
        """
        rag_system_prompt = SystemMessagePromptTemplate.from_template(rag_system_prompt_content)
        setRagSystemPrompt(rag_system_prompt)
        
        response = rag_graph.invoke({"question": rag_query, "chat_history": formatted_history})
        return {"answer": response["answer"]}

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
    
    
