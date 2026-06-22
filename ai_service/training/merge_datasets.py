import os
import shutil
import yaml

def merge_split(src_dir, dst_dir, split, new_class_id=9):
    src_split_img_dir = os.path.join(src_dir, split, "images")
    src_split_lbl_dir = os.path.join(src_dir, split, "labels")
    
    dst_split_img_dir = os.path.join(dst_dir, split, "images")
    dst_split_lbl_dir = os.path.join(dst_dir, split, "labels")
    
    if not os.path.exists(src_split_img_dir):
        print(f"Split {split} images directory not found in source: {src_split_img_dir}")
        return
        
    os.makedirs(dst_split_img_dir, exist_ok=True)
    os.makedirs(dst_split_lbl_dir, exist_ok=True)
    
    images = [f for f in os.listdir(src_split_img_dir) if os.path.isfile(os.path.join(src_split_img_dir, f))]
    print(f"Merging split '{split}': Found {len(images)} images in {src_split_img_dir}")
    
    copied_count = 0
    for img_name in images:
        # Prevent collisions by prepending "fight_"
        new_img_name = f"fight_{img_name}"
        src_img_path = os.path.join(src_split_img_dir, img_name)
        dst_img_path = os.path.join(dst_split_img_dir, new_img_name)
        
        # Copy image
        shutil.copy2(src_img_path, dst_img_path)
        
        # Process and copy label
        # Get label file name by replacing extension with .txt
        base_name, _ = os.path.splitext(img_name)
        lbl_name = f"{base_name}.txt"
        new_lbl_name = f"fight_{lbl_name}"
        
        src_lbl_path = os.path.join(src_split_lbl_dir, lbl_name)
        dst_lbl_path = os.path.join(dst_split_lbl_dir, new_lbl_name)
        
        if os.path.exists(src_lbl_path):
            with open(src_lbl_path, 'r') as f:
                lines = f.readlines()
                
            new_lines = []
            for line in lines:
                parts = line.strip().split()
                if parts:
                    # Class ID is the first token. Map it from 0 to new_class_id
                    class_id = int(parts[0])
                    # In single-class fights dataset, class_id is 0
                    if class_id == 0:
                        parts[0] = str(new_class_id)
                    new_lines.append(" ".join(parts) + "\n")
                    
            with open(dst_lbl_path, 'w') as f:
                f.writelines(new_lines)
        else:
            # If label file does not exist, write an empty file
            with open(dst_lbl_path, 'w') as f:
                pass
                
        copied_count += 1
        
    print(f"Finished split '{split}': Merged {copied_count} files successfully.")

def update_data_yaml(dst_dir, new_class_name="fight"):
    yaml_path = os.path.join(dst_dir, "data.yaml")
    if not os.path.exists(yaml_path):
        print(f"data.yaml not found at: {yaml_path}")
        return
        
    with open(yaml_path, 'r') as f:
        data = yaml.safe_load(f)
        
    names = data.get('names', [])
    if isinstance(names, dict):
        # In case names is a dict, convert/handle it
        max_idx = max(names.keys()) if names else -1
        names[max_idx + 1] = new_class_name
        data['nc'] = len(names)
    elif isinstance(names, list):
        if new_class_name not in names:
            names.append(new_class_name)
        data['names'] = names
        data['nc'] = len(names)
        
    with open(yaml_path, 'w') as f:
        yaml.safe_dump(data, f, default_flow_style=False)
        
    print(f"Updated data.yaml: nc set to {data['nc']}, names list updated to {data['names']}")

def main():
    src_dir = r"D:\smooke"
    dst_dir = r"D:\El7a2ny-trial\ai_service\training\emergency_dataset"
    
    print("Starting dataset merge...")
    for split in ["train", "valid", "test"]:
        merge_split(src_dir, dst_dir, split)
        
    update_data_yaml(dst_dir)
    print("Dataset merge completed successfully!")

if __name__ == "__main__":
    main()
