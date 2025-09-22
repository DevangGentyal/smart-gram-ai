from langchain.document_loaders import PyPDFLoader
from langchain.embeddings import SentenceTransformerEmbeddings
from langchain.vectorstores import Chroma
from langchain.text_splitter import RecursiveCharacterTextSplitter
import os

embedder = SentenceTransformerEmbeddings(model_name="all-MiniLM-L6-V2")

async def vectorize(pdf_path,pdf_id):
    # Load PDF
    loader = PyPDFLoader(pdf_path)
    documents = loader.load()

    # Split into chunks
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=200)
    chunks = text_splitter.split_documents(documents)

    # Add metadata to track PDF source
    for doc in chunks:
        doc.metadata["pdf_id"] = pdf_id
        doc.metadata["source"] = os.path.basename(pdf_path)

    persist_dir = "knowledgebase"
    collection_name = "knowledgebaseV1"

    # Check if vectorstore already exists
    if os.path.exists(persist_dir):
        vectorstore = await Chroma(
            persist_directory=persist_dir,
            embedding_function=embedder,
            collection_name=collection_name
        )
        vectorstore.add_documents(chunks)
    else:
        vectorstore = await Chroma.from_documents(
            chunks,
            embedding_function=embedder,
            collection_name=collection_name,
            persist_directory=persist_dir
        )

    # Save changes
    vectorstore.persist()

async def devectorize(pdf_path,pdf_id):
    persist_dir = "knowledgebase"
    collection_name = "knowledgebaseV1"
    vectorstore = await Chroma(
            persist_directory=persist_dir,
            embedding_function=embedder,
            collection_name=collection_name
        )
    await vectorstore.delete(where={"pdf_id": pdf_id})
    vectorstore.persist()