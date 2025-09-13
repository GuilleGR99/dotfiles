#!/usr/bin/env bash

# exit script if fails
set -euo pipefail

PROJECT="$1"

if [ -z "$PROJECT" ]; then 
    echo "Usage: $0 <project_name>"
    exit 1
fi

#### PROJECT CREATION ####

# Create base project with uv
uv init "$PROJECT"
cd "$PROJECT"

# Create src/ layout
PACKAGE=$(echo "$PROJECT" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]' '_')
mkdir -p src/"$PACKAGE"
mv main.py src/"$PACKAGE"/__init__.py

# Update pyproject.toml to use src/ layout
if ! grep -q "\[tool.uv.sources."$PACKAGE"\]" pyproject.toml; then
cat >> pyproject.toml <<EOF

[tool.uv.sources."$PACKAGE"]
path = "src"
EOF
fi

### GIT ###

cat > .gitignore <<EOF
__pycache__/
.venv/
.uv/
site/
*.pyc
.DS_Store
EOF

# # initialize a repo and commit once
# git init
# git add .
# git commit -m "Initial commit"

#### TEST ####

uv add --dev pytest

# Create tests/ folder
mkdir -p tests
touch tests/__init__.py
cat > tests/test_example.py <<EOF
def test_dummy():
    assert 1 + 1 == 2
EOF

#### DOCUMENTATION ####

# Add dev dependencies mkdocs for documentation
uv add --dev mkdocs

# Add dev dependencies for mkdocs plugins
uv add --dev mkdocs-material \
mkdocstrings\[python\] \
ghp-import \
mkdocs-autorefs \
mkdocs-gen-files \
mkdocs-literate-nav \
mkdocs-section-index \
# mkdocs-git-revision-date-localized-plugin

# Create docs/ and mkdocs.yml into /<PROJECT>/<PROJECT>
uv run mkdocs new "$PACKAGE"

# Move docs/ and mkdocs.yml from /<PROJECT>/<PROJECT> into /<PROJECT>
mv "$PACKAGE"/* .

# /<PROJECT>/<PROJECT> is not needed now
rm -r "$PACKAGE"

# Create gen_api.py inside docs to be used by gen-files mkdocs plugin
cat >>docs/gen_api.py <<EOF
# docs/gen_api.py
from mkdocs_gen_files import open as gen_open

with gen_open("api.md", "w") as f:
    f.write("# API Reference\n\n")
    f.write("::: ${PACKAGE}\n")
EOF

# Modify mkdocs.yml
cat >> mkdocs.yml <<EOF

site_name: "$PROJECT"
repo_url: https://GuilleGR99.github.io/$PACKAGE/
repo_name: GuilleGR99/$PACKAGE

theme:
  name: material
  features:
    - navigation.expand
    - navigation.sections
    - navigation.instant
    - search.suggest
    - search.highlight
    - content.code.copy
  palette:
    scheme: default
    primary: indigo
    accent: deep purple

plugins:
  - search
  - mkdocstrings:
      handlers:
        python:
          paths: ["src"]   # important: points to your code
          options:
            docstring_style: google     # or numpy / sphinx
            show_source: true
            extra:
              recurse: true # Automatically document submodules
  - autorefs                       # automatic cross-references
  - gen-files:                     # generate files dynamically
      scripts:
        - docs/gen_api.py
  - literate-nav:                  # define navigation in docs/ itself
  - section-index:                 # make folder index.md the landing page
  # - git-revision-date-localized:   # show last updated date
  #     fallback_to_build_date: true
  # - macros                         # use variables/macros inside markdown

markdown_extensions:
  - admonition
  - footnotes
  - def_list
  - pymdownx.details
  - pymdownx.superfences
  - pymdownx.highlight
  - pymdownx.inlinehilite
  - pymdownx.snippets
  - pymdownx.tabbed:
      alternate_style: true
  - pymdownx.tasklist:
      custom_checkbox: true

watch:
  - src

EOF

#### QUALITY ####

# Add dev dependencies ruff for code quality
uv add --dev ruff

# Add ruff plugins
cat >> pyproject.toml <<EOF
[tool.ruff]
line-length = 88         # como Black
# target-version = "py311" # versión de Python

[tool.ruff.lint]
extend-select = [
  "I",    # Ordenar imports (isort)
  "UP",   # Modernizar sintaxis (pyupgrade)
  "B",    # Detectar bugs comunes (bugbear)
  "N",    # Convenciones de nombres (pep8-naming)
#  "S",    # Chequeos de seguridad básicos (bandit)
#  "C4",   # Buenas prácticas en comprensiones
#  "T20",  # Evitar prints en producción
]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "lf"
EOF


echo "Project '$PROJECT' is ready."