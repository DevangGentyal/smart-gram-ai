from langchain.document_loaders import PyPDFLoader
from langchain_community.embeddings import SentenceTransformerEmbeddings
from langchain_community.embeddings import CohereEmbeddings
from langchain.vectorstores import Chroma
from langchain.text_splitter import RecursiveCharacterTextSplitter
import os

# embedder = SentenceTransformerEmbeddings(model_name="all-MiniLM-L6-V2")
# new_embedder = CohereEmbeddings(model="embed-multilingual-v3.0")

async def vectorize(pdf_path,file_id, vectorstore):
    # Load PDF
    loader = PyPDFLoader(pdf_path)
    documents = loader.load()

    # Split into chunks
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=200)
    chunks = text_splitter.split_documents(documents)

    # Add metadata to track PDF source
    for doc in chunks:
        doc.metadata["file_id"] = file_id
        doc.metadata["source"] = os.path.basename(pdf_path)
    # Save changes
    vectorstore.add_documents(chunks)
    vectorstore.persist()

async def devectorize(pdf_path,file_id, vectorstore):
    vectorstore.delete(where={"file_id": file_id})
    vectorstore.persist()