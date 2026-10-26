# ☕ ZCOFFEE — ABAP (SAP GUI + OData)

Back-end ABAP do **ZCOFFEE**, um ERP simplificado de cafeteria que eu desenvolvo como projeto de estudo no SAP.
Este repositório tem as duas gerações do projeto, exportadas com **abapGit**:

- **v1 — SAP GUI:** cockpit em module pool com transações Z para SD, MM, FI e RH
- **v2 — back-end Fiori:** CDS views e serviço OData V2 (`ZCOFFEE_SRV`) consumidos pelo app [zcoffee-ui5](https://github.com/cabrinileonardo/zcoffee-ui5)

---

## v1 — Cockpit SAP GUI

Transação `ZCOFFEE` → module pool `SAPMZ_ZCOFFEE_COCKPIT`, que funciona como hub de navegação entre os módulos.

**Cockpit**
- 5 dynpros: menu principal (0100) e um menu para cada módulo — Vendas (0200), Financeiro (0300), Compras (0400) e RH (0500)
- PBO/PAI, GUI status e title bar próprios em cada tela
- 6 classes locais organizando a navegação (`lcl_app` como classe central e uma classe por módulo)
- Popup de confirmação ao sair (`POPUP_TO_CONFIRM`), encapsulado em classe

**Transações chamadas pelo cockpit**

| Transação | Módulo | Destaques |
|---|---|---|
| `ZSDPED` | SD | Module pool de pedidos com 4 telas, 2 ALVs OO (`CL_GUI_ALV_GRID` em custom container) e function modules para total e baixa de estoque |
| `ZSDMP` | SD | Monitor de pedidos com `CL_SALV_TABLE`, cabeçalho → itens no duplo clique |
| `ZCLIENTES` | SD | CRUD de clientes |
| `ZPRODUTOS` | MM | CRUD de produtos |
| `ZREL_ESTOQUE` | MM | Relatório de estoque com `REUSE_ALV_GRID_DISPLAY` |
| `ZRELFI` | FI | Relatório financeiro com `CL_SALV_TABLE` e ALV de detalhe no duplo clique |
| `ZFIMENUPAG` / `ZFIBAIXAFAT` | FI | Formas de pagamento e baixa de faturas |
| `ZFUNCIONARIOS` | RH | CRUD de funcionários |

**Outros objetos:** tabelas Z, function groups, number ranges, search helps, classes globais `ZCL_POPUP` e `ZCL_PEDIDO_SERVICE` e **Adobe Forms** de fatura e nota fiscal.

O projeto usa as **três abordagens de ALV**: `REUSE_ALV_GRID_DISPLAY`, `CL_SALV_TABLE` e `CL_GUI_ALV_GRID`.

---

## v2 — Back-end do app Fiori

**Serviço OData V2 `ZCOFFEE_SRV`** (projeto SEGW `ZCOFFEE`)
- `ZCL_ZCOFFEE_DPC_EXT`: implementação de create, update e delete das entidades
- `ZCL_ZCOFFEE_MPC_EXT`: modelo do serviço
- Modelo de anotações `ZCOFFEE_ANNO_MDL` para os smart controls do front

**CDS views**

| CDS | Uso |
|---|---|
| `ZIRH_ZCOFFEE` | Funcionários (RH) |
| `ZCDS_HIST_SALARIO` | Histórico salarial |
| `ZI_MM_PRODUTO` | Produtos (MM) |
| `ZI_MM_FORNECEDOR` | Fornecedores (MM) |
| `ZI_MM_FORN_PRODUTO` | Vínculo fornecedor × produto |

**Regras de negócio em classe**
- `ZCL_ZCOFFEE_RH`: criar, atualizar e **inativar** funcionário (inativação lógica em vez de exclusão física)
- Validações antes de gravar (ex.: CPF duplicado), com os erros devolvidos ao front pelo message container (`/IWBEP/CX_MGW_BUSI_EXCEPTION`)

**Dicionário de dados:** tabelas `ZTB_*`, domínios e elementos de dados próprios (CPF, CNPJ, cargo, status etc.) e number range para o ID de funcionário.

---

## Como importar

1. Instale o [abapGit](https://abapgit.org) no seu sistema
2. Crie um pacote (ex.: `ZCOFFEE`) e faça *clone* deste repositório nele
3. Ative os objetos e registre o serviço `ZCOFFEE_SRV` na `/IWFND/MAINT_SERVICE`

## Tecnologias

ABAP procedural e OO · module pool (dynpro) · ALV (REUSE, SALV, GUI_ALV_GRID) · Adobe Forms · CDS views · SAP Gateway / OData V2 (SEGW) · abapGit

---

Projeto de estudo feito por **Leonardo Cabrini Mauro** · [LinkedIn](https://www.linkedin.com/in/leonardo-cabrini-mauro-79b292355/)
