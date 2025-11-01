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
from langchain_community.vectorstores import Chroma
from langchain.chat_models import init_chat_model
from langchain.prompts import ChatPromptTemplate, SystemMessagePromptTemplate
from langchain_core.documents import Document
from langgraph.graph import START, StateGraph
from typing_extensions import List, TypedDict
from basic_llm import build_simple_graph 
from rag_llm import build_rag_graph
from vectorize import vectorize, devectorize

# Input Query
query = "Benifit of PM-KISAN yojana?"
past_msgs = [
    {"role": "user", "content": "Hello"},
    {"role": "assistant", "content": "Hi! How can I help you today?"},
]
formatted_history = "\n".join([f"{m['role'].capitalize()}: {m['content']}" for m in past_msgs])

# Load LLM
load_dotenv()
os.environ["GOOGLE_API_KEY"] = os.getenv("GOOGLE_API_KEY")
llm = init_chat_model("gemini-2.5-flash",model_provider="google_genai")

# Load VectorStore and RAG prompt/
persist_dir = ("knowledgebase")
collection_name = "knowledgebaseV1"
embedder = SentenceTransformerEmbeddings(model_name="all-MiniLM-L6-V2")
vector_store = Chroma(
    persist_directory=persist_dir,
    collection_name=collection_name,
    embedding_function=embedder
)

# Propmt Templates
basic_system_prompt_content = """
        You are a classifier to determine whether the User Question is a 'basic' type or 'rag' type.
        basic -> general, greating, basic, memory, any basic task which dosen't need a document to be reffered
        rag -> knowledge based, information seeking, related to some docs
        If its a baisc, write the answer to the question by yourself.
        Give response as a VALID JSON array structrued and formatted well as below example:
        Give direct JSON with no headers or footer tags...start with the JSON block itself without Markdown Wrapper Formating
        {{
            "type":"basic",
            "ans":"Hi, How may I help You!",
        }}
        OR
        {{
            "type":"rag",
            "ans":"",
        }}
"""
basic_system_prompt = SystemMessagePromptTemplate.from_template(basic_system_prompt_content)
rag_builtin_prompt = hub.pull("rlm/rag-prompt",api_url="https://api.smith.langchain.com")
rag_system_prompt_content = f"""
        You are a SmartGram AI an helpful assistant in general for Village Citizens based on a Knowledge Base
        Follow these rules while answering:
        1. Don't Miss out any IMP information
        2. Use simple language suitable for villagers.
        3. If info is not in the context, say 'I don’t know'.
"""
rag_system_prompt = SystemMessagePromptTemplate.from_template(rag_system_prompt_content)

# Build Graphs
rag_graph = build_rag_graph(vector_store, llm, rag_system_prompt)
basic_graph = build_simple_graph(llm, basic_system_prompt)


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
        # rag_graph = build_rag_graph(vector_store, llm, rag_system_prompt)
        response = rag_graph.invoke({"question": query, "chat_history": formatted_history})
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
    
    
