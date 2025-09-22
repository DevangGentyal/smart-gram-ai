from langchain.prompts import  ChatPromptTemplate, HumanMessagePromptTemplate
from langgraph.graph import START, StateGraph
from typing_extensions import TypedDict,List
from langchain_core.documents import Document

class State(TypedDict):
    question: str
    context:List[Document]
    chat_history: str
    answer: str
    
def build_rag_graph(vector_sotre,llm,system_prompt):
    def retrive(state:State):
        retrieved_docs  = vector_sotre.similarity_search(state["question"],k=20)
        print("Retrived Docs: "+str(retrieved_docs))
        return {"context":retrieved_docs}
    
    def generate(state:State):
       
        docs_content = "\n\n".join(doc.page_content for doc in state["context"])
        user_msg = HumanMessagePromptTemplate.from_template("question: {question}, context: {context}, chat_history: {chat_history}")
        custom_prompt = ChatPromptTemplate.from_messages([system_prompt, user_msg])
        messages = custom_prompt.format_messages(
            question=state["question"],
            context=docs_content,
            chat_history=state["chat_history"]
        )
        
        response = llm.invoke(messages)
        return {"answer":response.content}

    graph_builder = StateGraph(State).add_sequence([retrive,generate])
    graph_builder.add_edge(START,"retrive")
    return graph_builder.compile()