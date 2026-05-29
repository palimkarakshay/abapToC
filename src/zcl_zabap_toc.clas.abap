class zcl_zabap_toc definition
  public
  final
  create public.

  public section.
    methods:
      create importing source_transport type trkorr target_system type tr_target
                returning value(toc) type trkorr raising zcx_zabap_exception,
      release importing toc type trkorr raising zcx_zabap_exception,
      import importing toc type trkorr target_system type tr_target
                returning value(ret_code) type trretcode raising zcx_zabap_exception,
      import_objects importing source_transport type trkorr destination_transport type trkorr
                raising zcx_zabap_exception,
      check_status_in_system importing toc type trkorr system type tr_target
                exporting imported type abap_bool rc type i raising zcx_zabap_exception.

  private section.
    data c_transport_type_toc type trfunction value 'T'.

    methods get_toc_description importing source_transport type trkorr returning value(description) type string.
endclass.


class zcl_zabap_toc implementation.
  method check_status_in_system.
    data:
      settings type ctslg_settings,
      cofiles  type ctslg_cofile.

    append system to settings-systems.

    call function 'TR_READ_GLOBAL_INFO_OF_REQUEST'
      exporting
        iv_trkorr   = toc
        is_settings = settings
      importing
        es_cofile   = cofiles.

    if cofiles-exists = abap_false.
      raise exception type zcx_zabap_exception exporting message = conv #( text-e05 ).
    endif.

    imported = cofiles-imported.
    rc = cofiles-rc.
  endmethod.

  method create.
    try.
        cl_adt_cts_management=>create_empty_request(
          exporting iv_type = 'T' iv_text = conv #( get_toc_description( source_transport ) )
                    iv_target = target_system importing es_request_header = data(transport_header) ).
        import_objects( source_transport = source_transport destination_transport = transport_header-trkorr ).
        toc = transport_header-trkorr.

      catch cx_root into data(cx).
        raise exception type zcx_zabap_exception
          exporting message = replace( val = text-e01 sub = '&1' with = cx->get_text( ) ).
    endtry.
  endmethod.

  method import.
    data error type string.

    call function 'ZABAP_TOC_UNPACK' destination target_system
      exporting
        toc           = toc
        target_system = target_system
      importing
        ret_code      = ret_code
        error         = error.

    if strlen( error ) > 0.
      raise exception type zcx_zabap_exception
        exporting
          message = replace( val = text-e03 sub = '&1' with = error ).
    endif.
  endmethod.

  method import_objects.
    data request_headers type trwbo_request_headers.
    data requests        type trwbo_requests.

    call function 'TR_READ_REQUEST_WITH_TASKS'
      exporting
        iv_trkorr          = source_transport
      importing
        et_request_headers = request_headers
        et_requests        = requests
      exceptions
        invalid_input      = 1
        others             = 2.
    if sy-subrc <> 0.
      raise exception type zcx_zabap_exception
        exporting
          message = replace( val = replace( val = text-e01 sub = '&1' with = |{ sy-subrc }| )
                             sub = '&2' with = 'TR_READ_REQUEST_WITH_TASKS' ).
    endif.

    loop at request_headers reference into data(request_header)
        where trkorr = source_transport or strkorr = source_transport.
      call function 'TR_COPY_COMM'
        exporting
          wi_dialog                = abap_false
          wi_trkorr_from           = request_header->trkorr
          wi_trkorr_to             = destination_transport
          wi_without_documentation = abap_false
        exceptions
          db_access_error          = 1                " Database access error
          trkorr_from_not_exist    = 2                " first correction does not exist
          trkorr_to_is_repair      = 3                " Target correction is repair
          trkorr_to_locked         = 4                " Command file TRKORR_TO blocked, (SM12)
          trkorr_to_not_exist      = 5                " second correction does not exist
          trkorr_to_released       = 6                " second correction already released
          user_not_owner           = 7                " User is not owner of first request
          no_authorization         = 8                " No authorization for this function
          wrong_client             = 9                " Different clients (source - target)
          wrong_category           = 10               " Different category (source - target)
          object_not_patchable     = 11
          others                   = 12.
      if sy-subrc <> 0.
        raise exception type zcx_zabap_exception
          exporting
            message = replace( val = replace( val = text-e01 sub = '&1' with = |{ sy-subrc }| )
                               sub = '&2' with = 'TR_COPY_COMM' ).
      endif.
    endloop.
  endmethod.

  method release.
    try.
        data(cts_api) = cl_cts_rest_api_factory=>create_instance( ).
        cts_api->release( iv_trkorr = toc iv_ignore_locks = abap_true ).

      catch cx_root into data(cx).
        raise exception type zcx_zabap_exception
          exporting message = replace( val = text-e02 sub = '&1' with = cx->get_text( ) ).
    endtry.
  endmethod.

  method get_toc_description.
    description = replace( val = text-t01 sub = '&1' with = source_transport ).
  endmethod.

endclass.
