from colorama import Fore
from groq import Groq
from typing import List, Dict

GENERATION_SYSTEM_PROMPT = """
You are a highly skilled medical professional with expertise in diagnosing conditions based on patient symptoms and medical history. 
Provide a diagnosis, listing potential conditions with corresponding confidence scores.
Then, recommend a medication plan, specifying the appropriate medications along with their dosages and frequencies.

Your task is to Generate the best content possible for the user's request.
If the user provides critique, respond with a revised version of your previous attempt.
You must always output the revised content.
"""

REFLECTION_SYSTEM_PROMPT = """
You are a critical evaluator reviewing the performance of a medical professional tasked with diagnosing medical conditions.
Assess the diagnosis, ensuring that it provides accurate, comprehensive, and well-supported potential conditions with confidence scores.
Critique the clarity, accuracy, and relevance of the medication recommendations, including dosages and frequencies.
Provide suggestions for improvement in both diagnostic reasoning and treatment plans.

If the user content has something wrong or something to be improved, output a list of recommendations
and critiques. If the user content is ok and there's nothing to change, output this: <OK>
"""

class ReflectionAgent:
    """An agent that uses the reflection pattern to improve medical diagnoses."""
    
    def __init__(self, model="llama-3.3-70b-versatile"):
        self.client = Groq()
        self.model = model
    
    def complete(self, messages: List[Dict]) -> str:
        """Send a request to the LLM and return the response."""
        response = self.client.chat.completions.create(
            messages=messages, 
            model=self.model
        )
        return response.choices[0].message.content
    
    def run(self, user_input, max_iterations: int = 5, verbose: bool = False) -> str:
        """
        Run the reflection pattern to generate an improved diagnosis.
        
        user_input can be either a string query or a list of conversation messages.
        """
        # Handle both string inputs and conversation history
        if isinstance(user_input, list):
            # Extract symptoms and relevant info from conversation
            system_prompt = GENERATION_SYSTEM_PROMPT + "\n\nBelow is a conversation history. Based on this information, provide a comprehensive diagnosis and medication plan."
            generation_history = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": "Please provide a diagnosis based on the following conversation history: " + str(user_input)}
            ]
        else:
            generation_history = [
                {"role": "system", "content": GENERATION_SYSTEM_PROMPT},
                {"role": "user", "content": user_input}
            ]
        
        reflection_history = [
            {"role": "system", "content": REFLECTION_SYSTEM_PROMPT}
        ]
        
        for i in range(max_iterations):
            # Generate response
            generation = self.complete(generation_history)
            if verbose:
                print(Fore.BLUE + "\n\nGENERATION\n\n", generation)
            
            # Add to histories
            generation_history.append({"role": "assistant", "content": generation})
            reflection_history.append({"role": "user", "content": generation})
            
            # Get critique
            critique = self.complete(reflection_history)
            if verbose:
                print(Fore.GREEN + "\n\nREFLECTION\n\n", critique)
            
            # Check if we're done
            if "<OK>" in critique:
                if verbose:
                    print(Fore.RED + "\n\nStop Sequence found. Stopping the reflection loop...\n\n")
                break
            
            # Add critique to generation history
            generation_history.append({"role": "user", "content": critique})
            reflection_history.append({"role": "assistant", "content": critique})
            
            # Keep histories manageable
            if len(generation_history) > 5:
                generation_history.pop(1)
            if len(reflection_history) > 5:
                reflection_history.pop(1)
        
        return generation