#!/usr/bin/env bash
# Quality check for generated content
# Usage: ./bin/check-content-quality.sh <article-file> <brief-file>

set -euo pipefail

ARTICLE_FILE="${1:?Usage: check-content-quality.sh <article-file> <brief-file>}"
BRIEF_FILE="${2:?Usage: check-content-quality.sh <article-file> <brief-file>}"

if [[ ! -f "$ARTICLE_FILE" ]]; then
  echo "❌ Article not found: $ARTICLE_FILE"
  exit 1
fi

if [[ ! -f "$BRIEF_FILE" ]]; then
  echo "❌ Brief not found: $BRIEF_FILE"
  exit 1
fi

echo "🔍 Quality Check: $(basename "$ARTICLE_FILE")"
echo ""

ARTICLE_CONTENT=$(cat "$ARTICLE_FILE")
BRIEF_CONTENT=$(cat "$BRIEF_FILE")

# Extract target keyword from brief
TARGET_KEYWORD=$(grep "^# " "$BRIEF_FILE" | head -1 | sed 's/^# //' || echo "")

if [[ -z "$TARGET_KEYWORD" ]]; then
  echo "⚠️  Could not extract target keyword from brief"
  TARGET_KEYWORD="unknown"
fi

echo "🎯 Target keyword: $TARGET_KEYWORD"
echo ""

# Basic stats
WORD_COUNT=$(echo "$ARTICLE_CONTENT" | wc -w | tr -d ' ')
CHAR_COUNT=$(echo "$ARTICLE_CONTENT" | wc -c | tr -d ' ')
HEADING_COUNT=$(grep -c "^## " "$ARTICLE_FILE" || echo 0)
H3_COUNT=$(grep -c "^### " "$ARTICLE_FILE" || echo 0)

echo "📊 Content Stats:"
echo "   Words: $WORD_COUNT"
echo "   Characters: $CHAR_COUNT"
echo "   H2 headings: $HEADING_COUNT"
echo "   H3 headings: $H3_COUNT"
echo ""

# Quality checks
ISSUES=0
WARNINGS=0

# Word count check
echo "✅ Checks:"
if [[ $WORD_COUNT -lt 1000 ]]; then
  echo "   ⚠️  Word count low ($WORD_COUNT < 1000)"
  ((WARNINGS++))
elif [[ $WORD_COUNT -lt 1500 ]]; then
  echo "   ⚠️  Word count acceptable but could be longer ($WORD_COUNT)"
  ((WARNINGS++))
else
  echo "   ✅ Word count good ($WORD_COUNT words)"
fi

# Heading check
if [[ $HEADING_COUNT -lt 3 ]]; then
  echo "   ⚠️  Few H2 headings ($HEADING_COUNT < 3)"
  ((WARNINGS++))
else
  echo "   ✅ Good heading structure ($HEADING_COUNT H2s)"
fi

# Keyword density check (should appear but not be stuffed)
KEYWORD_COUNT=$(echo "$ARTICLE_CONTENT" | grep -io "$TARGET_KEYWORD" | wc -l | tr -d ' ')
KEYWORD_DENSITY=$(echo "scale=2; ($KEYWORD_COUNT / $WORD_COUNT) * 100" | bc)

echo "   📍 Keyword usage: $KEYWORD_COUNT times (${KEYWORD_DENSITY}%)"
if (( $(echo "$KEYWORD_DENSITY < 0.5" | bc -l) )); then
  echo "   ⚠️  Target keyword rarely used"
  ((WARNINGS++))
elif (( $(echo "$KEYWORD_DENSITY > 3.0" | bc -l) )); then
  echo "   ❌ Keyword stuffing detected (${KEYWORD_DENSITY}% > 3%)"
  ((ISSUES++))
else
  echo "   ✅ Keyword density good (0.5% - 3%)"
fi

# Check for meta description in frontmatter
if grep -q "description:" "$ARTICLE_FILE" || grep -q "meta_description:" "$ARTICLE_FILE"; then
  echo "   ✅ Meta description found"
else
  echo "   ⚠️  No meta description"
  ((WARNINGS++))
fi

# Check for title
if grep -q "^# " "$ARTICLE_FILE"; then
  echo "   ✅ H1 title found"
else
  echo "   ❌ No H1 title"
  ((ISSUES++))
fi

echo ""
echo "📋 Summary:"
echo "   Issues: $ISSUES"
echo "   Warnings: $WARNINGS"
echo ""

if [[ $ISSUES -gt 0 ]]; then
  echo "❌ Quality check FAILED - $ISSUES critical issues"
  exit 1
elif [[ $WARNINGS -gt 2 ]]; then
  echo "⚠️  Quality check PASSED with warnings"
  exit 0
else
  echo "✅ Quality check PASSED"
  exit 0
fi
