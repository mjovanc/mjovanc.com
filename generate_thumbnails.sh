#!/bin/bash

# function to install ImageMagick using Homebrew (macOS)
install_imagemagick_macos() {
  if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please install Homebrew first."
    exit 1
  fi

  if ! brew list imagemagick &> /dev/null; then
    brew install imagemagick
  fi
}

# check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
  echo "ImageMagick is not installed. Attempting to install it..."
  install_imagemagick_macos

  # check again if ImageMagick is now installed
  if ! command -v convert &> /dev/null; then
    echo "Failed to install ImageMagick. Please install it manually and then run this script again."
    exit 1
  else
    echo "ImageMagick has been successfully installed."
  fi
fi

# define the parent directories
parent_directories=("static/tooling" "static/java")

# desired dimensions
width=1200
height=627

# aspect ratio
aspect_ratio="1.91:1"

# loop through the parent directories
for parent_dir in "${parent_directories[@]}"; do
  # check if the parent directory exists
  if [ -d "$parent_dir" ]; then
    # find all "main.png" files in subdirectories and process them
    find "$parent_dir" -type f -name "main.png" -print0 | while read -d $'\0' main_image; do
      # get the directory of the main image
      dir_path="$(dirname "$main_image")"

      # output thumbnail path
      thumbnail_path="$dir_path/main_thumb.png"

      # generate the thumbnail with the desired dimensions and aspect ratio
      convert "$main_image" -resize ${width}x${height}^ -gravity center -extent ${width}x${height} "$thumbnail_path"

      # check if the thumbnail was created successfully
      if [ $? -eq 0 ]; then
        echo "thumbnail created successfully: $thumbnail_path"
      else
        echo "failed to create a thumbnail for $main_image"
      fi
    done
  else
    echo "directory not found: $parent_dir"
  fi
done
