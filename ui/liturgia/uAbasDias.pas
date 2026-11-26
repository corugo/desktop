unit uAbasDias;

//A FAIXA DE DIAS DA LITURGIA -- um controle desenhado, com uma celula por dia.
//
//Substitui o GridPanel23 do fmMenu.dfm, que eram 8 TbsSkinSpeedButton mais 7
//TbsRibbonDivider num TGridPanel de 17 colunas (as impares percentuais, as
//pares absolutas de 10px). O realce do dia escolhido era o Down dos botoes,
//ligado por FindComponent('lcal_' + numero) -- nome montado em string.
//
//NAO sao N TBotaoChato: ele reserva 32px para o icone e alinha o texto a
//esquerda, e aqui o conjunto icone+texto e centrado na celula. Um controle
//desenhado tambem resolve de graca o realce do dia ativo e a divisao exata da
//largura, que no TGridPanel exigia os percentuais somarem 100.
//
//Veio da POC do widget flutuante (scratchpad/widget-guardado), onde nasceu
//para guias de uma letra so. Aceita texto de qualquer tamanho, e por isso
//serve a faixa inteira sem alteracao.
//
//PORTE PARA O LAZARUS (regra 5b do CLAUDE.md): trocar a clausula uses.
//CM_MOUSELEAVE existe igual nos dois frameworks.

interface

uses
  System.Classes, System.Types, Vcl.Controls, Vcl.Graphics, Vcl.ImgList,
  Winapi.Messages,
  uTema;

const
  //A marca do dia ativo, na borda de baixo da celula.
  ALT_MARCA_ABA = 4;

  //A fonte das guias. Mesma altura do texto do item da lista.
  ALTURA_FONTE_ABA = 13;

  //O icone e o espaco ate o texto. 24 porque a lista e a DM.ico_24x24, e o
  //DesenhaIcone NAO redimensiona (armadilha da secao 4o): a imagem sai no
  //tamanho nativo da lista, entao reservar menos so faria ela transbordar.
  LARG_ICONE_ABA = 24;
  GAP_ICONE_ABA = 6;

  //Altura sugerida da faixa: o icone mais o respiro e a marca. Quem monta usa
  //esta constante em vez de um numero solto, para a conta andar junto se o
  //icone mudar de tamanho.
  ALT_ABAS_DIAS = LARG_ICONE_ABA + 6 + ALT_MARCA_ABA;

type
  TEventoDia = procedure(Sender: TObject; dia: Integer) of object;

  TAbasDias = class(TCustomControl)
  private
    FTextos: array of string;
    FDias: array of Integer;
    FIcones: array of Integer;
    FImagens: TCustomImageList;
    FAtivo: Integer;
    FSob: Integer;
    FOnEscolher: TEventoDia;
    procedure poeAtivo(v: Integer);
    procedure poeImagens(v: TCustomImageList);
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    //protected e nao private para o teste em console poder medir a geometria
    //por uma descendente, como o TAcessoAlinhamento do fmMenu ja faz. Replicar
    //a conta no teste seria o espelho que erra antes do codigo.
    function celulaEm(x: Integer): Integer;
    function retanguloCelula(i: Integer): TRect;
    function iconeDaCelula(i: Integer): Integer;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    //icones pode vir vazio ou mais curto que os dias: celula sem icone
    //desenha so o texto, centrado.
    procedure defineDias(const textos: array of string;
      const dias: array of Integer; const icones: array of Integer);
    //O DIA, nao o indice da celula: quem chama fala em numero de dia.
    property ativo: Integer read FAtivo write poeAtivo;
    property imagens: TCustomImageList read FImagens write poeImagens;
    property OnEscolher: TEventoDia read FOnEscolher write FOnEscolher;
  end;

implementation

constructor TAbasDias.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAtivo := -1;
  FSob := -1;
  Cursor := crHandPoint;
  DoubleBuffered := True;
end;

procedure TAbasDias.defineDias(const textos: array of string;
  const dias: array of Integer; const icones: array of Integer);
var
  i: Integer;
begin
  SetLength(FTextos, Length(textos));
  SetLength(FDias, Length(dias));
  SetLength(FIcones, Length(icones));
  for i := 0 to High(textos) do
    FTextos[i] := textos[i];
  for i := 0 to High(dias) do
    FDias[i] := dias[i];
  for i := 0 to High(icones) do
    FIcones[i] := icones[i];
  Invalidate;
end;

procedure TAbasDias.poeAtivo(v: Integer);
begin
  if (v <> FAtivo) then
  begin
    FAtivo := v;
    Invalidate;
  end;
end;

procedure TAbasDias.poeImagens(v: TCustomImageList);
begin
  if (v <> FImagens) then
  begin
    FImagens := v;
    Invalidate;
  end;
end;

function TAbasDias.retanguloCelula(i: Integer): TRect;
var
  n, x1, x2: Integer;
begin
  n := Length(FTextos);
  if (n <= 0) or (i < 0) or (i >= n) then
  begin
    Result := Rect(0, 0, 0, 0);
    Exit;
  end;
  //Divisao proporcional, e nao largura fixa: assim a ultima celula termina
  //exatamente na borda, sem sobra de 1 ou 2px.
  x1 := (ClientWidth * i) div n;
  x2 := (ClientWidth * (i + 1)) div n;
  Result := Rect(x1, 0, x2, ClientHeight);
end;

//O indice do icone da celula, ou -1 quando ela nao tem. Centraliza as tres
//condicoes (sem lista, fora do array, indice negativo) num lugar so, porque o
//desenho e a medida da largura precisam concordar sobre isso.
function TAbasDias.iconeDaCelula(i: Integer): Integer;
begin
  Result := -1;
  if (FImagens = nil) or (i < 0) or (i > High(FIcones)) then
    Exit;
  if (FIcones[i] >= 0) then
    Result := FIcones[i];
end;

function TAbasDias.celulaEm(x: Integer): Integer;
var
  i: Integer;
  r: TRect;
begin
  Result := -1;
  for i := 0 to High(FTextos) do
  begin
    r := retanguloCelula(i);
    if (x >= r.Left) and (x < r.Right) then
    begin
      Result := i;
      Exit;
    end;
  end;
end;

procedure TAbasDias.Paint;
var
  i, ico, largTexto, largTotal, x, yIcone, baseConteudo: Integer;
  r: TRect;
  ehAtivo: Boolean;
  corTxt, fundoCelula: TColor;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := COR_ITEM;
  Canvas.FillRect(ClientRect);

  for i := 0 to High(FTextos) do
  begin
    r := retanguloCelula(i);
    ehAtivo := (i <= High(FDias)) and (FDias[i] = FAtivo);

    //O ATIVO NAO E PINTADO COM A COR DE ACENTO, diferente das outras listas
    //deste projeto. Os icones vem do DM.ico_24x24 e carregam a cor deles (a
    //armadilha da secao 4k): o calendario azul do Sabado sobre o acento azul
    //sumiria, e o cinza dos dias comuns ficaria sujo. Aqui o ativo e dito pelo
    //negrito e pela marca embaixo -- que e o idioma de uma faixa de guias de
    //qualquer forma, e deixa todo icone sobre a cor para a qual foi desenhado.
    fundoCelula := COR_ITEM;
    corTxt := COR_TEXTO_FRACO;
    if ehAtivo then
      corTxt := COR_TEXTO
    else if (i = FSob) then
    begin
      fundoCelula := COR_REALCE;
      Canvas.Brush.Color := fundoCelula;
      Canvas.FillRect(r);
      corTxt := COR_TEXTO;
    end;

    //A area util e tudo menos a faixa da marca, para o conteudo nao ficar
    //centrado em cima dela.
    baseConteudo := r.Bottom - ALT_MARCA_ABA;

    PreparaFonte(Canvas, ALTURA_FONTE_ABA, ehAtivo, corTxt);
    largTexto := Canvas.TextWidth(FTextos[i]);

    ico := iconeDaCelula(i);
    largTotal := largTexto;
    if (ico >= 0) then
      Inc(largTotal, LARG_ICONE_ABA + GAP_ICONE_ABA);

    //O conjunto icone+texto e que e centrado, nao cada um por si.
    x := r.Left + (((r.Right - r.Left) - largTotal) div 2);
    if (x < r.Left) then
      x := r.Left;

    if (ico >= 0) then
    begin
      yIcone := r.Top + (((baseConteudo - r.Top) - LARG_ICONE_ABA) div 2);
      DesenhaIcone(Canvas, Rect(x, yIcone, x + LARG_ICONE_ABA,
        yIcone + LARG_ICONE_ABA), FImagens, ico, glNada, corTxt, True,
        fundoCelula);
      Inc(x, LARG_ICONE_ABA + GAP_ICONE_ABA);
      //De novo porque o DesenhaIcone mexe no Canvas.
      PreparaFonte(Canvas, ALTURA_FONTE_ABA, ehAtivo, corTxt);
    end;

    DesenhaTexto(Canvas, Rect(x, r.Top, r.Right, baseConteudo), FTextos[i],
      alinEsquerda);

    if ehAtivo then
    begin
      Canvas.Brush.Color := COR_ACENTO;
      Canvas.FillRect(Rect(r.Left, baseConteudo, r.Right, r.Bottom));
    end;
  end;

  //A linha que separa as guias da lista. Depois da marca de proposito: ela nao
  //pode cortar o acento do dia ativo.
  Canvas.Brush.Color := COR_SEPARADOR;
  Canvas.FillRect(Rect(0, ClientHeight - 1, ClientWidth, ClientHeight));
end;

procedure TAbasDias.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  i: Integer;
begin
  inherited;
  if (Button <> mbLeft) then
    Exit;

  i := celulaEm(X);
  if (i < 0) or (i > High(FDias)) then
    Exit;

  //Avisa mesmo que seja o dia ja ativo: recarregar o dia corrente e um jeito
  //legitimo de atualizar a lista, e era o que o botao Down tambem fazia.
  if Assigned(FOnEscolher) then
    FOnEscolher(Self, FDias[i]);
end;

procedure TAbasDias.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
begin
  inherited;
  i := celulaEm(X);
  if (i <> FSob) then
  begin
    FSob := i;
    Invalidate;
  end;
end;

procedure TAbasDias.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if (FSob <> -1) then
  begin
    FSob := -1;
    Invalidate;
  end;
end;

end.