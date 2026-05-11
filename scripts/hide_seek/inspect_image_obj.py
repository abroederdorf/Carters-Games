import os
from google import genai

# --- Configuration ---
API_KEY = "AIzaSyAzZu1AIZdq5Im0q4sW8fdDKNiNbtSyW7A"
MODEL_NAME = "imagen-4.0-generate-001"
client = genai.Client(api_key=API_KEY)

def main():
    print("Inspecting GeneratedImage object attributes...")
    try:
        response = client.models.generate_images(
            model=MODEL_NAME,
            prompt="A small red apple, flat design",
            config={'number_of_images': 1}
        )
        
        if response.generated_images:
            gen_img = response.generated_images[0]
            print(f"GeneratedImage type: {type(gen_img)}")
            
            if hasattr(gen_img, 'image'):
                img_obj = gen_img.image
                print(f"Image object type: {type(img_obj)}")
                print(f"Image object attributes: {dir(img_obj)}")
                
                # Check common byte attributes on the Image object
                for attr in ['image_bytes', 'bytes', 'data', 'content']:
                    if hasattr(img_obj, attr):
                        val = getattr(img_obj, attr)
                        print(f"  Attribute '{attr}' exists! Type: {type(val)}")
                        if isinstance(val, bytes):
                            print(f"    Length: {len(val)} bytes")
            else:
                print("GeneratedImage has no 'image' attribute.")
        else:
            print("No images generated.")
            
    except Exception as e:
        print(f"Error during inspection: {e}")

if __name__ == "__main__":
    main()
