*-----------------------------------------------------------------*
*  Programa    : LibRegras.prg                           		  *
*  Finalidade  : Programa com fun??es contendo regras de neg?cio  *
*  Programador : Oziel                                   		  *
*-----------------------------------------------------------------*

FUNCTION RevisaStatusNotaEntrada(tnIdNota)
	
	LOCAL lnOldArea, lnReqVistos, lnRepAprova, lnQtVistos, lnQtAprova, loNota
	
	lnOldArea = SELECT()
	loNota = RetornaObjetoNotaById(tnIdNota)
	
	IF EMPTY(loNota.id) OR loNota.Status = 'A'
		RETURN
	ENDIF		
		
	lnReqVistos	= GetRequisito(loNota.VlrTotal,'V')
	lnRepAprova	= GetRequisito(loNota.VlrTotal,'A')
	lnQtVistos	= GetQuantOperacoesNota(tnIdNota, 'V')
	lnQtAprova	= GetQuantOperacoesNota(tnIdNota, 'A')
		
	IF lnQtVistos >= lnReqVistos AND lnQtAprova >= lnRepAprova
		GravaStatusNota(tnIdNota, 'A')
	ENDIF
	
	SELECT(lnOldArea)
ENDFUNC

FUNCTION GravaStatusNota(tnIdNota, tcStatus)
	AbreTabela('NF_ENTRADA')
	
	SELECT NF_ENTRADA
	LOCATE FOR id = tnIdNota
	IF FOUND()
		replace status WITH tcStatus IN NF_ENTRADA
		GO TOP 
	ENDIF
ENDFUNC


FUNCTION GetRequisito(tnValor, tcStatus)
	
	AbreTabela('FAIXAS_NFE')

	SELECT TOP 1 * FROM FAIXAS_NFE WHERE BETWEEN(tnValor, valorMin, ValorMax) ;
		ORDER BY 1 INTO CURSOR crsFaixa READWRITE
	
	IF tcStatus = 'V'
		RETURN crsFaixa.Vistos
	ELSE
		RETURN crsFaixa.Aprovacoes
	ENDIF
	
ENDFUNC

FUNCTION GetQuantOperacoesNota(tnIdNota, tcOperacao)
	AbreTabela('APROVA_NFE')
	USE IN SELECT('crsOperacoes')
	SELECT COUNT(nota) as qt FROM APROVA_NFE WHERE Nota =  tnIdNota AND operacao = tcOperacao ;
		INTO CURSOR crsOperacoes READWRITE
	
	RETURN crsOperacoes.Qt
ENDFUNC


FUNCTION ConsultarNotasPendentes(tdDataI, tdDataF, tcUsuario)
	LOCAL loUsuario, lxTeste
	
	loUsuario = RetornaObjetoUsuario(tcUsuario)
	AbreTabela('NF_ENTRADA')

	SELECT * FROM NF_ENTRADA WHERE BETWEEN(dtEmissao, tdDataI, tdDataF) AND ;
		BETWEEN(vlrTotal, loUsuario.ValorMin, loUsuario.ValorMax) AND STATUS <> 'A' ;
		ORDER BY dtEmissao, Id INTO CURSOR crsNotas READWRITE
	
	DELETE ALL FOR UsuarioJaTemLiberacaoParaEstaNota(crsNotas.Id, tcUsuario)
	DELETE ALL FOR !UsuarioPodeLiberarNota(crsNotas.VlrTotal, crsNotas.Id, loUsuario.Papel)

	SELECT * FROM crsNotas INTO CURSOR crsNotas READWRITE
	
ENDFUNC

FUNCTION UsuarioPodeLiberarNota(tnValorTotal, tnIdNota, tcOperacao)
	LOCAL lnRequisitados, lnOperacoes
	
	lnRequisitados	= GetRequisito(tnValorTotal, tcOperacao)
	lnOperacoes		= GetQuantOperacoesNota(tnIdNota, tcOperacao)
	
	IF lnRequisitados > lnOperacoes
		RETURN .T.
	ENDIF

	RETURN .F.	
ENDFUNC


FUNCTION UsuarioJaTemLiberacaoParaEstaNota(tnIdNota, tcUsuario)
	LOCAL lnOldArea
	
	lnOldArea = SELECT()
	AbreTabela('APROVA_NFE')	

	SELECT COUNT(nota) as qt FROM APROVA_NFE WHERE Nota =  tnIdNota AND usuario = tcUsuario ;
		INTO CURSOR crsOperaUsu READWRITE
	
	SELECT(lnOldArea)

	RETURN (crsOperaUsu.qt > 0)
ENDFUNC


FUNCTION RegistraOperacaoNotaFiscalEntrada(tnIdNota, tcUsuario, tcOperacao)
	
	LOCAL lnOldArea, loAprovacao
	
	lnOldArea = SELECT()
	
	AbreTabela('NF_ENTRADA')
	AbreTabela('APROVA_NFE')
	
	loAprovacao = CriaObjetoComCamposDaTabela('APROVA_NFE')
	loAprovacao.Nota		= tnIdNota
	loAprovacao.Usuario		= tcUsuario
	loAprovacao.Operacao	= tcOperacao
	loAprovacao.Data		= DATE()	
	
	SalvaDadosObjetoNaTabela('APROVA_NFE', loAprovacao)	
	
	SELECT(lnOldArea)
	
	RETURN .T.

ENDFUNC




