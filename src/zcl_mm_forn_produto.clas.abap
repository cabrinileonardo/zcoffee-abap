class ZCL_MM_FORN_PRODUTO definition
  public
  final
  create public .

public section.

  types:
    BEGIN OF ty_relacao_entity,
      idforn           TYPE zde_forn_id,
      idprod           TYPE zidprod,
      nomefornecedor   TYPE char40,
      nomeproduto      TYPE znome,
      precocompra      TYPE zpreco,
      moeda            TYPE zmoeda,
      prazoentregadias TYPE zde_prazo_dias,
      codprodforn      TYPE zde_cod_prod_forn,
      status           TYPE zstatus,
      dataultimacompra TYPE dats,
    END OF ty_relacao_entity .

  methods CREATE_RELACAO
    importing
      !IS_ENTITY_RELACAO type TY_RELACAO_ENTITY .
  methods UPDATE_RELACAO
    importing
      !IS_ENTITY_RELACAO type TY_RELACAO_ENTITY
      !IV_ID_FORN type ZDE_FORN_ID
      !IV_ID_PROD type ZIDPROD .
  methods DELETE_RELACAO
    importing
      !IV_ID_FORN type ZDE_FORN_ID
      !IV_ID_PROD type ZIDPROD .
  methods GET_MESSAGES
    returning
      value(RT_MSG) type BAPIRET2_T .
  methods MAP_RELACAO_TO_ENTITY
    returning
      value(RS_ENTITY_RELACAO) type TY_RELACAO_ENTITY .
protected section.
private section.

  data MS_RELACAO type ZTB_FORN_PROD .
  data MC_CREATE type CHAR1 value 'C' ##NO_TEXT.
  data MC_UPDATE type CHAR1 value 'U' ##NO_TEXT.
  data MT_MSG type BAPIRET2_T .

  methods SET_RELACAO
    importing
      !IS_ENTITY type TY_RELACAO_ENTITY .
  methods BUSCAR_RELACAO
    importing
      !IV_ID_FORN type ZDE_FORN_ID
      !IV_ID_PROD type ZIDPROD .
  methods MAP_CAMPOS_ATUALIZAVEIS
    importing
      !IS_ENTITY type TY_RELACAO_ENTITY .
  methods VALIDAR_RELACAO
    importing
      !IV_MODE type CHAR1 .
  methods ADD_MSG
    importing
      !IV_TYPE type BAPI_MTYPE
      !IV_MSG type BAPI_MSG .
  methods PREENCHER_CAMPOS .
  methods HAS_ERROR
    returning
      value(RV_ERROR) type ABAP_BOOL .
  methods SALVAR .
  methods ATUALIZAR .
  methods INATIVAR .
ENDCLASS.



CLASS ZCL_MM_FORN_PRODUTO IMPLEMENTATION.


  METHOD add_msg.

    APPEND VALUE bapiret2( type    = iv_type
                           message = iv_msg ) TO mt_msg.

  ENDMETHOD.


  METHOD create_relacao.

*   Mesma ordem da ZCL_MM_FORNECEDOR: mapear, validar e só então gravar.
    me->set_relacao( is_entity = is_entity_relacao ).

    me->preencher_campos( ).

    me->validar_relacao( iv_mode = mc_create ).

    IF me->has_error( ) = abap_true.
      RETURN.
    ENDIF.

    me->salvar( ).

  ENDMETHOD.


  METHOD update_relacao.

*   Carrega o registro atual primeiro: assim o par ID_FORN/ID_PROD vem do
*   banco (chave da URL), não do payload, e a validação sabe qual é o
*   próprio registro.
    me->buscar_relacao( iv_id_forn = iv_id_forn
                        iv_id_prod = iv_id_prod ).

    IF me->has_error( ) = abap_true.
      RETURN.
    ENDIF.

    me->map_campos_atualizaveis( is_entity = is_entity_relacao ).

    me->validar_relacao( iv_mode = mc_update ).

    IF me->has_error( ) = abap_true.
      RETURN.
    ENDIF.

    me->atualizar( ).

  ENDMETHOD.


  METHOD delete_relacao.

*   Exclusão é lógica: o registro permanece na tabela, só o status muda
*   para inativo - mesmo padrão da ZCL_MM_FORNECEDOR. Assim o histórico de
*   compras (DataUltimaCompra) não se perde quando um fornecedor deixa de
*   fornecer um produto.
    me->buscar_relacao( iv_id_forn = iv_id_forn
                        iv_id_prod = iv_id_prod ).

    IF me->has_error( ) = abap_true.
      RETURN.
    ENDIF.

    me->inativar( ).

  ENDMETHOD.


  METHOD set_relacao.

    CLEAR me->ms_relacao.

    me->ms_relacao-id_forn             = is_entity-idforn.
    me->ms_relacao-id_prod             = is_entity-idprod.
    me->ms_relacao-preco_compra        = is_entity-precocompra.
    me->ms_relacao-moeda                = is_entity-moeda.
    me->ms_relacao-prazo_entrega_dias  = is_entity-prazoentregadias.
    me->ms_relacao-cod_prod_forn        = is_entity-codprodforn.
    me->ms_relacao-status               = is_entity-status.
    me->ms_relacao-data_ult_compra      = is_entity-dataultimacompra.

  ENDMETHOD.


  METHOD map_campos_atualizaveis.

*   ID_FORN e ID_PROD são a chave (vêm da URL, carregados em BUSCAR_RELACAO)
*   e não são editáveis - trocar o fornecedor ou o produto de uma relação
*   já existente é, na prática, criar uma relação nova.
    me->ms_relacao-preco_compra       = is_entity-precocompra.
    me->ms_relacao-moeda               = is_entity-moeda.
    me->ms_relacao-prazo_entrega_dias = is_entity-prazoentregadias.
    me->ms_relacao-cod_prod_forn       = is_entity-codprodforn.
    me->ms_relacao-status              = is_entity-status.
    me->ms_relacao-data_ult_compra     = is_entity-dataultimacompra.

  ENDMETHOD.


  METHOD validar_relacao.

    DATA: lv_status_forn TYPE zstatus,
          lv_status_prod TYPE zstatus,
          lv_existe      TYPE abap_bool.

*   FORNECEDOR - obrigatório e precisa existir e estar ativo. Um fornecedor
*   inativo não pode passar a fornecer (nem continuar fornecendo) produtos.
    IF ms_relacao-id_forn IS INITIAL.

      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Informe o fornecedor.' ).

    ELSE.

      SELECT SINGLE status FROM ztb_fornecedores
        INTO @lv_status_forn
        WHERE id_forn = @ms_relacao-id_forn.

      IF sy-subrc <> 0.
        me->add_msg( iv_type = 'E'
                     iv_msg  = |Fornecedor { ms_relacao-id_forn } não encontrado.| ).
      ELSEIF lv_status_forn <> 'A'.
        me->add_msg( iv_type = 'E'
                     iv_msg  = |Fornecedor { ms_relacao-id_forn } está inativo.| ).
      ENDIF.

    ENDIF.

*   PRODUTO - obrigatório e precisa existir e estar ativo.
    IF ms_relacao-id_prod IS INITIAL.

      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Informe o produto.' ).

    ELSE.

      SELECT SINGLE status FROM ztb_produtos
        INTO @lv_status_prod
        WHERE id_prod = @ms_relacao-id_prod.

      IF sy-subrc <> 0.
        me->add_msg( iv_type = 'E'
                     iv_msg  = |Produto { ms_relacao-id_prod } não encontrado.| ).
      ELSEIF lv_status_prod <> 'A'.
        me->add_msg( iv_type = 'E'
                     iv_msg  = |Produto { ms_relacao-id_prod } está inativo.| ).
      ENDIF.

    ENDIF.

*   Par fornecedor/produto duplicado - só faz sentido checar na criação;
*   na alteração o par já é o mesmo registro carregado em BUSCAR_RELACAO.
    IF iv_mode = mc_create AND ms_relacao-id_forn IS NOT INITIAL AND ms_relacao-id_prod IS NOT INITIAL.

      SELECT SINGLE @abap_true FROM ztb_forn_prod
        INTO @lv_existe
        WHERE id_forn = @ms_relacao-id_forn
          AND id_prod = @ms_relacao-id_prod.

      IF lv_existe = abap_true.
        me->add_msg( iv_type = 'E'
                     iv_msg  = |Este fornecedor já está cadastrado para este produto.| ).
      ENDIF.

    ENDIF.

*   PREÇO DE COMPRA
    IF ms_relacao-preco_compra IS INITIAL OR ms_relacao-preco_compra <= 0.
      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Informe um preço de compra maior que zero.' ).
    ENDIF.

    IF ms_relacao-moeda IS INITIAL.
      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Informe a moeda do preço de compra.' ).
    ENDIF.

*   PRAZO DE ENTREGA
    IF ms_relacao-prazo_entrega_dias IS INITIAL OR ms_relacao-prazo_entrega_dias <= 0.
      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Informe um prazo de entrega maior que zero (em dias).' ).
    ENDIF.

*   CÓDIGO DO PRODUTO NO FORNECEDOR - cada fornecedor tem sua própria
*   codificação interna; sem ela a conferência do pedido de compra fica
*   sem referência do lado do fornecedor.
    IF ms_relacao-cod_prod_forn IS INITIAL.
      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Informe o código do produto no fornecedor.' ).
    ENDIF.

    CASE iv_mode.

      WHEN mc_update.

*       Só na alteração o status vem do usuário: na criação ele é fixado em
*       'A' por PREENCHER_CAMPOS.
        IF ms_relacao-status <> 'A' AND ms_relacao-status <> 'I'.
          me->add_msg( iv_type = 'E'
                       iv_msg  = 'Status inválido: use A (ativo) ou I (inativo).' ).
        ENDIF.

      WHEN OTHERS.

    ENDCASE.

  ENDMETHOD.


  METHOD preencher_campos.

*   Uma relação nasce sempre ativa; o usuário só pode inativá-la depois,
*   pelo botão de ação (exclusão lógica), nunca na criação.
    ms_relacao-status = 'A'.

  ENDMETHOD.


  METHOD has_error.

    READ TABLE me->mt_msg WITH KEY type = 'E'
      TRANSPORTING NO FIELDS.

    IF sy-subrc = 0.
      rv_error = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD get_messages.

    rt_msg = me->mt_msg.

  ENDMETHOD.


  METHOD map_relacao_to_entity.

*   Devolve a entidade ao Fiori já com o nome do fornecedor e do produto,
*   assim a tela não precisa de uma segunda chamada só para exibir o nome.
    rs_entity_relacao-idforn           = me->ms_relacao-id_forn.
    rs_entity_relacao-idprod           = me->ms_relacao-id_prod.
    rs_entity_relacao-precocompra      = me->ms_relacao-preco_compra.
    rs_entity_relacao-moeda            = me->ms_relacao-moeda.
    rs_entity_relacao-prazoentregadias = me->ms_relacao-prazo_entrega_dias.
    rs_entity_relacao-codprodforn      = me->ms_relacao-cod_prod_forn.
    rs_entity_relacao-status           = me->ms_relacao-status.
    rs_entity_relacao-dataultimacompra = me->ms_relacao-data_ult_compra.

    SELECT SINGLE nome FROM ztb_fornecedores
      INTO @rs_entity_relacao-nomefornecedor
      WHERE id_forn = @me->ms_relacao-id_forn.

    SELECT SINGLE nome FROM ztb_produtos
      INTO @rs_entity_relacao-nomeproduto
      WHERE id_prod = @me->ms_relacao-id_prod.

  ENDMETHOD.


  METHOD salvar.

    INSERT ztb_forn_prod FROM me->ms_relacao.

    IF sy-subrc <> 0.
      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Erro ao salvar a relação fornecedor/produto.' ).
      RETURN.
    ENDIF.

    me->add_msg( iv_type = 'S'
                 iv_msg  = |Fornecedor { me->ms_relacao-id_forn } vinculado ao produto | &&
                           |{ me->ms_relacao-id_prod } com sucesso!| ).

  ENDMETHOD.


  METHOD buscar_relacao.

    CLEAR me->ms_relacao.

    SELECT SINGLE *
      FROM ztb_forn_prod
      INTO @me->ms_relacao
      WHERE id_forn = @iv_id_forn
        AND id_prod = @iv_id_prod.

    IF sy-subrc <> 0.
      me->add_msg( iv_type = 'E'
                   iv_msg  = |Relação entre o fornecedor { iv_id_forn } e o produto | &&
                             |{ iv_id_prod } não encontrada.| ).
    ENDIF.

  ENDMETHOD.


  METHOD atualizar.

    UPDATE ztb_forn_prod FROM me->ms_relacao.

    IF sy-subrc <> 0.
      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Erro ao atualizar a relação fornecedor/produto.' ).
      RETURN.
    ENDIF.

    me->add_msg( iv_type = 'S'
                 iv_msg  = |Relação entre o fornecedor { me->ms_relacao-id_forn } e o produto | &&
                           |{ me->ms_relacao-id_prod } atualizada com sucesso!| ).

  ENDMETHOD.


  METHOD inativar.

    me->ms_relacao-status = 'I'.

    UPDATE ztb_forn_prod FROM me->ms_relacao.

    IF sy-subrc <> 0.
      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Erro ao excluir a relação fornecedor/produto.' ).
      RETURN.
    ENDIF.

    me->add_msg( iv_type = 'S'
                 iv_msg  = |Fornecedor { me->ms_relacao-id_forn } desvinculado do produto | &&
                           |{ me->ms_relacao-id_prod } com sucesso!| ).

  ENDMETHOD.
ENDCLASS.
