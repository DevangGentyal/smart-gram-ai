from langchain.prompts import  ChatPromptTemplate, HumanMessagePromptTemplate
from langgraph.graph import START, StateGraph
from typing_extensions import TypedDict

class State(TypedDict):
    question: str
    chat_history: str
    answer: str
    
def build_simple_graph(llm, system_prompt):
    def generate(state:State):
        user_msg = HumanMessagePromptTemplate.from_template("question: {question}, chat_history: {chat_history}")
        custom_prompt = ChatPromptTemplate.from_messages([system_prompt, user_msg])
        messages = custom_prompt.format_messages(
            question=state["question"],
            chat_history=state["chat_history"]
        )
        response = llm.invoke(messages)
        return {"answer":response.content}

    graph_builder = StateGraph(State).add_sequence([generate])
    graph_builder.add_edge(START,"generate")
    return graph_builder.compile()