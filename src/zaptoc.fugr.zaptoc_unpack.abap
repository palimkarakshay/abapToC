function zaptoc_unpack.
*"----------------------------------------------------------------------
*"*"Lokalny interfejs:
*"  IMPORTING
*"     VALUE(TOC) TYPE  TRKORR
*"     VALUE(TARGET_SYSTEM) TYPE  TR_TARGET
*"  EXPORTING
*"     VALUE(ERROR) TYPE  STRING
*"     VALUE(RET_CODE) TYPE  TRRETCODE
*"----------------------------------------------------------------------
  try.
      "Import
      data system type tmssysnam.
      data client type mandt.
      split target_system at '.' into system client.
      if client is initial.
        client = sy-mandt.
      endif.

      "Refresh Import queue
      data exception type stmscalert.
      call function 'TMS_MGR_REFRESH_IMPORT_QUEUES'
        exporting
          iv_system    = system
          iv_monitor   = abap_true
          iv_verbose   = abap_true
        importing
          es_exception = exception
        exceptions
          others       = 99.

      call function 'TMS_MGR_IMPORT_TR_REQUEST'
        exporting
          iv_system                  = system
          iv_request                 = toc
          iv_client                  = client
        importing
          ev_tp_ret_code             = ret_code
        exceptions
          read_config_failed         = 1
          table_of_requests_is_empty = 2
          others                     = 3.

    catch cx_root into data(cx).
      error = cx->get_longtext( ).
  endtry.

endfunction.
