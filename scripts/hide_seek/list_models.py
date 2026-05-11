from google import genai

# --- Configuration ---
API_KEY = "AIzaSyAzZu1AIZdq5Im0q4sW8fdDKNiNbtSyW7A"
client = genai.Client(api_key=API_KEY)

def main():
    print("Listing available models...")
    try:
        models = client.models.list()
        for m in models:
            print(f"Name: {m.name}")
            # Try to print more info if available
            try:
                print(f"  Description: {m.description}")
            except:
                pass
    except Exception as e:
        print(f"Error listing models: {e}")

if __name__ == "__main__":
    main()
