let s:commands = {}
let s:sqls_fzf_opt = []

function! sqls#_execute_query(selection) abort
    let l:mode = 'n'
    if a:selection
        let l:mode = 'v'
    endif
    call sqls#execute_query(l:mode)
endfunction

function! sqls#execute_query(mode) abort
    let l:args = {
    \   'server_name': 'sqls',
    \   'command_name': 'executeQuery',
    \   'command_args': [get(lsp#get_text_document_identifier(), 'uri', v:null)],
    \   'callback_func': 's:handle_preview',
    \   'sync': v:false,
    \   'bufnr': bufnr('%'),
    \ }
    if a:mode ==# 'v'
        let l:args['command_range'] = lsp#utils#range#_get_recent_visual_range()
    endif
    call sqls#lsp_execute_command(args)
endfunction

function! sqls#_execute_query_vertical(selection) abort
    let l:mode = 'n'
    if a:selection
        let l:mode = 'v'
    endif
    call sqls#execute_query_vertical(l:mode)
endfunction

function! sqls#execute_query_vertical(mode) abort
    let l:args = {
    \   'server_name': 'sqls',
    \   'command_name': 'executeQuery',
    \   'command_args': [get(lsp#get_text_document_identifier(), 'uri', v:null), '-show-vertical'],
    \   'callback_func': 's:handle_preview',
    \   'sync': v:false,
    \   'bufnr': bufnr('%'),
    \ }
    if a:mode ==# 'v'
        let l:args['command_range'] = lsp#utils#range#_get_recent_visual_range()
    endif
    call sqls#lsp_execute_command(args)
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

function! sqls#show_schemas() abort
    call sqls#lsp_execute_command({
    \   'server_name': 'sqls',
    \   'command_name': 'showSchemas',
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

function! s:handle_data(ctx, server_name, command, data) abort
    if has_key(a:data['response'], 'result')
        let a:ctx['response'] = a:data['response']
    endif
endfunction

function! sqls#complete_connections(A, L, P) abort
    let l:result = {'response': {'result': ''}}
    call sqls#lsp_execute_command({
    \   'server_name': 'sqls',
    \   'command_name': 'showConnections',
    \   'command_args': v:null,
    \   'callback_func': 's:handle_data',
    \   'callback_args': [l:result],
    \   'sync': v:true,
    \   'bufnr': bufnr('%'),
    \ })
    let l:connections = map(split(l:result['response']['result'], '\n'), {_, line -> split(line, '\s\+')[2]})
    return l:connections
endfunction

function! sqls#show_tables() abort
    call sqls#lsp_execute_command({
    \   'server_name': 'sqls',
    \   'command_name': 'showTables',
    \   'command_args': v:null,
    \   'callback_func': 's:handle_preview',
    \   'sync': v:false,
    \   'bufnr': bufnr('%'),
    \ })
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
    let l:command_range = get(a:params, 'command_range', v:null)
    let l:server_name = get(a:params, 'server_name', '')
    let l:callback_func = get(a:params, 'callback_func', 's:handle_no_preview')
    let l:callback_args = get(a:params, 'callback_args', [])
    let l:bufnr = get(a:params, 'bufnr', -1)
    let l:sync = get(a:params, 'sync', v:false)

    " create command.
    let l:command = { 'command': l:command_name }
    if l:command_args isnot v:null
        let l:command['arguments'] = l:command_args
    endif
    if l:command_range isnot v:null
        let l:command['range'] = l:command_range
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
        \   'on_notification': function(l:callback_func, l:callback_args + [l:server_name, l:command]),
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

function! s:select(data, prompt, callback) abort
    if exists(':FZF')
        let l:opts = s:prepare_sqls_fzf_opts(a:data, a:prompt, function(a:callback))
        call fzf#run(l:opts)
    else
        let l:selected = inputlist(a:data)
        if l:selected > 0
            call call(a:callback, [a:data[l:selected-1]])
        endif
    endif
endfunction

function! s:handle_fetch_database(server_name, command, data) abort
    if lsp#client#is_error(a:data['response'])
        call lsp#utils#error('Execute command failed on ' . a:server_name . ': ' . string(a:command) . ' -> ' . string(a:data))
        return
    endif

    " Select switch database
    let l:data = split(s:escape_string_for_display(a:data['response']['result']), '\n')
    call s:select(l:data, 'Schemas>', 'sqls#fzf_sink_switch_database')
endfunction

function! s:handle_fetch_connection(server_name, command, data) abort
    if lsp#client#is_error(a:data['response'])
        call lsp#utils#error('Execute command failed on ' . a:server_name . ': ' . string(a:command) . ' -> ' . string(a:data))
        return
    endif

    " Select switch database
    let l:data = split(s:escape_string_for_display(a:data['response']['result']), '\n')
    call s:select(l:data, 'Connections>', 'sqls#fzf_sink_switch_connections')
endfunction

function! s:prepare_sqls_fzf_opts(source, prompt, sink) abort
    let opts = {
    \    'source': a:source,
    \    'sink': a:sink,
    \    'options': ['--prompt', a:prompt] + get(s:, 'sqls_fzf_opt', []),
    \ }
    return fzf#wrap(opts)
endfunction

function! s:get_selection_pos(type) abort
    if a:type ==? 'v'
        let l:start_pos = getpos("'<")[1:2]
        let l:end_pos = getpos("'>")[1:2]
        " fix end_pos column (see :h getpos() and :h 'selection')
        let l:end_line = getline(l:end_pos[0])
        let l:offset = (&selection ==# 'inclusive' ? 1 : 2)
        let l:end_pos[1] = len(l:end_line[:l:end_pos[1]-l:offset])
        " edge case: single character selected with selection=exclusive
        if l:start_pos[0] == l:end_pos[0] && l:start_pos[1] > l:end_pos[1]
            let l:end_pos[1] = l:start_pos[1]
        endif
    elseif a:type ==? 'line'
        let l:start_pos = [line("'["), 1]
        let l:end_lnum = line("']")
        let l:end_pos = [line("']"), len(getline(l:end_lnum))]
    elseif a:type ==? 'char'
        let l:start_pos = getpos("'[")[1:2]
        let l:end_pos = getpos("']")[1:2]
    else
        let l:start_pos = [0, 0]
        let l:end_pos = [0, 0]
    endif

    return l:start_pos + l:end_pos
endfunction
