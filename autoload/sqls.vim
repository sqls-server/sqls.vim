let s:commands = {}
let s:sqls_fzf_opt = []

function! sqls#execute_query() abort
    call sqls#lsp_execute_command({
    \   'server_name': 'sqls',
    \   'command_name': 'executeQuery',
    \   'command_args': [get(lsp#get_text_document_identifier(), 'uri', v:null)],
    \   'callback_func': 's:handle_preview',
    \   'sync': v:false,
    \   'bufnr': bufnr('%'),
    \ })
endfunction

function! sqls#show_databases() abort
    call sqls#lsp_execute_command({
    \   'server_name': 'sqls',
    \   'command_name': 'showDatabases',
    \   'command_args': v:null,
    \   'callback_func': 's:handle_preview',
    \   'sync': v:false,
    \   'bufnr': bufnr('%'),
    \ })
endfunction

function! sqls#show_connections() abort
    call sqls#lsp_execute_command({
    \   'server_name': 'sqls',
    \   'command_name': 'showConnections',
    \   'command_args': v:null,
    \   'callback_func': 's:handle_preview',
    \   'sync': v:false,
    \   'bufnr': bufnr('%'),
    \ })
endfunction

function! sqls#show_tables() abort
    echo 'no implements'
endfunction

function! sqls#describe_table() abort
    echo 'no implements'
endfunction

function! sqls#switch_database(...) abort
    if a:0 >= 1
        let l:db_name = a:1
        call sqls#lsp_execute_command({
        \   'server_name': 'sqls',
        \   'command_name': 'switchDatabase',
        \   'command_args': [l:db_name],
        \   'callback_func': 's:handle_no_preview',
        \   'sync': v:false,
        \   'bufnr': bufnr('%'),
        \ })
        return
    endif

    call sqls#lsp_execute_command({
    \   'server_name': 'sqls',
    \   'command_name': 'showDatabases',
    \   'command_args': v:null,
    \   'callback_func': 's:handle_fetch_database',
    \   'sync': v:false,
    \   'bufnr': bufnr('%'),
    \ })
endfunction

function! sqls#switch_connection(...) abort
    if a:0 >= 1
        let l:conn_index = a:1
        call sqls#lsp_execute_command({
        \   'server_name': 'sqls',
        \   'command_name': 'switchConnections',
        \   'command_args': [l:conn_index],
        \   'callback_func': 's:handle_no_preview',
        \   'sync': v:false,
        \   'bufnr': bufnr('%'),
        \ })
        return
    endif

    call sqls#lsp_execute_command({
    \   'server_name': 'sqls',
    \   'command_name': 'showConnections',
    \   'command_args': v:null,
    \   'callback_func': 's:handle_fetch_connection',
    \   'sync': v:false,
    \   'bufnr': bufnr('%'),
    \ })
endfunction

function! sqls#lsp_execute_command(params) abort
    let l:command_name = a:params['command_name']
    let l:command_args = get(a:params, 'command_args', v:null)
    let l:server_name = get(a:params, 'server_name', '')
    let l:callback_func = get(a:params, 'callback_func', 's:handle_no_preview')
    let l:bufnr = get(a:params, 'bufnr', -1)
    let l:sync = get(a:params, 'sync', v:false)

    " create command.
    let l:command = { 'command': l:command_name }
    if l:command_args isnot v:null
        let l:command['arguments'] = l:command_args
    endif

    " execute command on local.
    if has_key(s:commands, l:command_name)
        try
            call s:commands[l:command_name]({
            \   'bufnr': l:bufnr,
            \   'server_name': l:server_name,
            \   'command': l:command,
            \ })
        catch /.*/
            call lsp#utils#error(printf('Execute command failed: %s', string(a:params)))
        endtry
        return
    endif

    " execute command on server.
    if !empty(l:server_name)
        call lsp#send_request(l:server_name, {
        \   'method': 'workspace/executeCommand',
        \   'params': l:command,
        \   'sync': l:sync,
        \   'on_notification': function(l:callback_func, [l:server_name, l:command]),
        \ })
    endif
    echo 'Do ' . l:command_name
endfunction

function! sqls#fzf_sink_switch_database(line) abort
    let l:database = a:line
    call sqls#lsp_execute_command({
    \   'server_name': 'sqls',
    \   'command_name': 'switchDatabase',
    \   'command_args': [l:database],
    \   'callback_func': 's:handle_no_preview',
    \   'sync': v:false,
    \   'bufnr': bufnr('%'),
    \ })
endfunction

function! sqls#fzf_sink_switch_connections(line) abort
    let l:connection = a:line
    let l:sp = split(l:connection, ' ')
    call sqls#lsp_execute_command({
    \   'server_name': 'sqls',
    \   'command_name': 'switchConnections',
    \   'command_args': [l:sp[0]],
    \   'callback_func': 's:handle_no_preview',
    \   'sync': v:false,
    \   'bufnr': bufnr('%'),
    \ })
endfunction

function! s:handle_no_preview(server_name, command, data) abort
    if lsp#client#is_error(a:data['response'])
        call lsp#utils#error('Execute command failed on ' . a:server_name . ': ' . string(a:command) . ' -> ' . string(a:data))
        return
    endif

    echo get(a:command, 'command', '') . ' Done'
endfunction

function! s:handle_preview(server_name, command, data) abort
    if lsp#client#is_error(a:data['response'])
        call lsp#utils#error('Execute command failed on ' . a:server_name . ': ' . string(a:command) . ' -> ' . string(a:data))
        return
    endif

    call s:open_preview_buffer(a:data['response']['result'], 'LSP ExecuteCommand')
    echo get(a:command, 'command', '') . ' Done'
endfunction

function! s:escape_string_for_display(str) abort
    return substitute(substitute(a:str, '\r\n', '\n', 'g'), '\r', '\n', 'g')
endfunction

function! s:open_preview_buffer(data, buf_filetype) abort
    execute 'new'
    let l:preview_win_id = win_getid()

    " set preview content
    call setline(1, split(s:escape_string_for_display(a:data), '\n'))

    " setup preview window
    setlocal
    \ bufhidden=wipe nomodified nobuflisted noswapfile nonumber
    \ nocursorline wrap nonumber norelativenumber signcolumn=no nofoldenable
    \ nospell nolist nomodeline
    silent! let &l:filetype = a:buf_filetype

    " set the focus to the preview window
    call win_gotoid(l:preview_win_id)
endfunction

function! s:handle_fetch_database(server_name, command, data) abort
    if lsp#client#is_error(a:data['response'])
        call lsp#utils#error('Execute command failed on ' . a:server_name . ': ' . string(a:command) . ' -> ' . string(a:data))
        return
    endif

    " Select switch database
    let l:data = split(s:escape_string_for_display(a:data['response']['result']), '\n')
    let l:opts = s:prepare_sqls_fzf_opts(l:data, 'Databases', function('sqls#fzf_sink_switch_database'))
    let l:database = fzf#run(l:opts)
endfunction

function! s:handle_fetch_connection(server_name, command, data) abort
    if lsp#client#is_error(a:data['response'])
        call lsp#utils#error('Execute command failed on ' . a:server_name . ': ' . string(a:command) . ' -> ' . string(a:data))
        return
    endif

    " Select switch database
    let l:data = split(s:escape_string_for_display(a:data['response']['result']), '\n')
    let l:opts = s:prepare_sqls_fzf_opts(l:data, 'Connections', function('sqls#fzf_sink_switch_connections'))
    let l:database = fzf#run(l:opts)
endfunction

function! s:prepare_sqls_fzf_opts(source, prompt, sink) abort
    let opts = {
    \    'source': a:source,
    \    'sink': a:sink,
    \    'options': ['--prompt', a:prompt] + get(s:, 'sqls_fzf_opt', []),
    \ }
    return fzf#wrap(opts)
endfunction
