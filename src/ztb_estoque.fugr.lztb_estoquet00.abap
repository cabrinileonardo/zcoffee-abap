*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTB_ESTOQUE.....................................*
DATA:  BEGIN OF STATUS_ZTB_ESTOQUE                   .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTB_ESTOQUE                   .
CONTROLS: TCTRL_ZTB_ESTOQUE
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTB_ESTOQUE                   .
TABLES: ZTB_ESTOQUE                    .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
