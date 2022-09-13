let g:sqls_loaded = 1

command! -range SqlsExecuteQuery call sqls#_execute_query(<range> != 0)
command! -range SqlsExecuteQueryVertical call sqls#_execute_query_vertical(<range> != 0)
command! SqlsShowDatabases call sqls#show_databases()
command! SqlsShowSchemas call sqls#show_schemas()
command! SqlsShowConnections call sqls#show_connections()
command! SqlsShowTables call sqls#show_tables()
command! SqlsDescribeTable call sqls#describe_table()
command! -nargs=? SqlsSwitchDatabase call sqls#switch_database(<f-args>)
command! -nargs=? -complete=customlist,sqls#complete_connections SqlsSwitchConnection call sqls#switch_connection(<f-args>)

nnoremap <plug>(sqls-execute-query) :<C-U>call sqls#execute_query('n')<CR>
vnoremap <plug>(sqls-execute-query) :<C-U>call sqls#execute_query('v')<CR>
nnoremap <plug>(sqls-execute-query-vertical) :<C-U>call sqls#execute_query_vertical('n')<CR>
vnoremap <plug>(sqls-execute-query-vertical) :<C-U>call sqls#execute_query_vertical('v')<CR>
nnoremap <plug>(sqls-show-databases) :<C-U>call sqls#show_databases()<CR>
nnoremap <plug>(sqls-show-schemas) :<C-U>call sqls#show_schemas()<CR>
nnoremap <plug>(sqls-show-connections) :<C-U>call sqls#show_connections()<CR>
nnoremap <plug>(sqls-show-tables) :<C-U>call sqls#show_tables()<CR>
nnoremap <plug>(sqls-describe-table) :<C-U>call sqls#describe_table()<CR>
nnoremap <plug>(sqls-switch-database) :<C-U>call sqls#switch_database()<CR>
nnoremap <plug>(sqls-switch-connection) :<C-U>call sqls#switch_connection()<CR>
