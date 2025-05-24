$pdf_previewer = 'open -a zathura';
$makeglossaries = 'makeglossaries -d output %S';
$pdflatex = 'pdflatex %O -synctex=1 -interaction=nonstopmode -shell-escape %S';
$latex   = 'latex   %O -interaction=nonstopmode -shell-escape %S';
$pdf_mode = 1;
@generated_exts = (@generated_exts, 'synctex.gz');

$latex = 'latex -interaction=nonstopmode -shell-escape';

$out_dir = 'output';

