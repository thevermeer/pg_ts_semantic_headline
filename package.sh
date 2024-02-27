# The bsh script concatenates all files in the /sql directory and into a single install package
## Input directory as ARG 1
input_directory=$1

## Output file name as ARG2
output_file=$2

# Concatenate all .sql files into a single file
cat "$input_directory"/*.sql > "$output_file"

echo "Compilation complete. Output file: $output_file"
