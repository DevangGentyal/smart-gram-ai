## This Module Querys the Vector Store to results related to the Query using Langchain Framework

# Import Packages
from langchain.vectorstores import Chroma
from langchain.embeddings import SentenceTransformerEmbeddings

# Load VectorStore
persist_dir = "backend/knowledgebase"
collection_name = "knowledgebaseV2"
embedder = SentenceTransformerEmbeddings(model_name="all-MiniLM-L6-V2")

vectorstore = Chroma(
    persist_directory=persist_dir,
    collection_name=collection_name,
    embedding_function=embedder
)

# Query to VectorStore
query = "What are these Rules Called?"
results = vectorstore.similarity_search(query, k=5)
print(results)