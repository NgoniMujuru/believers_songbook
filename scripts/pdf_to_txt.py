import fitz  # PyMuPDF
import re
import csv

# Path to the uploaded PDF file
pdf_path = "songs.pdf"

# Open the PDF file
pdf_document = fitz.open(pdf_path)

# Initialize a variable to hold the extracted text
extracted_text = ""

# Define the page range for songs 1-10 (1-indexed)
start_page = 13  # Page where songs start
end_page = 173  # Approximate page where song 10 ends

# Loop through the defined page range and extract text
for page_num in range(start_page - 1, end_page):
    page = pdf_document.load_page(page_num)
    page_text = page.get_text()
    # Remove lines that contain only page numbers
    filtered_text = "\n".join(
        [
            line
            for line in page_text.splitlines()
            if not re.match(r"^\d+$", line.strip())
        ]
    )
    extracted_text += filtered_text + "\n"

# Save the extracted text to a text file
output_file_path = "songs.txt"
with open(output_file_path, "w", encoding="utf-8") as text_file:
    text_file.write(extracted_text)

print(f"Extracted text saved to {output_file_path}")
