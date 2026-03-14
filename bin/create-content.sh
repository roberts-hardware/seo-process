#!/usr/bin/env bash
# AI-powered content creation from briefs and research
# Usage: ./bin/create-content.sh <client-id> <brief-file> <research-file>

set -euo pipefail

CLIENT_ID="${1:?Usage: create-content.sh <client-id> <brief-file> <research-file>}"
BRIEF_FILE="${2:?Usage: create-content.sh <client-id> <brief-file> <research-file>}"
RESEARCH_FILE="${3:?Usage: create-content.sh <client-id> <brief-file> <research-file>}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$REPO_ROOT/workspace/$CLIENT_ID"

# Check files exist
if [[ ! -f "$BRIEF_FILE" ]]; then
  echo "❌ Brief not found: $BRIEF_FILE"
  exit 1
fi

if [[ ! -f "$RESEARCH_FILE" ]]; then
  echo "❌ Research not found: $RESEARCH_FILE"
  exit 1
fi

# Check for Anthropic API key
if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "❌ ANTHROPIC_API_KEY not set in environment"
  echo "   Add to .env: ANTHROPIC_API_KEY=sk-ant-..."
  exit 1
fi

# Load brand voice if available
BRAND_VOICE=""
if [[ -f "$WORKSPACE/brand/voice-profile.md" ]]; then
  BRAND_VOICE=$(cat "$WORKSPACE/brand/voice-profile.md")
fi

# Load config
CONFIG="$WORKSPACE/seo/config.yaml"
BUSINESS_TYPE=$(grep "^business_type:" "$CONFIG" | cut -d'"' -f2 || echo "business")
SITE_URL=$(grep "^site_url:" "$CONFIG" | awk '{print $2}' | tr -d '"' || echo "")

# Read brief and research
BRIEF_CONTENT=$(cat "$BRIEF_FILE")
RESEARCH_CONTENT=$(cat "$RESEARCH_FILE")

BRIEF_NAME=$(basename "$BRIEF_FILE" .md)
ARTICLE_FILE="$WORKSPACE/content/articles/${BRIEF_NAME}.md"
mkdir -p "$WORKSPACE/content/articles"

echo "🤖 Creating AI-powered content..."
echo "   Client: $CLIENT_ID"
echo "   Brief: $(basename "$BRIEF_FILE")"
echo "   Output: $ARTICLE_FILE"
echo ""

# Build prompt for Claude
PROMPT=$(cat <<EOF
You are an expert SEO content writer. Create a comprehensive, high-quality article based on the brief and research data provided.

## Business Context
Type: $BUSINESS_TYPE
Website: $SITE_URL

## Brand Voice
$BRAND_VOICE

## Content Brief
$BRIEF_CONTENT

## Keyword Research Data
$RESEARCH_CONTENT

## Requirements
1. Write a complete, publish-ready article (1500-2500 words)
2. Follow SEO best practices:
   - Use target keyword naturally in title, H1, first paragraph, and throughout
   - Include H2 and H3 subheadings with semantic keywords
   - Answer "People Also Ask" questions from research
   - Include related keywords naturally
3. Match the brand voice (if provided)
4. Write for humans first, search engines second
5. Include actionable insights and expertise
6. Use short paragraphs (2-4 sentences)
7. Add a compelling introduction and conclusion
8. Include a call-to-action at the end

## Output Format
Markdown with:
- Title (H1)
- Meta description (in frontmatter comment at top)
- Structured headings (H2, H3)
- No keyword stuffing
- Natural, conversational tone
- Expert insights specific to $BUSINESS_TYPE

Generate the article now.
EOF
)

# Call Claude API
echo "📝 Generating content with Claude..."

RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d @- <<JSON
{
  "model": "claude-sonnet-4-20250514",
  "max_tokens": 8000,
  "temperature": 0.7,
  "messages": [
    {
      "role": "user",
      "content": $(echo "$PROMPT" | jq -Rs .)
    }
  ]
}
JSON
)

# Check for errors
if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
  ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message')
  echo "❌ Claude API error: $ERROR_MSG"
  exit 1
fi

# Extract content
ARTICLE_CONTENT=$(echo "$RESPONSE" | jq -r '.content[0].text')

if [[ -z "$ARTICLE_CONTENT" || "$ARTICLE_CONTENT" == "null" ]]; then
  echo "❌ No content generated"
  echo "Response: $RESPONSE"
  exit 1
fi

# Add metadata frontmatter
TIMESTAMP=$(date -u +"%Y-%m-%d")
cat > "$ARTICLE_FILE" <<EOF
---
generated: $TIMESTAMP
client: $CLIENT_ID
brief: $(basename "$BRIEF_FILE")
model: claude-sonnet-4
status: draft
---

$ARTICLE_CONTENT
EOF

echo "✅ Article created: $ARTICLE_FILE"
echo ""
echo "📊 Stats:"
WORD_COUNT=$(echo "$ARTICLE_CONTENT" | wc -w | tr -d ' ')
CHAR_COUNT=$(echo "$ARTICLE_CONTENT" | wc -c | tr -d ' ')
echo "   Words: $WORD_COUNT"
echo "   Characters: $CHAR_COUNT"
echo ""
