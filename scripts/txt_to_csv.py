import os
import csv


def format_title(filename):
    """Capitalize the first letter of each word and make the rest lowercase in the filename."""
    return " ".join(word.capitalize() for word in filename.split())


def read_and_process_files(folder_path):
    """Process text files in the specified folder and generate a CSV with song details ordered alphabetically."""
    # Initialize the counters and list to store file names
    counter = 1
    skipped_files = 0
    file_details = []

    # Collect all eligible files first
    for filename in os.listdir(folder_path):
        if filename.endswith(".txt"):
            if any(char.isdigit() for char in filename):
                skipped_files += 1
            else:
                file_path = os.path.join(folder_path, filename)
                with open(file_path, "r", encoding="utf-8") as txt_file:
                    lyrics = txt_file.read()
                file_details.append(
                    (filename[:-4], lyrics)
                )  # Store filename without extension and lyrics

    # Sort files alphabetically by the formatted title
    file_details.sort(key=lambda x: format_title(x[0]))

    # CSV file to write the song data
    csv_filename = "songs.csv"
    with open(csv_filename, mode="w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file, delimiter=";")  # Use semicolon as the delimiter
        # Write the headers
        writer.writerow(["SongNum", "Title", "Key", "Lyrics"])

        # Process each file in alphabetical order
        for title, lyrics in file_details:
            # Write the song details to the CSV
            writer.writerow([counter, format_title(title), "", lyrics])
            counter += 1

    print(f"Total files processed: {counter - 1}")
    print(f"Total files skipped: {skipped_files}")


# Usage example (uncomment and modify the path to use):
read_and_process_files("songs/")
