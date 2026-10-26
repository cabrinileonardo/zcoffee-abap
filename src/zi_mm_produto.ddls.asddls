@AbapCatalog.sqlViewName: 'ZV_MM_PRODUTOS'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS View para produtos'
@Metadata.ignorePropagatedAnnotations: true
define view ZI_MM_PRODUTO
  as select from ztb_produtos
{
  key id_prod        as Id,
      nome           as Nome,
      descricao      as Descricao,
      preco          as Preco,
      moeda          as Moeda,
      categoria      as Categoria,
      status         as Status,
      unidade_medida as Unidade,
      data_criacao   as Criacao
}
