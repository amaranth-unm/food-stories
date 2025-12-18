#!/bin/bash

# Image Optimization Script for Student Uploads
# Reduces file size of large images in stories directories

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Food Stories Image Optimizer ===${NC}"
echo ""

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${RED}Error: ImageMagick is not installed.${NC}"
    echo "Install it with: brew install imagemagick"
    exit 1
fi

# Change to script directory
cd "$(dirname "$0")"

# Create backup directory
BACKUP_DIR="stories/backup-$(date +%Y%m%d-%H%M%S)"
echo -e "${YELLOW}Creating backup at: $BACKUP_DIR${NC}"
mkdir -p "$BACKUP_DIR"

# Find all image files in stories directories
echo ""
echo -e "${GREEN}Finding images in stories directories...${NC}"
echo ""

# Counter for statistics
TOTAL_FILES=0
TOTAL_SIZE_BEFORE=0
TOTAL_SIZE_AFTER=0

# Process all images in stories subdirectories
find stories -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | while read -r img; do
    # Skip backup directory
    if [[ "$img" == *"/backup-"* ]]; then
        continue
    fi
    
    # Get file size before
    SIZE_BEFORE=$(stat -f%z "$img" 2>/dev/null || stat -c%s "$img" 2>/dev/null)
    SIZE_BEFORE_MB=$(echo "scale=2; $SIZE_BEFORE/1048576" | bc)
    
    # Only process if larger than 500KB
    if [ $SIZE_BEFORE -gt 512000 ]; then
        echo -e "${BLUE}Processing:${NC} $img"
        echo -e "  Before: ${YELLOW}${SIZE_BEFORE_MB} MB${NC}"
        
        # Backup original
        BACKUP_PATH="$BACKUP_DIR/$(dirname "$img")"
        mkdir -p "$BACKUP_PATH"
        cp "$img" "$BACKUP_PATH/"
        
        # Create temporary file
        TEMP_FILE="${img}.tmp"
        
        # Optimize: resize to max 1600px width/height, 85% quality
        convert "$img" -resize '1600x1600>' -quality 85 "$TEMP_FILE"
        
        # Replace original with optimized
        mv "$TEMP_FILE" "$img"
        
        # Get new size
        SIZE_AFTER=$(stat -f%z "$img" 2>/dev/null || stat -c%s "$img" 2>/dev/null)
        SIZE_AFTER_MB=$(echo "scale=2; $SIZE_AFTER/1048576" | bc)
        SAVINGS=$(echo "scale=1; ($SIZE_BEFORE - $SIZE_AFTER) * 100 / $SIZE_BEFORE" | bc)
        
        echo -e "  After:  ${GREEN}${SIZE_AFTER_MB} MB${NC} (saved ${SAVINGS}%)"
        echo ""
        
        ((TOTAL_FILES++))
    else
        echo -e "${BLUE}Skipping (already small):${NC} $img"
    fi
done

echo ""
echo -e "${GREEN}=== Optimization Complete ===${NC}"
echo ""
echo "Backup saved to: $BACKUP_DIR"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the optimized images to ensure quality is acceptable"
echo "2. Commit and push changes to GitHub:"
echo "   git add stories/"
echo "   git commit -m 'Optimize student-uploaded images'"
echo "   git push"
echo ""
