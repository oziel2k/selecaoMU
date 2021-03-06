*--------------------------------------------------------*
*  Programa    : LibBase.prg                             *
*  Finalidade  : Programa com fun??es padr?es do sistema *
*  Programador : Oziel                                   *
*--------------------------------------------------------*


FUNCTION MudarUsuario()
	LOCAL loForm

	FecharTodosForms()
	
	IF !UsuarioLogou()
		FecharSistema()
	ENDIF
ENDFUNC	

FUNCTION MostraMensagem(tcMensagem, tcTitulo)
	
	DO CASE
		CASE !VARTYPE(tcTitulo) = 'L'		
		CASE TYPE('_SCREEN.ActiveForm.Caption') = 'C'
			tcTitulo = _SCREEN.ActiveForm.Caption
		OTHERWISE
			tcTitulo = _SCREEN.Caption
	ENDCASE
	
	MESSAGEBOX(tcMensagem,0, tcTitulo)

ENDFUNC

FUNCTION CredenciaisValidas(tcUsuario, tcSenha)
	RETURN RealizaLoginUsuario(tcUsuario, tcSenha)	
ENDFUNC

FUNCTION RealizaLoginUsuario(tcUsuario, tcSenha)	

	IF !AbreTabela('USUARIOS')
		MostraMensagem('N?o foi poss?vel abrir a tabela de usu?rios do sistema')
		RETURN .F.
	ENDIF 
	
	SELECT TOP 1 * FROM USUARIOS WHERE ALLTRIM(usuario) == ALLTRIM(tcUsuario) AND ALLTRIM(senha) == ALLTRIM(tcSenha) ;
		INTO CURSOR crsUsuario ORDER BY Usuario READWRITE
	
	IF RECCOUNT('crsUsuario')=0
		RETURN .F.
	ENDIF
	
	gcUsuario 	= ALLTRIM(crsUsuario.usuario)
	gcPapel		= crsUsuario.Papel
	
	RETURN .T.
ENDFUNC

FUNCTION ControlaErro(tnError, tcMethod, tnLine)
	
	LOCAL lcErrorMsg

	TEXT TO lcErrorMsg TEXTMERGE NOSHOW PRETEXT 3
		M?todo: <<tcMethod>>
		Linha: <<ALLTRIM(STR(tnLine))>>
		Erro: <<ALLTRIM(STR(tnError))>>		
	ENDTEXT
	
	MESSAGEBOX(lcErrorMsg)	
	
ENDFUNC


FUNCTION UsuarioLogou()
	LOCAL llLogou, loLogin

	DO FORM ('frmlogin') NAME FRMLOGIN TO loLogin

	RETURN glLogou
ENDFUNC

FUNCTION CarregarConfiguracoes()
	LOCAL lcArquivo, lcTemplate
	
	lcArquivo = ADDBS(gcPathExe) + 'config.cfg'
	
	IF !FILE(lcArquivo)
		MostraMensagem('Arquivo de configura??es n?o encontrado: "' + lcArquivo + '".')
		RETURN .F.
	ENDIF
	
	lcTemplate 	= ExtractXmlTagValue(FILETOSTR(lcArquivo), 'config')	
	gcPathTabelas = ADDBS(ExtractXmlTagValue(lcTemplate, 'pasta_tabelas'))		
	RETURN .T.
ENDFUNC


FUNCTION FecharSistema()

	FecharTodosForms()

	Clear All
	Clear Program
	Clear Resources
	CLOSE ALL
	CLEAR EVENTS
	ON SHUTDOWN
	CLEAR EVENTS
ENDFUNC

FUNCTION CarregaMenus()
	DO menuPrincipal.mpr
ENDFUNC

FUNCTION AbreTabela(tcArquivo, tcAlias, tlExclusive, tlReadOnly)

	LOCAL lnError, lnOldArea, lcOldError, lnTentativas

	lnOldArea 	= SELECT()
	tcAlias		= IIF(EMPTY(tcAlias), FORCEEXT(JUSTFNAME(tcArquivo),""), tcAlias)
	tcArquivo 	= ALLTRIM(tcArquivo)
	tcArquivo 	= ADDBS(gcPathTabelas) + FORCEEXT(tcArquivo, "dbf")

	IF ! FILE(tcArquivo)
		RETURN .F.
	ENDIF
	
	IF USED(tcAlias)
		RETURN .T.
	ENDIF	
	
	lnTentativas = 0 
	DO WHILE lnTentativas < 6

		lnError = 0

		IF !tlExclusive
			IF tlReadOnly
				USE (tcArquivo) ALIAS (tcAlias) AGAIN SHARED NOUPDATE  IN 0
			ELSE
				USE (tcArquivo) ALIAS (tcAlias) AGAIN SHARED IN 0
			ENDIF
		ELSE
			IF tlReadOnly
				USE (tcArquivo) ALIAS (tcAlias) AGAIN EXCLUSIVE NOUPDATE
			ELSE
				USE (tcArquivo) ALIAS (tcAlias) AGAIN EXCLUSIVE
			ENDIF
		ENDIF

		DO CASE
			CASE !tlReadOnly AND ISREADONLY()
				ERROR 1705
				EXIT
			CASE lnError == 0 OR CHRSAW(0.5)
				EXIT
		ENDCASE

		lnTentativas = lnTentativas + 1
	ENDDO

	IF lnError <> 0
		SELECT (lnOldArea)
		RETURN .F.
	ENDIF

	IF NOT CURSORSETPROP("Buffering", 3, tcAlias)
		USE
		SELECT (lnOldArea)
		RETURN .F.
	ENDIF

	IF NOT EMPTY(TAG(1))
		SET ORDER TO 1
		GO TOP
	ENDIF

	RETURN lnError = 0

ENDFUNC

FUNCTION ExtractXmlTagValue(tcTemplate, tcTag)

	LOCAL lnLenTag, lnStart, lnEnd, lcValue
	
	lnLenTag 	= LEN(tcTag)
	lnStart 	= AT("<" + tcTag + ">", tcTemplate, 1) + lnLenTag + 2
	lnEnd		= AT("</" + tcTag + ">", tcTemplate, 1) - lnStart
	
	lcValue		= SUBSTR(tcTemplate, lnStart, lnEnd)

	RETURN lcValue	
ENDFUNC 



FUNCTION ReleaseToolBars()
	LOCAL i
	LOCAL laToolBars[11,2]
	
	DIMENSION laToolBars[11,2]
	laToolBars[1,1] = TB_FORMDESIGNER_LOC
	laToolBars[2,1] = TB_STANDARD_LOC  
	laToolBars[3,1] = TB_LAYOUT_LOC
	laToolBars[4,1] = TB_QUERY_LOC
	laToolBars[5,1] = TB_VIEWDESIGNER_LOC
	laToolBars[6,1] = TB_COLORPALETTE_LOC  
	laToolBars[7,1] = TB_FORMCONTROLS_LOC
	laToolBars[8,1] = TB_DATADESIGNER_LOC
	laToolBars[9,1] = TB_REPODESIGNER_LOC
	laToolBars[10,1] = TB_REPOCONTROLS_LOC
	laToolBars[11,1] = TB_PRINTPREVIEW_LOC

	FOR i = 1 TO ALEN(laToolBars, 1)
	  laToolBars[i,2] = WVISIBLE(laToolBars[i,1])
	  IF laToolBars[i,2]
	    HIDE WINDOW (laToolBars[i,1])
	  ENDIF
	ENDFOR
ENDFUNC

FUNCTION FecharTodosForms()
	LOCAL loForm

	FOR EACH loForm IN application.Forms
		IF TYPE("loForm") == "O" AND loForm.Baseclass == "Form"
			IF !loForm.QueryUnload()
				RETURN .F.
			ENDIF
			loForm.Release()
		ENDIF
	ENDFOR
ENDFUNC

FUNCTION RetornaObjetoNotaById(tnNota)
	LOCAL lnOldArea, loRegistro
	
	lnOldArea = SELECT()
	
	AbreTabela('NF_ENTRADA')
	
	SELECT * FROM NF_ENTRADA WHERE id = tnNota INTO CURSOR crsNotaByID READWRITE
	SCATTER MEMO NAME loRegistro
	
	SELECT(lnOldArea)
	RETURN loRegistro
ENDFUNC

FUNCTION RetornaObjetoUsuario(tcUsuario)
	LOCAL lnOldArea, loRegistro
	
	lnOldArea = SELECT()
	
	AbreTabela('USUARIOS')
	
	SELECT * FROM USUARIOS WHERE usuario = tcUsuario INTO CURSOR crsUser READWRITE
	SCATTER MEMO NAME loRegistro
	
	SELECT(lnOldArea)
	RETURN loRegistro
ENDFUNC

FUNCTION CriaObjetoComCamposDaTabela(tcTabela)

	LOCAL loObj, lnOldArea
	
	lnOldArea = SELECT()

	AbreTabela(tcTabela)
	SELECT (tcTabela)	

	SCATTER MEMO NAME loObj	BLANK
	SELECT(lnOldArea)	

	RETURN loObj
ENDFUNC 

FUNCTION SalvaDadosObjetoNaTabela(tcTabela, loCampos)	
	LOCAL lnOldArea
	
	lnOldArea = SELECT()	
	AbreTabela(tcTabela)
	SELECT (tcTabela)
	APPEND BLANK
		
	GATHER NAME loCampos MEMO 
	GO TOP 
	SELECT(lnOldArea)	
ENDFUNC

