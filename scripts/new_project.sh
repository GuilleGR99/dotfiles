#!/usr/bin/env bash

# exit script if fails
set -euo pipefail

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
uv add --dev mkdocs

# 5. Add dev dependencies for mkdocs plugins
uv add --dev mkdocs-material \
mkdocstrings\[python\] \
mkdocs-autorefs \
mkdocs-gen-files \
mkdocs-literate-nav \
mkdocs-section-index \
mkdocs-git-revision-date-localized-plugin \
mkdocs-macros-plugin

# 6. Create docs/ and mkdocs.yml into /<PROJECT>/<PROJECT>
uv run mkdocs new "$PROJECT"

# 7. Move docs/ and mkdocs.yml from /<PROJECT>/<PROJECT> into /<PROJECT>
mv "$PROJECT"/* .

# 8. /<PROJECT>/<PROJECT> is not needed now
rm -r "$PROJECT"

# Create gen_api.py inside docs to be used by gen-files mkdocs plugin
cat >>docs/gen_api.py <<EOF
# docs/gen_api.py
from mkdocs_gen_files import open as gen_open

with gen_open("api.md", "w") as f:
    f.write("# API Reference\n\n")
    f.write("::: $PROJECT.main\n")
EOF

# 9. Modify mkdocs.yml
cat >> mkdocs.yml <<EOF

site_name: "$PROJECT"
repo_url: https://github.com/GuilleGR99/$PROJECT
repo_name: GuilleGR99/$PROJECT

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
      fallback_to_build_date: true
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

# 10. Update pyproject.toml to use src/ layout
if ! grep -q "\[tool.uv.sources."$PROJECT"\]" pyproject.toml; then
cat >> pyproject.toml <<EOF

[tool.uv.sources."$PROJECT"]
path = "src"
EOF
fi

# # initialize a repo and commit once
# git init
# git add .
# git commit -m "Initial commit"


echo "Project '$PROJECT' is ready."