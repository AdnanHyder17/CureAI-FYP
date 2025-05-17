def sanitize_conversation_for_llm(conversation_data):
    """Remove timestamp and other unnecessary fields from conversation data before sending to LLM."""
    if not conversation_data:
        return []
        
    sanitized_data = []
    for message in conversation_data:
        clean_message = {
            "role": message["role"],
            "content": message["content"]
        }
        sanitized_data.append(clean_message)
    
    return sanitized_data