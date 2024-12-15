# Use a lightweight Linux base image
FROM debian:bullseye-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages (e.g., jq, awk)
RUN apt-get update && apt-get install -y \
    bash perl dos2unix gawk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the Bash script into the container
COPY regex_parser.sh /app/

# Make the script executable
RUN chmod +x /app/regex_parser.sh

# Define the default command
CMD ["bash", "/app/regex_parser.sh"]