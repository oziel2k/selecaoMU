*--------------------------------------------------------*
*  Oziel oziel2k@outlook.com	                    2022 *
*--------------------------------------------------------*
*  Programa    : main.prg                                *
*  Finalidade  : Programa principal                      *
*  Programador : Oziel                                   *
*--------------------------------------------------------*


*== Sets Iniciais ============

IF ! EMPTY(PROGRAM(2))
	RETURN 'Este programa deve ser o principal.'
ENDIF
IF VERSION(2) <> 0
	RETURN 'Versão apenas para RunTime.'
ENDIF

SET DATE BRITISH
SET HOURS TO 24

_SCREEN.Icon = 'app.ico'

CLEAR

*== Criação variáveis globais e carregamento bibliotecas não visuais ============
PUBLIC gcPathTabelas, gcUsuario, gcPapel, gcInifile, gcPathExe, glLogou
SET PROCEDURE TO LibBase, LibRegras
SET PATH TO (SYS(2004))

gcPathExe = JUSTPATH(SYS(16, 0))

_SCREEN.Caption = 'Sistema de Aprovação de Notas (Seleção MU)'

*== Inicia o carregamento ============
IF !CarregarConfiguracoes()
	RETURN
ENDIF

On Shutdown FecharSistema()

ON ERROR ControlaErro(ERROR(), PROGRAM(), LINENO())

CarregaMenus()
IF UsuarioLogou()
	READ EVENTS
ENDIF

IF VERSION(2) <> 0
	ReleaseToolBars()
	PUSH MENU _MSYSMENU
ENDIF

ON ERROR

RELEASE ALL EXTENDED


