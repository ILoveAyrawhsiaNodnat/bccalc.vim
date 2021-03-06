"" calculate expression entered on command line and give answer, e.g.:
" :Calculate sin (3) + sin (4) ^ 2
command! -nargs=+ Calculate echo "<args> = " . Calculate ("<args>")

"" calculate expression from visual selection and put result into unnamed reg
vnoremap <leader>bc "ey:call CalcLines()<cr>

"" calculate expression in the current line
noremap  <leader>bc "eyy:call CalcLines()<cr>

" ---------------------------------------------------------------------
"  Calculate:
"    clean up an expression, pass it to bc, return answer
function! s:Calculate (s)

	let l:str= a:s

	" remove newlines and trailing spaces
	" Shouldn't be any newlines here anyway since
	" they should have been removed by CalcLines, but this is useful for testing
	let l:str= substitute (l:str, "\n",   ";", "g")
	let l:str= substitute (l:str, '\s*$', "", "g")

	" sub common func names for bc equivalent
	let l:str = substitute (l:str, '\csin\s*(',  's (', 'g')
	let l:str = substitute (l:str, '\ccos\s*(',  'c (', 'g')
	let l:str = substitute (l:str, '\catan\s*(', 'a (', 'g')
	let l:str = substitute (l:str, "\cln\s*(",   'l (', 'g')
	let l:str = substitute (l:str, '\clog\s*(',  'l (', 'g')
	let l:str = substitute (l:str, '\cexp\s*(',  'e (', 'g')


	" alternate exponentiation symbols
	let l:str = substitute (l:str, '\*\*', '^', "g")

	" Substitute superscript characters like ² to become ^(²)
	    "First put them in parenthesis
	    let l:str = substitute(l:str, "[⁰¹²³⁴⁵⁶⁷⁸⁹]\\+", "^(&)", "g")
	
	    "This changes all numbers like ² to 2
	    "First, it changes the string to a list of characters
	    "Next it maps 2 to ², and so on for all the numbers
	    "Finally it joins all of the returned characters
	    let l:str = join(map(split(l:str, '\zs'), 's:FromSuperToNormal(v:val)'), "")

	" escape chars for shell
	let l:str = escape (l:str, '*();&><|')

	let l:preload = exists ("g:bccalc_preload") ? g:bccalc_preload : ""

	" run bc
	let l:answer = system ("echo " . l:str . " \| bc -l " . l:preload)

	" change newlines to separators
	let l:answer = substitute (l:answer, "\n", ", ", "g")

	" change the last sep to the empty string
	let l:answer = substitute (l:answer, ", $", "", "")

	" strip trailing 0s in decimals
	let l:answer = substitute (l:answer, '\.\(\d*[1-9]\)0\+', '.\1', "g")

	return l:answer
endfunction

function! s:FromSuperToNormal(char)  "{{{
    "Have to use a list rather than a string because you're 
    "not using ascii characters
    let l:super = split("⁰¹²³⁴⁵⁶⁷⁸⁹", '\zs')    
    let l:location = index(l:super, a:char)  

    if l:location ==# -1
	return a:char
    else
	return l:location
	"You can just return location here because the 0th index is ⁰, the
	"1st is ¹, and so on
    endif
endfunction "}}}

" ---------------------------------------------------------------------
" CalcLines:
"
" take expression from lines, either visually selected or the current line, as
" passed determined by arg vsl
function! CalcLines()

	" replace newlines with semicolons and remove trailing spaces
	let @e = substitute (@e, "\n", ";", "g")
	let @e = substitute (@e, '\s*$', "", "g")

	let l:answer = s:Calculate (@e)

	" echo answer and put into unnamed register
	echo "answer = " . l:answer
	call setreg('"', l:answer)
endfunction

