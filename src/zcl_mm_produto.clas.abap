class ZCL_MM_PRODUTO definition
  public
  final
  create public .

public section.

  methods CREATE_PRODUTO
    importing
      !IS_ENTITY_PROD type ZCL_ZCOFFEE_MPC=>TS_ZI_MM_PRODUTOTYPE .
  methods UPDATE_PRODUTO
    importing
      !IS_ENTITY_PROD type ZCL_ZCOFFEE_MPC=>TS_ZI_MM_PRODUTOTYPE
      !IV_IDPROD type ZIDPROD .
  methods DELETE_PRODUTO
    importing
      !IV_IDPROD type ZIDPROD .
  methods GET_MESSAGES
    returning
      value(RT_MSG) type BAPIRET2_T .
  methods MAP_PROD_TO_ENTITY
    returning
      value(RS_ENTITY_PROD) type ZCL_ZCOFFEE_MPC=>TS_ZI_MM_PRODUTOTYPE .
  PROTECTED SECTION.
private section.

  data MS_PRODUTO type ZST_PRODUTO .
  data MT_MSG type BAPIRET2_T .
  data MC_CREATE type CHAR1 value 'C' ##NO_TEXT.
  data MC_UPDATE type CHAR1 value 'U' ##NO_TEXT.

  methods INATIVAR_PRODUTO
    importing
      !IV_ID type ZIDPROD .
  methods VALIDAR_PRODUTO
    importing
      !IV_MODE type CHAR1 .
  methods ADD_MSG
    importing
      !IV_TYPE type BAPI_MTYPE
      !IV_MESSAGE type BAPI_MSG .
  methods HAS_ERROR
    returning
      value(RV_ERROR) type ABAP_BOOL .
  methods GERAR_ID
    returning
      value(RV_ID) type ZID_PROD .
  methods SALVAR .
  methods PREENCHER_CAMPOS .
  methods PREPARAR_PRODUTO .
  methods MAP_ENTITY_TO_PROD
    importing
      !IS_ENTITY type ZCL_ZCOFFEE_MPC=>TS_ZI_MM_PRODUTOTYPE .
  methods BUSCAR_PRODUTO
    importing
      !IV_IDPROD type ZIDPROD .
  methods MAP_CAMPOS_ATUALIZAVEIS
    importing
      !IS_ENTITY type ZCL_ZCOFFEE_MPC=>TS_ZI_MM_PRODUTOTYPE .
  methods ATUALIZAR .
ENDCLASS.



CLASS ZCL_MM_PRODUTO IMPLEMENTATION.


  METHOD add_msg.

    APPEND VALUE bapiret2(
     type    = iv_type
     message = iv_message ) TO mt_msg.

  ENDMETHOD.


  METHOD atualizar.

    DATA ls_produtos TYPE ztb_produtos.

    MOVE-CORRESPONDING me->ms_produto TO ls_produtos.

    UPDATE ztb_produtos FROM ls_produtos.

    IF sy-subrc <> 0.
      me->add_msg(
        iv_type    = 'E'
        iv_message = 'Erro ao atualizar o produto.'
      ).
      RETURN.
    ENDIF.

    me->add_msg(
      iv_type    = 'S'
      iv_message = |Produto { me->ms_produto-id_prod } atualizado com sucesso!|
    ).

  ENDMETHOD.


  METHOD buscar_produto.

    CLEAR me->ms_produto.

    SELECT SINGLE *
      FROM ztb_produtos
      INTO CORRESPONDING FIELDS OF @me->ms_produto
      WHERE id_prod = @iv_idprod.

    IF sy-subrc <> 0.

      me->add_msg(
        iv_type    = 'E'
        iv_message = |Produto { iv_idprod } não encontrado!| ).

    ENDIF.

  ENDMETHOD.


  METHOD create_produto.
    me->map_entity_to_prod( is_entity = is_entity_prod ).
    me->preparar_produto( ).
    me->validar_produto( iv_mode = 'C' ).         "Validação dos produtos
    me->preencher_campos( ).                      "Preenche campos

    IF me->has_error( ) = abap_true.              "Verifica se há erros
      RETURN.
    ENDIF.

    me->salvar( ).                                "Grava do DB

  ENDMETHOD.


  METHOD delete_produto.

    me->buscar_produto( iv_idprod = iv_idprod ).
    me->inativar_produto( iv_id = iv_idprod ).

  ENDMETHOD.


  METHOD gerar_id.

    DATA lv_number TYPE n LENGTH 6.

    CLEAR: me->ms_produto-id_prod, lv_number, rv_id.

    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr             = '01'
        object                  = 'ZNRO_IDPRO'
      IMPORTING
        number                  = lv_number
      EXCEPTIONS
        interval_not_found      = 1
        number_range_not_intern = 2
        object_not_found        = 3
        quantity_is_0           = 4
        quantity_is_not_1       = 5
        interval_overflow       = 6
        buffer_overflow         = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
      me->add_msg(
        iv_type    = 'E'
        iv_message = 'Erro crítico ao gerar ID.'
      ).
      RETURN.
    ENDIF.

    rv_id = lv_number.

  ENDMETHOD.


  METHOD get_messages.

    rt_msg = mt_msg.

  ENDMETHOD.


  METHOD has_error.

    READ TABLE me->mt_msg WITH KEY type = 'E'
      TRANSPORTING NO FIELDS.

    IF sy-subrc = 0.
      rv_error = 'X'.
    ENDIF.

  ENDMETHOD.


  METHOD inativar_produto.

    SELECT SINGLE status
      FROM ztb_produtos
      INTO @DATA(lv_status)
      WHERE id_prod = @iv_id.

    IF lv_status = 'I'.
      me->add_msg(
        iv_type    = 'E'                 " Ctg.mens.: S sucesso, E erro, W aviso, I inform., A cancel.
        iv_message = 'Produto ja inativo'                  " Texto de mensagem
      ).
      RETURN.
    ENDIF.

    UPDATE ztb_produtos SET status = 'I'
      WHERE id_prod = iv_id.

    IF sy-subrc <> 0.
      me->add_msg(
        iv_type    = 'E'                 " Ctg.mens.: S sucesso, E erro, W aviso, I inform., A cancel.
        iv_message = 'Falha ao inativar produto'                 " Texto de mensagem
      ).
    ELSE.
      me->add_msg(
        iv_type    = 'S'                 " Ctg.mens.: S sucesso, E erro, W aviso, I inform., A cancel.
        iv_message = 'Produto Inativado com sucesso!'                 " Texto de mensagem
      ).
    ENDIF.

  ENDMETHOD.


  METHOD map_campos_atualizaveis.

    "Atualiza somente os campos que o usuário pode editar
    "id_prod e data_criacao permanecem os do registro original (carregado em BUSCAR_PRODUTO)
    me->ms_produto-nome           = is_entity-nome.
    me->ms_produto-descricao      = is_entity-descricao.
    me->ms_produto-preco          = is_entity-preco.
    me->ms_produto-categoria      = is_entity-categoria.
*    me->ms_produto-qtd_min        = is_entity-qntmin.
    me->ms_produto-unidade_medida = is_entity-unidade.
    me->ms_produto-status         = is_entity-status.

  ENDMETHOD.


  METHOD map_entity_to_prod.

    CLEAR me->ms_produto.

    "Mapeia Entity -> Estrutura interna
    MOVE-CORRESPONDING is_entity TO me->ms_produto.
    me->ms_produto-id_prod        = is_entity-id.
    me->ms_produto-status         = is_entity-status.
    me->ms_produto-data_criacao   = is_entity-criacao.
*    me->ms_produto-qtd_min        = is_entity-qntmin.
    me->ms_produto-unidade_medida = is_entity-unidade.


  ENDMETHOD.


  METHOD map_prod_to_entity.

    "Retorna para o Fiori mapeando os campos
    MOVE-CORRESPONDING me->ms_produto TO rs_entity_prod.
    rs_entity_prod-id           = me->ms_produto-id_prod.
    rs_entity_prod-status       = me->ms_produto-status.
    rs_entity_prod-criacao      = me->ms_produto-data_criacao.
*    rs_entity_prod-qntmin = me->ms_produto-qtd_min.
    rs_entity_prod-unidade      = me->ms_produto-unidade_medida.

  ENDMETHOD.


  METHOD preencher_campos.

    me->ms_produto-id_prod = me->gerar_id( ).
    me->ms_produto-status = 'A'.
    me->ms_produto-data_criacao = sy-datum.
    me->ms_produto-moeda = 'BRL'.

  ENDMETHOD.


  METHOD preparar_produto.

    CONDENSE me->ms_produto-nome.
    CONDENSE me->ms_produto-categoria.

    "Remove espaços no início e fim
    SHIFT me->ms_produto-nome LEFT DELETING LEADING space.
    SHIFT me->ms_produto-categoria LEFT DELETING LEADING space.

    "Upper case
    TRANSLATE ms_produto-nome TO UPPER CASE.
    TRANSLATE ms_produto-descricao TO UPPER CASE.
    TRANSLATE ms_produto-nome TO UPPER CASE.

  ENDMETHOD.


  METHOD salvar.

    DATA ls_produtos TYPE ztb_produtos.

    MOVE-CORRESPONDING me->ms_produto TO ls_produtos.  "Tipo identico para inserir por conta do mandante

    INSERT ztb_produtos FROM ls_produtos.

    IF sy-subrc <> 0.
      me->add_msg(
        iv_type    = 'E'
        iv_message = 'Erro ao salvar o produto.'
      ).
      RETURN.
    ENDIF.

    me->add_msg(
      iv_type    = 'S'
      iv_message = |Produto { me->ms_produto-id_prod } cadastrado com suceso!|
    ).

  ENDMETHOD.


  METHOD update_produto.

    me->buscar_produto( iv_idprod = iv_idprod ).   "Carrega o produto atual (com data_criacao, status etc.)

    IF me->has_error( ) = abap_true.               "Produto não encontrado -> aborta
      RETURN.
    ENDIF.

    me->map_campos_atualizaveis( is_entity = is_entity_prod ).  "Só sobrescreve campos editáveis
    me->preparar_produto( ).                       "Normaliza texto
    me->validar_produto( iv_mode = mc_update ).     "Validações

    IF me->has_error( ) = abap_true.
      RETURN.
    ENDIF.

    me->atualizar( ).                              "Persiste

  ENDMETHOD.


  METHOD validar_produto.

    CASE iv_mode.
      WHEN mc_create.

        "NOME
        IF me->ms_produto-nome IS INITIAL.
          me->add_msg( iv_type    = 'E' iv_message = 'Nome do produto obrigatório!' ).
        ENDIF.

        "PREÇO
        IF me->ms_produto-preco <= 0.
          me->add_msg( iv_type    = 'E' iv_message = 'Preço inválido!' ).
        ENDIF.

*>>> ABACO - LCM - 26/08/2026 - Início - Mudança regra de negócio

*        "Fornecedor
*        IF ms_produto-forn_id IS INITIAL.
*
*          me->add_msg(
*            iv_type    = 'E'
*            iv_message = 'Informe um fornecedor' ).
*        ELSE.
*          me->validar_fornecedor( ).
*
*        ENDIF.

*>>> ABACO - LCM - 26/08/2026 - Fim

*>>> ABACO - LCM - 26/08/2026 - Início - Adicionando campo quantidade mínima (alerta para repor estoque).

*        "Quantidade mínima (alerta)
*        IF me->ms_produto-qtd_min <= 0.
*          me->add_msg(
*            iv_type    = 'E'
*            iv_message = 'Informe uma quantidade válida!'
*          ).
*        ENDIF.

*>>> ABACO - LCM - 26/08/2026 - Fim

        "Categoria
        IF me->ms_produto-categoria IS INITIAL.

          me->add_msg(
            iv_type    = 'E'
            iv_message = 'Informe o tipo do produto' ).
        ENDIF.

      WHEN mc_update.

        "NOME
        IF me->ms_produto-nome IS INITIAL.
          me->add_msg( iv_type = 'E' iv_message = 'Nome do produto obrigatório!' ).
        ENDIF.

        "PREÇO
        IF me->ms_produto-preco <= 0.
          me->add_msg( iv_type = 'E' iv_message = 'Preço inválido!' ).
        ENDIF.

*>>> ABACO - LCM - 26/08/2026 - Início - Mudança regra de negócio

*        "Fornecedor
*        IF me->ms_produto-forn_id IS INITIAL.
*          me->add_msg( iv_type = 'E' iv_message = 'Informe um fornecedor' ).
*        ELSE.
*          me->validar_fornecedor( ).
*        ENDIF.

*>>> ABACO - LCM - 26/08/2026 - Fim

*>>> ABACO - LCM - 26/08/2026 - Início - Adicionando campo quantidade mínima (alerta para repor estoque).

*        "Quantidade mínima (alerta)
*        IF me->ms_produto-qtd_min <= 0.
*          me->add_msg(
*            iv_type    = 'E'
*            iv_message = 'Informe uma quantidade válida!'
*          ).
*        ENDIF.

*>>> ABACO - LCM - 26/08/2026 - Fim

        "Categoria
        IF me->ms_produto-categoria IS INITIAL.
          me->add_msg( iv_type = 'E' iv_message = 'Informe o tipo do produto' ).
        ENDIF.
      WHEN OTHERS.
    ENDCASE.

  ENDMETHOD.
ENDCLASS.
