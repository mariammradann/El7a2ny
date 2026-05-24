import os
import argparse
from dotenv import load_dotenv
from roboflow import Roboflow

load_dotenv()

def main():
    parser = argparse.ArgumentParser(description="Download dataset from Roboflow.")
    parser.add_argument("--api_key", type=str, help="Roboflow Private API Key")
    parser.add_argument("--workspace", type=str, help="Roboflow Workspace ID")
    parser.add_argument("--project", type=str, help="Roboflow Project ID")
    parser.add_argument("--version", type=int, default=1, help="Dataset version")
    args = parser.parse_args()

    # Fallback to environment variables
    api_key = args.api_key or os.getenv("ROBOFLOW_API_KEY")
    workspace = args.workspace or os.getenv("ROBOFLOW_WORKSPACE")
    project_id = args.project or os.getenv("ROBOFLOW_PROJECT")

    if not api_key:
        api_key = input("Enter your Roboflow Private API Key: ").strip()
    if not workspace:
        workspace = input("Enter Roboflow Workspace ID: ").strip()
    if not project_id:
        project_id = input("Enter Roboflow Project ID: ").strip()

    print(f"Connecting to Roboflow workspace '{workspace}'...")
    rf = Roboflow(api_key=api_key)
    
    print(f"Fetching project '{project_id}'...")
    project = rf.workspace(workspace).project(project_id)
    
    print(f"Downloading dataset version {args.version} in YOLOv8 format...")
    # This downloads and extracts the dataset into a folder inside the current directory
    dataset = project.version(args.version).download("yolov8")
    
    print("\n✅ Dataset downloaded successfully!")
    print(f"Location: {dataset.location}")
    print("You can now proceed to run the training script.")

if __name__ == "__main__":
    main()
