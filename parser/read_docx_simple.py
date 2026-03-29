import zipfile
import xml.etree.ElementTree as ET
import sys

def read_docx(file_path):
    try:
        with zipfile.ZipFile(file_path, 'r') as docx:
            xml_content = docx.read('word/document.xml')
            tree = ET.fromstring(xml_content)
            
            # Namespaces
            ns = {
                'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
            }
            
            texts = []
            for paragraph in tree.findall('.//w:p', ns):
                paragraph_text = []
                for run in paragraph.findall('.//w:t', ns):
                    if run.text:
                        paragraph_text.append(run.text)
                if paragraph_text:
                    texts.append("".join(paragraph_text))
            
            return "\n".join(texts)
    except Exception as e:
        return f"Error: {e}"

if __name__ == "__main__":
    if len(sys.argv) > 1:
        print(read_docx(sys.argv[1]))
    else:
        print("Usage: python read_docx_simple.py <file_path>")
