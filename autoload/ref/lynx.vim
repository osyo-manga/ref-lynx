let s:save_cpo = &cpo
set cpo&vim


if !exists('g:ref_lynx_start_linenumber')
  let g:ref_lynx_start_linenumber = 0
endif

if !exists('g:ref_lynx_cmd')
  let g:ref_lynx_cmd = 'lynx -dump -nonumbers %s'
endif

if !exists('g:ref_lynx_encoding')
	let g:ref_lynx_encoding = 'char'
endif

if !exists('g:ref_lynx_use_cache')
	let g:ref_lynx_use_cache = 0
endif

if !exists('g:ref_lynx_hide_url_number')
	let g:ref_lynx_hide_url_number = 1
endif


let s:source = {'name': 'lynx'}

function! ref#lynx#define()
  return s:source
endfunction


function! s:source.available()
  return !empty(g:ref_lynx_cmd)
endfunction

function! s:source.get_body(query)
	if type(g:ref_lynx_cmd) == type('')
		let cmd = split(g:ref_lynx_cmd, '\s\+')
	elseif type(g:ref_lynx_cmd) == type([])
		let cmd = copy(g:ref_lynx_cmd)
	else
		return ''
	endif
	
	let url = a:query
	call map(cmd, 'substitute(v:val, "%s", url, "g")')
	if len(cmd) > 0 && cmd[0] =~ '^:'
		return eval(join(cmd, ' ')[1:])
	elseif g:ref_lynx_use_cache
		let expr = 'ref#system(' . string(cmd) . ').stdout'
		let res = join(ref#cache('lynx', a:query, expr), "\n")
	else
		let res = ref#system(cmd).stdout
	endif
	return s:iconv(res, g:ref_lynx_encoding, &encoding)
endfunction

function! s:source.opened(query)
	execute "normal! ".g:ref_lynx_start_linenumber."z\<CR>"
	call s:syntax(a:query)
endfunction

function! s:source.normalize(query)
	return substitute(substitute(a:query, '\_s\+', ' ', 'g'), '^ \| $', '', 'g')
endfunction

function! s:get_url()
	let num = matchstr(expand('<cWORD>'), '[\zs\d*\ze')
	if !num
		return ""
	endif
	let line = search(num.'. http', 'n')
	let url = matchstr(getline(line), '\s\+'.num.'. \zs.*\ze')
	return url
endfunction

function! s:open_url_cmd()
	let url = s:get_url()
	return url != "" ? "Ref lynx ".url : ""
endfunction

function! s:syntax(query)
	syntax clear
	syntax match refLynxURL "\[\d*\]\w*" contains=refLynxURLNo
	syntax match refLynxURLNo "\[\d*\]" contained conceal

	highlight refLynxURL term=bold cterm=bold gui=bold

	if g:ref_lynx_hide_url_number
		setlocal conceallevel=2
	endif
	setlocal concealcursor=n

	nnoremap <silent><buffer> <CR> :execute " ".<SID>open_url_cmd()<CR>
	
	augroup ref-lynx
		autocmd CursorMoved <buffer> echo <SID>get_url()
	augroup END
endfunction

" iconv() wrapper for safety.
function! s:iconv(expr, from, to)
  if a:from == '' || a:to == '' || a:from ==# a:to
    return a:expr
  endif
  let result = iconv(a:expr, a:from, a:to)
  return result != '' ? result : a:expr
endfunction

let s:save_cpo = &cpo
set cpo&vim
