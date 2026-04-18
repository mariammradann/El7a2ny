import os

directory = r'c:\Users\artif\El7a2ny\client\el7a2ny_app\lib'
fonts_to_replace = "'Unixel'"

for root, dirs, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                if fonts_to_replace in content:
                    content = content.replace(fonts_to_replace, "'NotoSansArabic'")
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"Updated {filepath}")
            except Exception as e:
                print(f"Failed {filepath}: {e}")
