class ZCL_ZCOFFEE_DPC_EXT definition
  public
  inheriting from ZCL_ZCOFFEE_DPC
  create public .

public section.
protected section.

  methods ZIRH_ZCOFFEE_CREATE_ENTITY
    redefinition .
  methods ZIRH_ZCOFFEE_DELETE_ENTITY
    redefinition .
  methods ZIRH_ZCOFFEE_UPDATE_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZCOFFEE_DPC_EXT IMPLEMENTATION.


METHOD zirh_zcoffee_create_entity.

  DATA(lo_msg) =
    me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  DATA(lo_rh_service) = NEW zcl_zcoffee_rh( ).

* Ler payload
  io_data_provider->read_entry_data(
    IMPORTING
      es_data = er_entity
  ).

* Criar funcionário
  lo_rh_service->criar_funcionario(
    EXPORTING
      is_funcionario = CORRESPONDING #( er_entity )
    IMPORTING
      ev_sucesso     = DATA(ld_sucesso)
      ev_menssagem   = DATA(ld_menssagem)
      es_funcionario = DATA(ls_func_criado)
  ).

* Tratamento de erro
  IF ld_sucesso = abap_false.

    lo_msg->add_message_text_only(
      iv_msg_type = 'E'
      iv_msg_text = ld_menssagem
    ).

    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.

  ENDIF.

* Retornar entidade criada
  MOVE-CORRESPONDING ls_func_criado TO er_entity.

  er_entity-id           = ls_func_criado-id_func.
  er_entity-nascimento   = ls_func_criado-dt_nasc.
  er_entity-admissao     = ls_func_criado-data_adm.
  er_entity-login        = ls_func_criado-login_user.

ENDMETHOD.


  METHOD zirh_zcoffee_delete_entity.
    DATA ld_func TYPE ztb_funcionario-id_func.

    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    DATA(ls_key) = it_key_tab[ name = 'ID' ].

    IF ls_key IS INITIAL.

      lo_msg->add_message_text_only(
        iv_msg_type               = 'E'                    " Message Type - defined by GCS_MESSAGE_TYPE
        iv_msg_text               = 'ID não informado'     " Message Text
      ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

    ld_func = ls_key-value.

    DATA(lo_rh) = NEW zcl_zcoffee_rh( ).

    lo_rh->inativar_funcionario(
      EXPORTING
        iv_funcionario = ld_func                    " Tipo Igualado
      IMPORTING
        ev_msg         = DATA(ld_msg)                " Message Text
        ev_sucesso     = DATA(ld_sucesso)            " Flag de sucesso
    ).

    IF ld_sucesso = abap_false.
      lo_msg->add_message_text_only(
        iv_msg_type               = 'E'                    " Message Type - defined by GCS_MESSAGE_TYPE
        iv_msg_text               = ld_msg                 " Message Text
      ).
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.


  ENDMETHOD.


METHOD zirh_zcoffee_update_entity.

  DATA(lo_msg) =
    me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  DATA ls_func TYPE ztb_funcionario.

* Ler payload
  io_data_provider->read_entry_data(
    IMPORTING
      es_data = er_entity
  ).

* Ler chave da URI
  READ TABLE it_key_tab INTO DATA(ls_id)
    WITH KEY name = 'ID'.

  IF sy-subrc = 0.
    er_entity-id = ls_id-value.
  ENDIF.

* Converter entidade
  MOVE-CORRESPONDING er_entity TO ls_func.

  ls_func-id_func = er_entity-id.
  ls_func-dt_nasc = er_entity-nascimento.

* Atualizar funcionário
  DATA(lo_rh) = NEW zcl_zcoffee_rh( ).

  lo_rh->atualizar_funcionario(
    EXPORTING
      is_funcionario = ls_func
    IMPORTING
      ev_sucesso     = DATA(ld_sucesso)
      ev_msg         = DATA(ld_msg)
      es_funcionario = DATA(ls_new)
  ).

* Tratamento de erro
  IF ld_sucesso = abap_false.

    lo_msg->add_message_text_only(
      iv_msg_type = 'E'
      iv_msg_text = ld_msg
    ).

    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.

  ENDIF.

* Retornar entidade atualizada
  MOVE-CORRESPONDING ls_new TO er_entity.

  er_entity-id          = ls_new-id_func.
  er_entity-nascimento  = ls_new-dt_nasc.
  er_entity-admissao    = ls_new-data_adm.
  er_entity-login       = ls_new-login_user.

ENDMETHOD.
ENDCLASS.
