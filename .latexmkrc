# 1) Put this at the top so everything goes into ./output/
$out_dir = 'output';

# 2) PDF + SyncTeX
$pdf_mode      = 1;
@generated_exts = (@generated_exts, 'synctex.gz');

# 3) Your pdflatex command
$pdflatex = 'pdflatex -synctex=1 -interaction=nonstopmode -shell-escape %O %S';

# 4) TELL latexmk how to build glossaries:
#    - run makeglossaries after the first TeX pass
add_cus_dep('glo', 'gls', 0, 'makeglossaries');
add_cus_dep('acn', 'acr', 0, 'makeglossaries');
#  (the “0” means run immediately when the .glo/.acn appears)
$makeglossaries = 'makeglossaries -d ' . $out_dir . ' %S';

# 5) Optional: don’t stop on warnings
$bibtex_use = 2;
