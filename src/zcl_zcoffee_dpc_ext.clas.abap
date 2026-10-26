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
  methods ZI_MM_FORNECEDOR_CREATE_ENTITY
    redefinition .
  methods ZI_MM_FORNECEDOR_DELETE_ENTITY
    redefinition .
  methods ZI_MM_FORNECEDOR_UPDATE_ENTITY
    redefinition .
  methods ZI_MM_FORN_PRODU_CREATE_ENTITY
    redefinition .
  methods ZI_MM_FORN_PRODU_DELETE_ENTITY
    redefinition .
  methods ZI_MM_PRODUTO_CREATE_ENTITY
    redefinition .
  methods ZI_MM_PRODUTO_DELETE_ENTITY
    redefinition .
  methods ZI_MM_PRODUTO_UPDATE_ENTITY
    redefinition .
  methods ZI_MM_FORN_PRODU_UPDATE_ENTITY
    redefinition .
  PRIVATE SECTION.
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
        is_funcionario = CORRESPONDING #( er_entity MAPPING dt_nasc = nascimento )
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


METHOD zi_mm_produto_create_entity.

  DATA: ls_produto TYPE zst_produto,
        lo_produto TYPE REF TO zcl_mm_produto,
        lt_return  TYPE bapiret2_t.

  DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  "Lê os dados enviados pelo Fiori
  io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).

  "Instancia a regra de negócio
  lo_produto = NEW zcl_mm_produto( ).

  "Executa o caso de uso
  lo_produto->create_produto( is_entity_prod = er_entity ).

  "Recupera mensagens
  lt_return = lo_produto->get_messages( ).

  "Adiciona todas as mensagens ao Message Container
  LOOP AT lt_return INTO DATA(ls_return).

    lo_msg->add_message_text_only(
      iv_msg_type = ls_return-type
      iv_msg_text = ls_return-message ).

  ENDLOOP.

  "Se houver erro, devolve todas as mensagens
  READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.

  IF sy-subrc = 0.

    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.

  ENDIF.

  "Recupera o produto atualizado (com ID gerado)
  er_entity = lo_produto->map_prod_to_entity( ).


ENDMETHOD.


  METHOD zi_mm_produto_delete_entity.
    DATA lt_return  TYPE bapiret2_t.
    DATA lv_id TYPE zidprod.
    DATA(lo_produto) = NEW zcl_mm_produto( ).
    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).


    lv_id = it_key_tab[ name = 'Id' ]-value.

    lo_produto->delete_produto( lv_id ).
    lo_produto->get_messages(
      RECEIVING
        rt_msg = lt_return                  " Tabela de retorno
    ).

    LOOP AT lt_return INTO DATA(ls_return).
      lo_msg->add_message_text_only(
        iv_msg_type               = ls_return-type
        iv_msg_text               = ls_return-message
).
    ENDLOOP.

    READ TABLE lt_return TRANSPORTING NO FIELDS WITH KEY type = 'E'.

    IF sy-subrc = 0.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.



  ENDMETHOD.


  METHOD zi_mm_produto_update_entity.

    DATA lv_idprod TYPE zidprod.
    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    io_data_provider->read_entry_data(
      IMPORTING
        es_data = er_entity
    ).

    DATA(ls_key) = it_key_tab[ name = 'Id' ].  "Produto a ser alterado

    lv_idprod = ls_key-value. "Passando para variável do meso tipo de parâmetro de importação de lo_produto->update_produto( iv_prod )

    "Instância do objeto
    DATA(lo_produto) = NEW zcl_mm_produto( ).

    "Atualizar produto
    lo_produto->update_produto( is_entity_prod = er_entity
                                iv_idprod      = lv_idprod ).

    "Obter as menssagens de retorno
    DATA(lt_return) = lo_produto->get_messages( ).

    "Percorrer Tabela de retorno
    LOOP AT lt_return INTO DATA(ls_return).

      lo_msg->add_message_text_only(
        iv_msg_type               = ls_return-type
        iv_msg_text               = ls_return-message
      ).

      "Lançar exceção
      IF ls_return-type = 'E'.

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            message_container = lo_msg.

      ENDIF.

    ENDLOOP.

    "Mapear campos para retornar Payload ao fiori
    er_entity = lo_produto->map_prod_to_entity( ).

  ENDMETHOD.


  METHOD zi_mm_fornecedor_create_entity.

*>>> ABACO - LCM - 18/09/2026 - Início - Devolve mensagens e falha visível
* Antes o método chamava CREATE_FORNECEDOR e ignorava o resultado: qualquer
* erro de validação virava HTTP 201 com o payload original de volta, sem
* gravar nada. Agora segue o mesmo padrão de ZI_MM_PRODUTO_CREATE_ENTITY.
    DATA: lo_fornecedor TYPE REF TO zcl_mm_fornecedor,
          lt_return     TYPE bapiret2_t.

    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    "Lê os dados enviados pelo Fiori
    io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).

    "Instancia a regra de negócio
    lo_fornecedor = NEW zcl_mm_fornecedor( ).

    "Executa o caso de uso
    lo_fornecedor->create_fornecedor( is_entity_forn = er_entity ).

    "Recupera mensagens
    lt_return = lo_fornecedor->get_messages( ).

    "Adiciona todas as mensagens ao Message Container
    LOOP AT lt_return INTO DATA(ls_return).

      lo_msg->add_message_text_only(
        iv_msg_type = ls_return-type
        iv_msg_text = ls_return-message ).

    ENDLOOP.

    "Se houver erro, devolve todas as mensagens
    READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.

    IF sy-subrc = 0.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.

    ENDIF.

    "Recupera o fornecedor gravado (com ID gerado)
    er_entity = lo_fornecedor->map_forn_to_entity( ).
*>>> ABACO - LCM - 18/09/2026 - Fim

  ENDMETHOD.


  METHOD zi_mm_fornecedor_delete_entity.

*>>> ABACO - LCM - 18/09/2026 - Início - Devolve mensagens e falha visível
* Antes o método era um stub vazio (nenhuma chamada) e depois, no draft,
* chamava DELETE_FORNECEDOR mas ignorava o resultado: um ID inexistente
* devolvia HTTP 204 sem excluir nada e sem mensagem nenhuma. Agora segue o
* mesmo padrão de ZI_MM_PRODUTO_DELETE_ENTITY / ZI_MM_FORNECEDOR_CREATE_ENTITY.
    DATA: lv_id_forn    TYPE zde_forn_id,
          lo_fornecedor TYPE REF TO zcl_mm_fornecedor,
          lt_return     TYPE bapiret2_t.

    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    "A chave vem da URL
    DATA(ls_key_tab) = it_key_tab[ name = 'IdForn' ].
    lv_id_forn = ls_key_tab-value.

    "Instancia a regra de negócio
    lo_fornecedor = NEW zcl_mm_fornecedor( ).

    "Executa o caso de uso (exclusão lógica)
    lo_fornecedor->delete_fornecedor( lv_id_forn ).

    "Recupera mensagens
    lt_return = lo_fornecedor->get_messages( ).

    "Adiciona todas as mensagens ao Message Container
    LOOP AT lt_return INTO DATA(ls_return).

      lo_msg->add_message_text_only(
        iv_msg_type = ls_return-type
        iv_msg_text = ls_return-message ).

    ENDLOOP.

    "Se houver erro, devolve todas as mensagens
    READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.

    IF sy-subrc = 0.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.

    ENDIF.
*>>> ABACO - LCM - 18/09/2026 - Fim

  ENDMETHOD.


  METHOD zi_mm_fornecedor_update_entity.

*>>> ABACO - LCM - 18/09/2026 - Início - Implementação do update
* O método era um stub vazio: um PUT devolvia sucesso sem alterar nada.
    DATA: lv_idforn     TYPE zde_forn_id,
          lo_fornecedor TYPE REF TO zcl_mm_fornecedor,
          lt_return     TYPE bapiret2_t.

    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    "Lê os dados enviados pelo Fiori
    io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).

    "A chave vem da URL, não do corpo da requisição
    DATA(ls_key) = it_key_tab[ name = 'IdForn' ].
    lv_idforn = ls_key-value.

    "Instancia a regra de negócio
    lo_fornecedor = NEW zcl_mm_fornecedor( ).

    "Executa o caso de uso
    lo_fornecedor->update_fornecedor( is_entity_forn = er_entity
                                      iv_idforn      = lv_idforn ).

    "Recupera mensagens
    lt_return = lo_fornecedor->get_messages( ).

    "Adiciona todas as mensagens ao Message Container
    LOOP AT lt_return INTO DATA(ls_return).

      lo_msg->add_message_text_only(
        iv_msg_type = ls_return-type
        iv_msg_text = ls_return-message ).

    ENDLOOP.

    "Se houver erro, devolve todas as mensagens
    READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.

    IF sy-subrc = 0.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.

    ENDIF.

    "Recupera o fornecedor já atualizado
    er_entity = lo_fornecedor->map_forn_to_entity( ).
*>>> ABACO - LCM - 18/09/2026 - Fim

  ENDMETHOD.


  METHOD zi_mm_forn_produ_create_entity.

    DATA: lo_relacao TYPE REF TO zcl_mm_forn_produto,
          lt_return  TYPE bapiret2_t,
          ls_entity  TYPE zcl_mm_forn_produto=>ty_relacao_entity.

    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    "Lê os dados enviados pelo Fiori
    io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).

    ls_entity = CORRESPONDING #( er_entity ).

    "Instancia a regra de negócio
    lo_relacao = NEW zcl_mm_forn_produto( ).

    "Executa o caso de uso
    lo_relacao->create_relacao( is_entity_relacao = ls_entity ).

    "Recupera mensagens
    lt_return = lo_relacao->get_messages( ).

    "Adiciona todas as mensagens ao Message Container
    LOOP AT lt_return INTO DATA(ls_return).

      lo_msg->add_message_text_only(
        iv_msg_type = ls_return-type
        iv_msg_text = ls_return-message ).

    ENDLOOP.

    "Se houver erro, devolve todas as mensagens
    READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.

    IF sy-subrc = 0.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.

    ENDIF.

    "Recupera a relação gravada, já com nome do fornecedor e do produto
    er_entity = CORRESPONDING #( lo_relacao->map_relacao_to_entity( ) ).

  ENDMETHOD.


  METHOD zi_mm_forn_produ_delete_entity.

    DATA: lv_id_forn TYPE zde_forn_id,
          lv_id_prod TYPE zidprod,
          lo_relacao TYPE REF TO zcl_mm_forn_produto,
          lt_return  TYPE bapiret2_t.

    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    "A chave (fornecedor + produto) vem da URL
    DATA(ls_key_forn) = it_key_tab[ name = 'IdForn' ].
    lv_id_forn = ls_key_forn-value.

    DATA(ls_key_prod) = it_key_tab[ name = 'IdProd' ].
    lv_id_prod = ls_key_prod-value.

    "Instancia a regra de negócio
    lo_relacao = NEW zcl_mm_forn_produto( ).

    "Executa o caso de uso (exclusão lógica)
    lo_relacao->delete_relacao( iv_id_forn = lv_id_forn
                                iv_id_prod = lv_id_prod ).

    "Recupera mensagens
    lt_return = lo_relacao->get_messages( ).

    "Adiciona todas as mensagens ao Message Container
    LOOP AT lt_return INTO DATA(ls_return).

      lo_msg->add_message_text_only(
        iv_msg_type = ls_return-type
        iv_msg_text = ls_return-message ).

    ENDLOOP.

    "Se houver erro, devolve todas as mensagens
    READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.

    IF sy-subrc = 0.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.

    ENDIF.

  ENDMETHOD.


  METHOD zi_mm_forn_produ_update_entity.

    DATA: lv_id_forn TYPE zde_forn_id,
          lv_id_prod TYPE zidprod,
          lo_relacao TYPE REF TO zcl_mm_forn_produto,
          lt_return  TYPE bapiret2_t,
          ls_entity  TYPE zcl_mm_forn_produto=>ty_relacao_entity.

    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    "Lê os dados enviados pelo Fiori
    io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).

    "A chave (fornecedor + produto) vem da URL, não do corpo da requisição
    DATA(ls_key_forn) = it_key_tab[ name = 'IdForn' ].
    lv_id_forn = ls_key_forn-value.

    DATA(ls_key_prod) = it_key_tab[ name = 'IdProd' ].
    lv_id_prod = ls_key_prod-value.

    ls_entity = CORRESPONDING #( er_entity ).

    "Instancia a regra de negócio
    lo_relacao = NEW zcl_mm_forn_produto( ).

    "Executa o caso de uso
    lo_relacao->update_relacao( is_entity_relacao = ls_entity
                                iv_id_forn        = lv_id_forn
                                iv_id_prod        = lv_id_prod ).

    "Recupera mensagens
    lt_return = lo_relacao->get_messages( ).

    "Adiciona todas as mensagens ao Message Container
    LOOP AT lt_return INTO DATA(ls_return).

      lo_msg->add_message_text_only(
        iv_msg_type = ls_return-type
        iv_msg_text = ls_return-message ).

    ENDLOOP.

    "Se houver erro, devolve todas as mensagens
    READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.

    IF sy-subrc = 0.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.

    ENDIF.

    "Recupera a relação já atualizada
    er_entity = CORRESPONDING #( lo_relacao->map_relacao_to_entity( ) ).

  ENDMETHOD.
ENDCLASS.
