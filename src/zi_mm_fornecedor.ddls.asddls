@AbapCatalog.sqlViewName: 'ZV_MM_FORNECEDOR'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS View para fornecedores'
@Metadata.ignorePropagatedAnnotations: true

/* 1. Habilita a funcionalidade de busca na CDS View */
@Search.searchable: true 

define view ZI_MM_FORNECEDOR
  as select from ztb_fornecedores
{
  key id_forn  as IdForn,
  
      /* 2. Define o campo Nome como elemento de busca padrão */
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      nome     as Nome,
      
      cnpj     as CNPJ,
      email    as Email, 
      telefone as Telefone,
      status   as Status   
}
