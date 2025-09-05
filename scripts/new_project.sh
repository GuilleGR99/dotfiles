#!/usr/bin/env bash
set -e

PROJECT="$1"

if [ -z "$PROJECT" ]; then 
    echo "Usage: $0 <project_name>"
    exit 1
fi

# 1. Create base project with uv
uv init "$PROJECT"
cd "$PROJECT"

# 2. Create src/ layout
mkdir -p src/"$PROJECT"
mv main.py src/"$PROJECT"/__init__.py

# 3. Create tests/ folder
mkdir -p tests
touch tests/__init__.py
cat > tests/test_example.py <<EOF
def test_dummy():
    assert 1 + 1 == 2
EOF

# 4. Add dev dependencies for docs
uv add --dev sphinx myst-parser

# 5. Create docs/ with Sphinx
mkdir docs
cd docs
uv run sphinx-quickstart -q -p "$PROJECT" -a "Guillermo" -v "0.1.0" --sep --ext-autodoc --ext-viewcode
cd ..

# 6. Update pyproject.toml to use src/ layout
if ! grep -q "\[tool.uv.sources."$PROJECT"\]" pyproject.toml; then
cat >> pyproject.toml <<EOF

[tool.uv.sources."$PROJECT"]
path = "src"
EOF
fi

echo "Project '$PROJECT' is ready."