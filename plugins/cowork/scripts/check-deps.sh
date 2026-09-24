#!/usr/bin/env bash
# Reports which Cowork verification dependencies are missing. Never exits non-zero
# for a missing optional tool; this is a report, not a gate.
miss=0
chk() { if command -v "$1" >/dev/null 2>&1; then echo "  ok    $1"; else echo "  MISS  $1  -- $2"; miss=1; fi; }
pychk() { if python3 -c "import $1" 2>/dev/null; then echo "  ok    python:$1"; else echo "  MISS  python:$1  -- pip install $2"; miss=1; fi; }

echo "Cowork dependency check"
echo
echo "Document rendering (needed to verify docx/pptx/pdf):"
chk soffice   "install libreoffice"
chk pdftoppm  "install poppler-utils"
chk pdftotext "install poppler-utils"
chk pandoc    "install pandoc"
echo
echo "PDF handling:"
pychk pypdf pypdf
pychk pdfplumber pdfplumber
pychk pypdfium2 pypdfium2
echo
echo "Document generation:"
if NODE_PATH=$(npm root -g 2>/dev/null) node -e "require('docx')" 2>/dev/null; then
  echo "  ok    npm:docx"
else
  echo "  MISS  npm:docx  -- npm install -g docx && export NODE_PATH=\$(npm root -g)"
  miss=1
fi
echo
[ "$miss" -eq 0 ] && echo "All good." || echo "Some deps missing. Claude can still write files, but cannot verify them."
