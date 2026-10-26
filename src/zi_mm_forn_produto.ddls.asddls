@AbapCatalog.sqlViewName: 'ZV_MM_FORNPROD'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS View para relação Fornecedor x Produto'
@Metadata.ignorePropagatedAnnotations: true
define view ZI_MM_FORN_PRODUTO
  as select from ztb_forn_prod as FornProd

    inner join ztb_fornecedores as Forn on FornProd.id_forn = Forn.id_forn
    inner join ztb_produtos     as Prod on FornProd.id_prod = Prod.id_prod
{
  key FornProd.id_forn            as IdForn,
  key FornProd.id_prod            as IdProd,
      Forn.nome                   as NomeFornecedor,
      Prod.nome                   as NomeProduto,
      FornProd.preco_compra       as PrecoCompra,
      FornProd.moeda              as Moeda,
      FornProd.prazo_entrega_dias as PrazoEntregaDias,
      FornProd.cod_prod_forn      as CodProdForn,
      FornProd.status             as Status,
      FornProd.data_ult_compra    as DataUltimaCompra
}
