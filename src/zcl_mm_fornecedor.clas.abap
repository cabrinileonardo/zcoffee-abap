class ZCL_MM_FORNECEDOR definition
  public
  final
  create public .

public section.

  methods CREATE_FORNECEDOR
    importing
      !IS_ENTITY_FORN type ZCL_ZCOFFEE_MPC=>TS_ZI_MM_FORNECEDORTYPE .
  methods UPDATE_FORNECEDOR
    importing
      !IS_ENTITY_FORN type ZCL_ZCOFFEE_MPC=>TS_ZI_MM_FORNECEDORTYPE
      !IV_IDFORN type ZDE_FORN_ID .
  methods DELETE_FORNECEDOR
    importing
      !IV_ID_FORN type ZDE_FORN_ID .
  methods GET_MESSAGES
    returning
      value(RT_MSG) type BAPIRET2_T .
  methods MAP_FORN_TO_ENTITY
    returning
      value(RS_ENTITY_FORN) type ZCL_ZCOFFEE_MPC=>TS_ZI_MM_FORNECEDORTYPE .
protected section.
private section.

  data MS_FORNECEDOR type ZST_FORNECEDOR .
  data MC_CREATE type CHAR1 value 'C' ##NO_TEXT.
  data MC_UPDATE type CHAR1 value 'U' ##NO_TEXT.
  data MT_MSG type BAPIRET2_T .

  methods SET_FORNECEDOR
    importing
      !IS_ENTITY type ZCL_ZCOFFEE_MPC=>TS_ZI_MM_FORNECEDORTYPE .
  methods BUSCAR_FORNECEDOR
    importing
      !IV_IDFORN type ZDE_FORN_ID .
  methods MAP_CAMPOS_ATUALIZAVEIS
    importing
      !IS_ENTITY type ZCL_ZCOFFEE_MPC=>TS_ZI_MM_FORNECEDORTYPE .
  methods VALIDAR_FORNECEDOR
    importing
      !IV_MODE type CHAR1 .
  methods ADD_MSG
    importing
      !IV_TYPE type BAPI_MTYPE
      !IV_MSG type BAPI_MSG .
  methods IS_CNPJ_VALIDO
    importing
      !IV_CNPJ type CLIKE
    returning
      value(RV_VALIDO) type ABAP_BOOL .
  methods PREPARAR_FORNECEDOR .
  methods PREENCHER_CAMPOS .
  methods HAS_ERROR
    returning
      value(RV_ERROR) type ABAP_BOOL .
  methods GERAR_ID
    returning
      value(RV_ID) type ZDE_FORN_ID .
  methods SALVAR .
  methods ATUALIZAR .
  methods INATIVAR .
ENDCLASS.



CLASS ZCL_MM_FORNECEDOR IMPLEMENTATION.


  METHOD add_msg.

*>>> ABACO - LCM - 18/09/2026 - Início - Correção: mensagem era anexada vazia
* A versão anterior fazia APPEND de ms_msg sem preencher os parâmetros
* recebidos, então toda mensagem entrava vazia em mt_msg.
    APPEND VALUE bapiret2( type    = iv_type
                           message = iv_msg ) TO mt_msg.
*>>> ABACO - LCM - 18/09/2026 - Fim

  ENDMETHOD.


  METHOD atualizar.

    DATA ls_fornecedor TYPE ztb_fornecedores.

    MOVE-CORRESPONDING me->ms_fornecedor TO ls_fornecedor.

    UPDATE ztb_fornecedores FROM ls_fornecedor.

    IF sy-subrc <> 0.
      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Erro ao atualizar o fornecedor.' ).
      RETURN.
    ENDIF.

    me->add_msg( iv_type = 'S'
                 iv_msg  = |Fornecedor { me->ms_fornecedor-id_forn } atualizado com sucesso!| ).

  ENDMETHOD.


  METHOD buscar_fornecedor.

    CLEAR me->ms_fornecedor.

    SELECT SINGLE *
      FROM ztb_fornecedores
      INTO CORRESPONDING FIELDS OF @me->ms_fornecedor
      WHERE id_forn = @iv_idforn.

    IF sy-subrc <> 0.
      me->add_msg( iv_type = 'E'
                   iv_msg  = |Fornecedor { iv_idforn } não encontrado.| ).
    ENDIF.

  ENDMETHOD.


  METHOD create_fornecedor.

*   Mesma ordem da ZCL_MM_PRODUTO: mapear, normalizar, validar e só então gravar.
    me->set_fornecedor( is_entity = is_entity_forn ).

*   O ID é sempre gerado pelo servidor. Zerar aqui não é cosmético: a checagem
*   de CNPJ duplicado exclui o próprio ID, então um payload que viesse com o
*   ID de um fornecedor existente faria a duplicidade passar despercebida.
    CLEAR me->ms_fornecedor-id_forn.

    me->preparar_fornecedor( ).

    me->validar_fornecedor( iv_mode = mc_create ).

    IF me->has_error( ) = abap_true.
      RETURN.
    ENDIF.

    me->preencher_campos( ).

    me->ms_fornecedor-id_forn = me->gerar_id( ).

    IF me->has_error( ) = abap_true.
      RETURN.
    ENDIF.

    me->salvar( ).

  ENDMETHOD.


  METHOD delete_fornecedor.

*   Exclusão é lógica: o registro permanece na tabela, só o status muda
*   para inativo. BUSCAR_FORNECEDOR garante que o ID existe antes de mexer.
    me->buscar_fornecedor( iv_idforn = iv_id_forn ).

    IF me->has_error( ) = abap_true.
      RETURN.
    ENDIF.

    me->inativar( ).

  ENDMETHOD.


  METHOD gerar_id.

    DATA lv_number TYPE n LENGTH 6.

    CLEAR: lv_number, rv_id.

    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr             = '01'
        object                  = 'ZNRO_IDFOR'
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
      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Erro crítico ao gerar ID do fornecedor.' ).
      RETURN.
    ENDIF.

    rv_id = lv_number.

  ENDMETHOD.


  METHOD get_messages.

    rt_msg = me->mt_msg.

  ENDMETHOD.


  METHOD has_error.

    READ TABLE me->mt_msg WITH KEY type = 'E'
      TRANSPORTING NO FIELDS.

    IF sy-subrc = 0.
      rv_error = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD inativar.

    DATA ls_fornecedor TYPE ztb_fornecedores.

*>>> ABACO - LCM - 06/10/2026 - Início - Alteração de campo ativo para status na estrutura
*    me->ms_fornecedor-ativo = 'I'.
    me->ms_fornecedor-status = 'I'.
*>>> ABACO - LCM - 18/09/2026 - Fim

    MOVE-CORRESPONDING me->ms_fornecedor TO ls_fornecedor.

    UPDATE ztb_fornecedores FROM ls_fornecedor.

    IF sy-subrc <> 0.
      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Erro ao excluir o fornecedor.' ).
      RETURN.
    ENDIF.

    me->add_msg( iv_type = 'S'
                 iv_msg  = |Fornecedor { me->ms_fornecedor-id_forn } excluído com sucesso!| ).

  ENDMETHOD.


  METHOD is_cnpj_valido.

*   Valida os dois dígitos verificadores do CNPJ (módulo 11).
*   Espera 14 dígitos, sem máscara - normalizar antes em PREPARAR_FORNECEDOR.
    CONSTANTS: lc_pesos1 TYPE c LENGTH 12 VALUE '543298765432',
               lc_pesos2 TYPE c LENGTH 13 VALUE '6543298765432'.

*   Cópia de tamanho exato: o parâmetro é CLIKE e pode chegar de um campo
*   maior que 14, cujos brancos à direita fariam o operador CN acusar
*   caractere não numérico que não existe no valor.
    DATA: lv_cnpj   TYPE c LENGTH 14,
          lv_soma   TYPE i,
          lv_resto  TYPE i,
          lv_dv     TYPE i,
          lv_digito TYPE i,
          lv_pos    TYPE i.

    rv_valido = abap_false.

    IF strlen( iv_cnpj ) <> 14.
      RETURN.
    ENDIF.

    lv_cnpj = iv_cnpj.

    IF lv_cnpj CN '0123456789'.
      RETURN.
    ENDIF.

*   Sequências repetidas (00000000000000, 11111111111111...) satisfazem o
*   cálculo do dígito, mas não são CNPJ válido.
    IF lv_cnpj CO lv_cnpj(1).
      RETURN.
    ENDIF.

*   1o dígito verificador
    CLEAR lv_soma.
    DO 12 TIMES.
      lv_pos    = sy-index - 1.
      lv_digito = lv_cnpj+lv_pos(1).
      lv_soma   = lv_soma + lv_digito * lc_pesos1+lv_pos(1).
    ENDDO.

    lv_resto = lv_soma MOD 11.
    IF lv_resto < 2.
      lv_dv = 0.
    ELSE.
      lv_dv = 11 - lv_resto.
    ENDIF.

    lv_digito = lv_cnpj+12(1).
    IF lv_digito <> lv_dv.
      RETURN.
    ENDIF.

*   2o dígito verificador
    CLEAR lv_soma.
    DO 13 TIMES.
      lv_pos    = sy-index - 1.
      lv_digito = lv_cnpj+lv_pos(1).
      lv_soma   = lv_soma + lv_digito * lc_pesos2+lv_pos(1).
    ENDDO.

    lv_resto = lv_soma MOD 11.
    IF lv_resto < 2.
      lv_dv = 0.
    ELSE.
      lv_dv = 11 - lv_resto.
    ENDIF.

    lv_digito = lv_cnpj+13(1).
    IF lv_digito = lv_dv.
      rv_valido = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD map_campos_atualizaveis.

*   Sobrescreve apenas o que o usuário pode editar. ID_FORN e DATA_CRIACAO
*   permanecem os do registro original, carregado em BUSCAR_FORNECEDOR.
*   O CNPJ é editável de propósito: sem isso, um cadastro criado com CNPJ
*   errado ficaria impossível de corrigir pela aplicação. A validação de
*   dígito verificador e de duplicidade continua valendo na alteração.
    me->ms_fornecedor-nome     = is_entity-nome.
    me->ms_fornecedor-cnpj     = is_entity-cnpj.
    me->ms_fornecedor-email    = is_entity-email.
    me->ms_fornecedor-telefone = is_entity-telefone.

*>>> ABACO - LCM - 06/10/2026 - Início - Alteração de campo ativo para status na estrutura
*    me->ms_fornecedor-ativo    = is_entity-ativo.
    me->ms_fornecedor-status = is_entity-status.
*>>> ABACO - LCM - 06/10/2026 - Fim

  ENDMETHOD.


  METHOD map_forn_to_entity.

*   Devolve a entidade ao Fiori já com o ID gerado.
*   A CDS ZI_MM_FORNECEDOR não expõe DATA_CRIACAO, então ela não retorna.
    rs_entity_forn-idforn   = me->ms_fornecedor-id_forn.
    rs_entity_forn-nome     = me->ms_fornecedor-nome.
    rs_entity_forn-cnpj     = me->ms_fornecedor-cnpj.
    rs_entity_forn-email    = me->ms_fornecedor-email.
    rs_entity_forn-telefone = me->ms_fornecedor-telefone.

*>>> ABACO - LCM - 06/10/2026 - Início - Alteração de campo ativo para status na estrutura
*    rs_entity_forn-ativo    = me->ms_fornecedor-ativo.
     rs_entity_forn-status = me->ms_fornecedor-status.
*>>> ABACO - LCM - 06/10/2026 - Fim


  ENDMETHOD.


  METHOD preencher_campos.

*   Campos de controle são definidos pelo servidor, nunca pelo payload:
*   um fornecedor nasce ativo e com a data de criação do dia.

*>>> ABACO - LCM - 06/10/2026 - Início - Alteração de campo ativo para status na estrutura
*    ms_fornecedor-ativo        = 'A'.
    ms_fornecedor-status = 'A'.
*>>> ABACO - LCM - 06/10/2026 - Fim

    ms_fornecedor-data_criacao = sy-datum.

  ENDMETHOD.


  METHOD preparar_fornecedor.

*   Normaliza ANTES de validar: sem isto a checagem de CNPJ duplicado não
*   enxerga '12.345.678/0001-01' e '12345678000101' como o mesmo cadastro.
    CONDENSE ms_fornecedor-nome.

    CONDENSE ms_fornecedor-email NO-GAPS.
    TRANSLATE ms_fornecedor-email TO LOWER CASE.

*   Persiste só dígitos; a máscara é responsabilidade da camada de exibição.
    REPLACE ALL OCCURRENCES OF PCRE '\D' IN ms_fornecedor-cnpj     WITH ``.
    REPLACE ALL OCCURRENCES OF PCRE '\D' IN ms_fornecedor-telefone WITH ``.

    CONDENSE ms_fornecedor-cnpj     NO-GAPS.
    CONDENSE ms_fornecedor-telefone NO-GAPS.

  ENDMETHOD.


  METHOD salvar.

    DATA ls_fornecedor TYPE ztb_fornecedores.

    MOVE-CORRESPONDING me->ms_fornecedor TO ls_fornecedor.

    INSERT ztb_fornecedores FROM ls_fornecedor.

    IF sy-subrc = 4.
*     INSERT ... FROM devolve 4 exclusivamente quando já existe registro com a
*     mesma chave. O ID vem do number range, então isto não é erro do dado
*     informado: significa que ZNRO_IDFOR está fora de sincronia com a tabela
*     (registro gravado por fora do range, ou intervalo recriado do zero).
      me->add_msg(
        iv_type = 'E'
        iv_msg  = |Já existe fornecedor com o ID { me->ms_fornecedor-id_forn }. | &&
                  |Verifique o intervalo 01 do number range ZNRO_IDFOR.| ).
      RETURN.
    ENDIF.

    IF sy-subrc <> 0.
      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Erro ao salvar o fornecedor.' ).
      RETURN.
    ENDIF.

    me->add_msg( iv_type = 'S'
                 iv_msg  = |Fornecedor { me->ms_fornecedor-id_forn } cadastrado com sucesso!| ).

  ENDMETHOD.


  METHOD set_fornecedor.

*>>> ABACO - LCM - 18/09/2026 - Início - Atribuição por nome
* A versão anterior fazia ms_fornecedor = is_entity entre estruturas de tipos
* diferentes: funcionava por coincidência de ordem e tipo dos campos, e
* quebraria em silêncio se a CDS ZI_MM_FORNECEDOR ganhasse um campo novo.
    CLEAR me->ms_fornecedor.

    me->ms_fornecedor-id_forn  = is_entity-idforn.
    me->ms_fornecedor-nome     = is_entity-nome.
    me->ms_fornecedor-cnpj     = is_entity-cnpj.
    me->ms_fornecedor-email    = is_entity-email.
    me->ms_fornecedor-telefone = is_entity-telefone.
*>>> ABACO - LCM - 18/09/2026 - Fim

*>>> ABACO - LCM - 06/10/2026 - Início - Alteração de campo ativo para status na estrutura
*    me->ms_fornecedor-ativo    = is_entity-ativo.
    me->ms_fornecedor-status = is_entity-status.
*>>> ABACO - LCM - 06/10/2026 - Fim


  ENDMETHOD.


  METHOD update_fornecedor.

*   Carrega o registro atual primeiro: assim ID_FORN e DATA_CRIACAO vêm do
*   banco e não do payload, e a validação de CNPJ duplicado sabe qual é o
*   próprio fornecedor para não acusar conflito consigo mesmo.
    me->buscar_fornecedor( iv_idforn = iv_idforn ).

    IF me->has_error( ) = abap_true.
      RETURN.
    ENDIF.

    me->map_campos_atualizaveis( is_entity = is_entity_forn ).

    me->preparar_fornecedor( ).

    me->validar_fornecedor( iv_mode = mc_update ).

    IF me->has_error( ) = abap_true.
      RETURN.
    ENDIF.

    me->atualizar( ).

  ENDMETHOD.


  METHOD validar_fornecedor.

    DATA: lv_id_existente TYPE zde_forn_id,
          lv_tamanho      TYPE i.

*   As regras de nome, CNPJ, e-mail e telefone valem igualmente na criação e
*   na alteração, por isso ficam fora do CASE: duplicá-las por modo é o que
*   faz os dois blocos divergirem com o tempo.

*   NOME
    IF ms_fornecedor-nome IS INITIAL.
      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Informe o nome do fornecedor.' ).
    ELSEIF strlen( ms_fornecedor-nome ) > 60.
      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Nome do fornecedor excede 60 caracteres.' ).
    ENDIF.

*   CNPJ - obrigatório, dígito verificador e unicidade.
*   A unicidade só é confiável porque PREPARAR_FORNECEDOR já removeu a máscara.
    IF ms_fornecedor-cnpj IS INITIAL.

      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Informe o CNPJ do fornecedor.' ).

*    ELSEIF me->is_cnpj_valido( iv_cnpj = ms_fornecedor-cnpj ) = abap_false.
*
*      me->add_msg( iv_type = 'E'
*                   iv_msg  = |CNPJ { ms_fornecedor-cnpj } inválido.| ).

    ELSE.

*     O filtro por ID exclui o próprio registro na alteração. Na criação o ID
*     ainda está zerado, então nada é excluído e a checagem cobre a tabela toda.
      SELECT SINGLE id_forn
        FROM ztb_fornecedores
        INTO @lv_id_existente
        WHERE cnpj    = @ms_fornecedor-cnpj
          AND id_forn <> @ms_fornecedor-id_forn.

      IF sy-subrc = 0.
        me->add_msg( iv_type = 'E'
                     iv_msg  = |CNPJ já cadastrado no fornecedor { lv_id_existente }.| ).
      ENDIF.

    ENDIF.

*   EMAIL
    IF ms_fornecedor-email IS INITIAL.

      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Informe o e-mail do fornecedor.' ).

    ELSE.

      FIND PCRE '^[^@\s]+@[^@\s]+\.[^@\s]+$'
        IN |{ ms_fornecedor-email }|.

      IF sy-subrc <> 0.
        me->add_msg( iv_type = 'E'
                     iv_msg  = |E-mail { ms_fornecedor-email } inválido.| ).
      ENDIF.

    ENDIF.

*   TELEFONE - 10 dígitos (fixo) ou 11 (celular).
*   Não há validação de unicidade: fornecedores distintos podem compartilhar
*   o mesmo número (matriz/filial), como no cenário de referência do MM.
    IF ms_fornecedor-telefone IS INITIAL.

      me->add_msg( iv_type = 'E'
                   iv_msg  = 'Informe o telefone do fornecedor.' ).

    ELSE.

      lv_tamanho = strlen( ms_fornecedor-telefone ).

      IF lv_tamanho < 10 OR lv_tamanho > 11.
        me->add_msg( iv_type = 'E'
                     iv_msg  = 'Telefone deve ter 10 dígitos (fixo) ou 11 (celular).' ).
      ENDIF.

    ENDIF.

    CASE iv_mode.

      WHEN mc_update.

*       Só na alteração o status vem do usuário: na criação ele é fixado em
*       'A' por PREENCHER_CAMPOS, e o que vier no payload é ignorado.

*>>> ABACO - LCM - 06/10/2026 - Início - Alteração de campo ativo para status na estrutura
*        IF ms_fornecedor-ativo <> 'A' AND ms_fornecedor-ativo <> 'I'.
        IF ms_fornecedor-status <> 'A' AND ms_fornecedor-status <> 'I'.
*>>> ABACO - LCM - 18/09/2026 - Fim

          me->add_msg( iv_type = 'E'
                       iv_msg  = 'Status inválido: use A (ativo) ou I (inativo).' ).
        ENDIF.

      WHEN OTHERS.

    ENDCASE.

  ENDMETHOD.
ENDCLASS.
