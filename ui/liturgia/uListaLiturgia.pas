unit uListaLiturgia;

//A lista da liturgia: UM controle, desenhado por nos.
//
//Mesmo desenho do uListaMusicas, de proposito -- as duas listas do programa
//passam a ter a mesma mecanica (rolagem propria, realce sob o mouse, colunas
//de acao fixas, legenda no mouse) e a mesma cara.
//
//O QUE SUBSTITUI. O carregaItemLiturgia CLONA de 8 a 14 componentes por item
//com CopyComponent (TPanel + TbsPngImageView + TbsSkinStdLabel +
//TbsSkinCheckBox) dentro de um TbsSkinScrollBox, e depois acha cada um por
//FindComponent(item + '_bticon_img') -- sao 24 buscas por nome montado. Com
//30 itens na liturgia isso passa de 250 controles, boa parte deles janela.
//
//O que se ganha, alem do porte:
//
//  1. ACABA O "SCAN" DE CIMA PARA BAIXO. O painel de cada item e alTop dentro
//     de um TbsSkinScrollBox, e o AlignControls dele varre TODOS os filhos a
//     cada mexida em Height, Top, Visible ou Margins -- umas cinco vezes por
//     item montado, mais uma por item destruido. Com n itens e quadratico, e
//     era isso que pintava a tela em faixas (secao 4j do CLAUDE.md). La eu
//     tratei com paliativo (DisableAlign + WM_SETREDRAW); aqui o problema
//     deixa de existir, porque nao ha controle por item para realinhar.
//  2. O clique bate com o desenho: cada zona do item sai de uma funcao, e
//     tanto o Paint quanto o teste de clique chamam a MESMA funcao.
//  3. Arrastar para reordenar passa a dizer DE ONDE PARA ONDE. Hoje o item e
//     arrastado solto pela tela e, ao soltar, a ordem nova e deduzida do
//     `Top` de cada painel, ordenando texto montado com FormatFloat. Aqui o
//     controle sabe o indice de origem e o de destino, e so avisa.
//
//A ALTURA DA LINHA E VARIAVEL, e e a unica diferenca estrutural em relacao ao
//uListaMusicas: ali toda linha tem PASSO_ITEM, aqui a divisoria e mais baixa e
//tem um respiro antes dela. Por isso o topo de cada item e PRE-CALCULADO em
//FY/FH no defineItens, em vez de sair de uma multiplicacao.
//
//AS SEIS ACOES SAO AS DO MENU DE MUSICAS. Nao ha enum novo: o TAcaoItem e o
//IconeDaAcao vem do uMenuMusicas e o GlifoDaAcao do uListaMusicas. Conferido
//byte a byte que os lit_modItem_icomus1..6 do .dfm trazem os mesmos seis
//indices nos mesmos Tags.
//
//PORTE PARA O LAZARUS: trocar a clausula uses. Winapi.Windows esta aqui so
//pelos VK_*, Winapi.Messages so pelo CM_MOUSELEAVE e Vcl.Forms so pelo
//Application.CancelHint -- os tres existem iguais no LCL.

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.ImgList, Vcl.Forms, Vcl.ExtCtrls,
  uTema, uBarraRolagem, uMenuMusicas, uListaMusicas, uItensLiturgia;

const
  //Medidas das colunas, da esquerda para a direita. No .dfm de hoje elas sao
  //absolutas dentro do painel do item; aqui ficam nomeadas.
  MARGEM_ESQ   = 8;
  LARG_ALCA    = 26;   //a alca de arrastar (lit_modItem_btmove, icone 81)
  LARG_COR     = 40;   //o quadrado da cor do item, com o icone do tipo
  LARG_CHECK   = 30;
  MARGEM_TEXTO = 10;
  LARG_ACAO    = 34;   //igual a do uListaMusicas, para as duas baterem
  LARG_EDITAR  = 28;   //o lapis (lit_modItem_btedit)
  //Abaixo disto o texto do item nao vale a pena: entra na largura minima.
  LARG_MIN_TEXTO = 150;

  //LARG_BARRA e MIN_POLEGAR saíram para o uBarraRolagem: o menu de músicas
  //desenha a mesma barra, e medida repetida em dois lugares é fazenda de bug.

  //De quanto em quanto o botão da ponta rola, e o ritmo da repetição
  //enquanto ele fica apertado.
  PASSO_BOTAO = 40;
  MS_PRIMEIRA_REPETICAO = 400;
  MS_REPETICAO = 60;

  //A barra na borda esquerda do item que esta sendo reproduzido.
  LARG_BARRA_NO_AR = 3;

  //A marca de "o item entra aqui", no arraste. Grossa de proposito: ela
  //aparece por um instante, com o mouse em movimento, e 2px passavam batido.
  ALTURA_MARCA = 5;

  //Arrastando um item, a lista corre sozinha quando o cursor entra nesta
  //faixa junto da borda de cima ou de baixo. E o que permite levar um item
  //para longe sem soltar no meio do caminho.
  MARGEM_AUTOROLAGEM = 32;
  //Pixels por tique na borda, no maximo. Perto do limite da faixa cai para 1.
  PASSO_AUTOROLAGEM = 14;
  MS_AUTOROLAGEM = 25;

type
  //As zonas clicaveis de um item. Cada uma tem a sua funcao de retangulo, e e
  //a mesma que o desenho usa -- nao ha como divergirem.
  TZonaLit = (zoNada, zoAlca, zoCor, zoCheck, zoCorpo, zoAcao, zoEditar);

  TEventoItemLit = procedure(Sender: TObject; indice: Integer) of object;
  TEventoAcaoLit = procedure(Sender: TObject; indice: Integer;
    acao: TAcaoItem) of object;
  TEventoMarcaLit = procedure(Sender: TObject; indice: Integer;
    marcado: Boolean) of object;
  TEventoMoverLit = procedure(Sender: TObject; de, para: Integer) of object;

  TListaLiturgia = class(TCustomControl)
  private
    FItens: TItensLiturgia;
    //Topo e altura de cada item, pre-calculados: a altura da linha varia.
    FY: array of Integer;
    FH: array of Integer;
    FAlturaTotal: Integer;

    FTopo: Integer;          //rolagem, em pixels
    FIndice: Integer;        //item selecionado, -1 = nenhum
    FItemSob: Integer;
    FZonaSob: TZonaLit;
    FAcaoSob: Integer;       //Ord() da acao sob o mouse, -1 = nenhuma
    FSlots: Integer;         //colunas de acao reservadas na direita
    FNoAr: Integer;          //item sendo reproduzido, -1 = nenhum
    FBloqueado: Boolean;     //cbBloqItens: esconde alca e lapis

    FItemPreso: Integer;
    FZonaPresa: TZonaLit;
    FAcaoPresa: Integer;

    //Arraste da barra de rolagem.
    FRolando: Boolean;
    FRolaY: Integer;
    FRolaTopo: Integer;
    FZonaBarraSob: TZonaBarra;     //zona da barra sob o mouse
    FZonaBarraPresa: TZonaBarra;   //botão da barra que está apertado
    //Temporizador PRÓPRIO, separado do FTimerRolagem: aquele é da
    //auto-rolagem do arraste de item e tem a guarda FMovendo. Um só para os
    //dois significaria um desligar o do outro no meio do caminho.
    FTimerBarra: TTimer;

    //Arraste de reordenacao.
    FMovendo: Boolean;
    FMoveDe: Integer;
    FMoveAlvo: Integer;      //posicao de insercao, 0..Length(FItens)
    //Ultimo Y do cursor no arraste. A auto-rolagem precisa dele porque ela
    //roda por tempo, com o mouse possivelmente parado na borda.
    FMoveY: Integer;
    FTimerRolagem: TTimer;

    FImagens: TCustomImageList;
    FImagens16: TCustomImageList;

    FOnRolou: TNotifyEvent;
    FOnAcao: TEventoAcaoLit;
    FOnAbrirItem: TEventoItemLit;
    FOnEditar: TEventoItemLit;
    FOnCor: TEventoItemLit;
    FOnMarcar: TEventoMarcaLit;
    FOnMover: TEventoMoverLit;
    FOnSelecionar: TEventoItemLit;

    procedure recalcula;
    function topoMaximo: Integer;
    function larguraUtil: Integer;
    procedure poeTopo(v: Integer);
    procedure poeIndice(v: Integer);
    procedure poeNoAr(v: Integer);
    procedure poeBloqueado(v: Boolean);

    function retanguloItem(i: Integer): TRect;
    function itemEm(y: Integer): Integer;
    function larguraEditar: Integer;
    function larguraAlca: Integer;
    function inicioDasAcoes(const r: TRect): Integer;
    function retanguloAlca(const r: TRect): TRect;
    function retanguloCor(const r: TRect): TRect;
    function retanguloCheck(const r: TRect): TRect;
    function retanguloEditar(const r: TRect): TRect;
    function retanguloAcao(const r: TRect; acao: TAcaoItem): TRect;
    function zonaEm(const p: TPoint; out item: Integer;
      out acao: TAcaoItem): TZonaLit;
    //Ponto caiu num slot DESENHADO mas apagado? Serve para o clique nao
    //vazar para o corpo do item, que reproduziria a musica.
    function slotApagadoEm(const p: TPoint; out acao: TAcaoItem): Boolean;
    procedure poeDica(const texto: string);

    function barra: TBarraRolagem;
    procedure aoTicarBarra(Sender: TObject);
    procedure passoDaBarra(zona: TZonaBarra);
    function alvoDeInsercao(y: Integer): Integer;
    function passoDaAutoRolagem(y: Integer): Integer;
    procedure aoTicarAutoRolagem(Sender: TObject);
    procedure cuidaDaAutoRolagem(y: Integer);

    procedure desenhaItem(cv: TCanvas; i: Integer);
    procedure desenhaDivisoria(cv: TCanvas; i: Integer);
    procedure desenhaAlca(cv: TCanvas; const r: TRect;
      fundo: TColor; sob: Boolean);
    procedure desenhaCheck(cv: TCanvas; const r: TRect; marcado, sob: Boolean);
    procedure desenhaMarcaDeInsercao(cv: TCanvas);
    function corDoItem(i: Integer): TColor;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure defineItens(const itens: TItensLiturgia);
    function quantidade: Integer;
    function temBarra: Boolean;
    procedure mostraItem(i: Integer);

    //O ident (nome da secao) do item, que e o que o fmMenu usa para ler e
    //gravar parametro. Devolve '' fora da faixa.
    function identDoItem(i: Integer): string;
    function indiceDoIdent(const ident: string): Integer;
    //Troca o estado de marcado sem remontar a lista inteira.
    procedure marcaItem(i: Integer; marcado: Boolean);
    //O estado de marcado de um item. E ele que a selecao multipla usa:
    //marcar todos, inverter, apagar marcados e copiar marcados liam isto
    //do Checked do TbsSkinCheckBox de cada painel.
    function itemMarcado(i: Integer): Boolean;

    //Ate onde pode encolher antes de deixar de funcionar.
    function larguraMinima: Integer;
    function alturaMinima: Integer;

    property indice: Integer read FIndice write poeIndice;
    //Qual item esta sendo reproduzido agora.
    property noAr: Integer read FNoAr write poeNoAr;
    //cbBloqItens: com os itens bloqueados, a alca e o lapis saem.
    property bloqueado: Boolean read FBloqueado write poeBloqueado;
    property imagens: TCustomImageList read FImagens write FImagens;
    //O lapis de editar e o UNICO icone que vem do ico_16x16.
    property imagens16: TCustomImageList read FImagens16 write FImagens16;

    property OnRolou: TNotifyEvent read FOnRolou write FOnRolou;
    property OnAcao: TEventoAcaoLit read FOnAcao write FOnAcao;
    property OnAbrirItem: TEventoItemLit read FOnAbrirItem write FOnAbrirItem;
    property OnEditar: TEventoItemLit read FOnEditar write FOnEditar;
    property OnCor: TEventoItemLit read FOnCor write FOnCor;
    property OnMarcar: TEventoMarcaLit read FOnMarcar write FOnMarcar;
    //de -> para, em indices da lista. O destino e a posicao de insercao.
    property OnMover: TEventoMoverLit read FOnMover write FOnMover;
    property OnSelecionar: TEventoItemLit read FOnSelecionar
      write FOnSelecionar;
  end;

implementation

{ TListaLiturgia }

constructor TListaLiturgia.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIndice := -1;
  FItemSob := -1;
  FZonaSob := zoNada;
  FAcaoSob := -1;
  FNoAr := -1;
  FItemPreso := -1;
  FZonaPresa := zoNada;
  FAcaoPresa := -1;
  FMoveDe := -1;
  FMoveAlvo := -1;
  FZonaBarraSob := zbNada;
  FZonaBarraPresa := zbNada;
  Cursor := crHandPoint;
  TabStop := True;
  //A legenda muda conforme a zona sob o cursor, entao nao ha Hint fixo. O
  //ParentShowHint vai explicito: o SetShowHint da VCL so o desliga quando o
  //valor MUDA, e depender disso seria depender de implementacao.
  ParentShowHint := False;
  ShowHint := True;
  DoubleBuffered := True;

  //A auto-rolagem roda por TEMPO e nao por movimento do mouse: o caso que
  //ela resolve e justamente segurar o item na borda e esperar a lista
  //correr. So o MouseMove nao daria conta.
  FTimerRolagem := TTimer.Create(Self);
  FTimerRolagem.Enabled := False;
  FTimerRolagem.Interval := MS_AUTOROLAGEM;
  FTimerRolagem.OnTimer := aoTicarAutoRolagem;

  //Segurar o botao da ponta rola sem parar. Sem isto so o clique conta, e
  //atravessar uma liturgia grande sairia a um clique por linha.
  FTimerBarra := TTimer.Create(Self);
  FTimerBarra.Enabled := False;
  FTimerBarra.Interval := MS_PRIMEIRA_REPETICAO;
  FTimerBarra.OnTimer := aoTicarBarra;
end;

procedure TListaLiturgia.recalcula;
var
  i, y: Integer;
begin
  SetLength(FY, Length(FItens));
  SetLength(FH, Length(FItens));

  y := 0;
  for i := 0 to High(FItens) do
  begin
    //O respiro da divisoria era Margins.Top = 20 no painel dela.
    Inc(y, RespiroDoItem(FItens[i].tipo));
    FY[i] := y;
    FH[i] := AlturaDoItem(FItens[i].tipo);
    Inc(y, FH[i] + 1);  //o 1px do separador, que era o Panel3 alBottom
  end;

  FAlturaTotal := y;
end;

procedure TListaLiturgia.defineItens(const itens: TItensLiturgia);
var
  i, topoAntes: Integer;
begin
  //A ROLAGEM E PRESERVADA, e isso importa: este metodo e chamado a cada
  //redesenho da lista -- reordenar, marcar, recolorir e apagar passam por
  //ele --, nao apenas para trocar de dia. Zerar o topo aqui jogava a lista
  //para o inicio depois de soltar um item arrastado.
  topoAntes := FTopo;

  FItens := itens;
  FTopo := 0;
  FIndice := -1;
  FItemSob := -1;
  FZonaSob := zoNada;
  FAcaoSob := -1;
  FNoAr := -1;
  FMovendo := False;
  FMoveDe := -1;
  FMoveAlvo := -1;
  if (FTimerRolagem <> nil) then
    FTimerRolagem.Enabled := False;

  recalcula;

  //Reposto DEPOIS do recalcula, que e quem sabe a altura total nova: lista
  //que encurtou puxa o topo para o limite.
  FTopo := topoAntes;
  if (FTopo > topoMaximo) then
    FTopo := topoMaximo;
  if (FTopo < 0) then
    FTopo := 0;

  //As colunas de acao sao FIXAS: cada acao tem sempre a mesma posicao, e a
  //que nao se aplica fica apagada no lugar dela. Mas reservar seis colunas
  //numa liturgia SEM nenhuma musica seria jogar fora um terco da largura --
  //entao a reserva so existe se algum item usar.
  FSlots := 0;
  for i := 0 to High(FItens) do
    if (FItens[i].possiveis <> []) then
    begin
      FSlots := Ord(High(TAcaoItem)) + 1;
      Break;
    end;

  Invalidate;
end;

function TListaLiturgia.quantidade: Integer;
begin
  Result := Length(FItens);
end;

function TListaLiturgia.identDoItem(i: Integer): string;
begin
  if (i >= 0) and (i <= High(FItens)) then
    Result := FItens[i].ident
  else
    Result := '';
end;

function TListaLiturgia.indiceDoIdent(const ident: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(FItens) do
    if SameText(FItens[i].ident, ident) then
    begin
      Result := i;
      Exit;
    end;
end;

function TListaLiturgia.itemMarcado(i: Integer): Boolean;
begin
  Result := (i >= 0) and (i <= High(FItens)) and FItens[i].marcado;
end;

procedure TListaLiturgia.marcaItem(i: Integer; marcado: Boolean);
begin
  if (i < 0) or (i > High(FItens)) then
    Exit;
  if (FItens[i].marcado = marcado) then
    Exit;
  FItens[i].marcado := marcado;
  Invalidate;
end;

function TListaLiturgia.larguraMinima: Integer;
begin
  //Alca + cor + check + texto legivel + as seis acoes + lapis + barra. As
  //acoes entram sempre: um minimo que variasse com o conteudo deixaria a
  //janela menor do que a proxima liturgia precisa.
  Result := MARGEM_ESQ + LARG_ALCA + LARG_COR + LARG_CHECK + MARGEM_TEXTO +
            LARG_MIN_TEXTO + (Ord(High(TAcaoItem)) + 1) * LARG_ACAO +
            LARG_EDITAR + LARG_BARRA;
end;

function TListaLiturgia.alturaMinima: Integer;
begin
  Result := 3 * (uItensLiturgia.ALTURA_ITEM + 1);
end;

function TListaLiturgia.temBarra: Boolean;
begin
  Result := FAlturaTotal > ClientHeight;
end;

function TListaLiturgia.larguraUtil: Integer;
begin
  Result := ClientWidth;
  if temBarra then
    Dec(Result, LARG_BARRA);
end;

function TListaLiturgia.topoMaximo: Integer;
begin
  Result := FAlturaTotal - ClientHeight;
  if (Result < 0) then
    Result := 0;
end;

procedure TListaLiturgia.poeTopo(v: Integer);
begin
  if (v > topoMaximo) then
    v := topoMaximo;
  if (v < 0) then
    v := 0;
  if (v <> FTopo) then
  begin
    FTopo := v;
    Invalidate;
    if Assigned(FOnRolou) then
      FOnRolou(Self);
  end;
end;

procedure TListaLiturgia.poeIndice(v: Integer);
begin
  if (v < -1) then
    v := -1;
  if (v > High(FItens)) then
    v := High(FItens);
  if (v <> FIndice) then
  begin
    FIndice := v;
    Invalidate;
    if Assigned(FOnSelecionar) and (FIndice >= 0) then
      FOnSelecionar(Self, FIndice);
  end;
end;

procedure TListaLiturgia.poeNoAr(v: Integer);
begin
  if (v < -1) then
    v := -1;
  if (v <> FNoAr) then
  begin
    FNoAr := v;
    Invalidate;
  end;
end;

procedure TListaLiturgia.poeBloqueado(v: Boolean);
begin
  if (v <> FBloqueado) then
  begin
    FBloqueado := v;
    Invalidate;
  end;
end;

function TListaLiturgia.corDoItem(i: Integer): TColor;
begin
  //O INI guarda '$00BBGGRR' ou identificador ('clNavy'). O StringToColor
  //resolve as duas formas, e existe igual no Graphics do LCL.
  try
    Result := StringToColor(FItens[i].cor);
  except
    Result := StringToColor(COR_PADRAO);
  end;
end;

{ geometria }

function TListaLiturgia.retanguloItem(i: Integer): TRect;
begin
  if (i < 0) or (i > High(FItens)) then
  begin
    Result := Rect(0, 0, 0, 0);
    Exit;
  end;
  Result := Rect(0, FY[i] - FTopo, larguraUtil, FY[i] - FTopo + FH[i]);
end;

function TListaLiturgia.itemEm(y: Integer): Integer;
var
  i, abs_: Integer;
begin
  Result := -1;
  abs_ := y + FTopo;
  //Varredura simples: liturgia tem dezenas de itens, nao milhares, e a altura
  //e variavel -- nao da para dividir como no uListaMusicas. O respiro entre
  //um bloco e o anterior nao pertence a item nenhum, e e isso que o teste
  //de faixa devolve.
  for i := 0 to High(FItens) do
    if (abs_ >= FY[i]) and (abs_ < FY[i] + FH[i]) then
    begin
      Result := i;
      Exit;
    end;
end;

function TListaLiturgia.larguraEditar: Integer;
begin
  if FBloqueado then
    Result := 0
  else
    Result := LARG_EDITAR;
end;

function TListaLiturgia.larguraAlca: Integer;
begin
  if FBloqueado then
    Result := 0
  else
    Result := LARG_ALCA;
end;

function TListaLiturgia.inicioDasAcoes(const r: TRect): Integer;
begin
  Result := r.Right - larguraAlca - larguraEditar - FSlots * LARG_ACAO;
end;

//A alca e a ULTIMA coluna da direita, como era no .dfm: o
//lit_modItem_btmove era alRight com Left = 1023, a direita do lapis
//(Left = 996). O lapis fica a esquerda dela.
function TListaLiturgia.retanguloAlca(const r: TRect): TRect;
begin
  if FBloqueado then
    Result := Rect(0, 0, 0, 0)
  else
    Result := Rect(r.Right - LARG_ALCA, r.Top, r.Right, r.Bottom);
end;

function TListaLiturgia.retanguloCor(const r: TRect): TRect;
var
  x: Integer;
begin
  x := r.Left + MARGEM_ESQ;
  Result := Rect(x, r.Top, x + LARG_COR, r.Bottom);
end;

function TListaLiturgia.retanguloCheck(const r: TRect): TRect;
var
  x: Integer;
begin
  x := retanguloCor(r).Right;
  Result := Rect(x, r.Top, x + LARG_CHECK, r.Bottom);
end;

function TListaLiturgia.retanguloEditar(const r: TRect): TRect;
var
  d: Integer;
begin
  if FBloqueado then
  begin
    Result := Rect(0, 0, 0, 0);
    Exit;
  end;
  d := r.Right - LARG_ALCA;
  Result := Rect(d - LARG_EDITAR, r.Top, d, r.Bottom);
end;

function TListaLiturgia.retanguloAcao(const r: TRect; acao: TAcaoItem): TRect;
var
  x: Integer;
begin
  //A coluna da acao e o Ord dela, sempre -- nao depende de quais outras o
  //item tem. E isso que faz o clique bater com o desenho em qualquer linha.
  x := inicioDasAcoes(r) + Ord(acao) * LARG_ACAO;
  Result := Rect(x, r.Top, x + LARG_ACAO, r.Bottom);
end;

function TListaLiturgia.zonaEm(const p: TPoint; out item: Integer;
  out acao: TAcaoItem): TZonaLit;
var
  r: TRect;
  ac: TAcaoItem;
begin
  Result := zoNada;
  acao := acSlideCantado;

  item := itemEm(p.Y);
  if (item < 0) or (p.X >= larguraUtil) then
    Exit;

  r := retanguloItem(item);

  //A divisoria nao tem coluna nenhuma: so a alca, o lapis e o corpo, que e a
  //faixa colorida inteira. Clicar nela abre o seletor de cor, igual a hoje --
  //no .dfm o _bticon dela e alClient com OnClick = PanelColorClick.
  if EhDivisoria(FItens[item].tipo) then
  begin
    if not FBloqueado and PtInRect(retanguloAlca(r), p) then
      Result := zoAlca
    else if not FBloqueado and PtInRect(retanguloEditar(r), p) then
      Result := zoEditar
    else
      Result := zoCor;
    Exit;
  end;

  if not FBloqueado and PtInRect(retanguloAlca(r), p) then
    Result := zoAlca
  else if not FBloqueado and PtInRect(retanguloEditar(r), p) then
    Result := zoEditar
  else if PtInRect(retanguloCor(r), p) then
    Result := zoCor
  else if PtInRect(retanguloCheck(r), p) then
    Result := zoCheck
  else
  begin
    for ac := Low(TAcaoItem) to High(TAcaoItem) do
      if (ac in FItens[item].acoes) and PtInRect(retanguloAcao(r, ac), p) then
      begin
        acao := ac;
        Result := zoAcao;
        Exit;
      end;
    Result := zoCorpo;
  end;
end;

function TListaLiturgia.slotApagadoEm(const p: TPoint;
  out acao: TAcaoItem): Boolean;
var
  item: Integer;
  r: TRect;
  ac: TAcaoItem;
begin
  Result := False;
  acao := acSlideCantado;

  item := itemEm(p.Y);
  if (item < 0) or (p.X >= larguraUtil) then
    Exit;
  if EhDivisoria(FItens[item].tipo) then
    Exit;

  r := retanguloItem(item);
  for ac := Low(TAcaoItem) to High(TAcaoItem) do
    if (ac in FItens[item].possiveis) and not (ac in FItens[item].acoes) and
       PtInRect(retanguloAcao(r, ac), p) then
    begin
      acao := ac;
      Result := True;
      Exit;
    end;
end;

procedure TListaLiturgia.poeDica(const texto: string);
begin
  if (texto = Hint) then
    Exit;
  Hint := texto;
  //A janela de dica que ja esta na tela NAO troca de texto sozinha: foi
  //montada com o texto antigo. Sem cancelar, andar de uma zona para a
  //vizinha mostra a legenda errada.
  Application.CancelHint;
end;

{ barra de rolagem }

//A geometria da barra para o estado de agora. E valor, recalculado a cada
//uso: guardar em campo daria uma copia a mais para manter em dia a cada
//rolagem, redimensionamento ou troca de conteudo.
function TListaLiturgia.barra: TBarraRolagem;
begin
  Result := MontaBarra(ClientWidth, ClientHeight, FAlturaTotal,
                       FTopo, topoMaximo);
end;

procedure TListaLiturgia.passoDaBarra(zona: TZonaBarra);
begin
  case zona of
    zbSobe:         poeTopo(FTopo - PASSO_BOTAO);
    zbDesce:        poeTopo(FTopo + PASSO_BOTAO);
    zbPaginaAcima:  poeTopo(FTopo - ClientHeight);
    zbPaginaAbaixo: poeTopo(FTopo + ClientHeight);
  end;
  Invalidate;
end;

procedure TListaLiturgia.aoTicarBarra(Sender: TObject);
begin
  //O primeiro tique e o mais lento (MS_PRIMEIRA_REPETICAO): da tempo de
  //soltar depois de um clique simples sem a lista disparar.
  FTimerBarra.Interval := MS_REPETICAO;

  if (FZonaBarraPresa = zbNada) then
  begin
    FTimerBarra.Enabled := False;
    Exit;
  end;

  //Chegou na ponta: parar de repetir em vez de girar a toa.
  if ((FZonaBarraPresa = zbSobe) and (FTopo <= 0)) or
     ((FZonaBarraPresa = zbDesce) and (FTopo >= topoMaximo)) then
  begin
    FTimerBarra.Enabled := False;
    Exit;
  end;

  passoDaBarra(FZonaBarraPresa);
end;

{ reordenacao }

function TListaLiturgia.alvoDeInsercao(y: Integer): Integer;
var
  i, abs_, meio: Integer;
begin
  //A posicao de insercao e 0..Length: antes do primeiro, entre dois, ou
  //depois do ultimo. Decide pela METADE do item, que e o que da a sensacao
  //de "vai entrar aqui".
  abs_ := y + FTopo;
  Result := Length(FItens);
  for i := 0 to High(FItens) do
  begin
    meio := FY[i] + (FH[i] div 2);
    if (abs_ < meio) then
    begin
      Result := i;
      Exit;
    end;
  end;
end;

//Para onde a lista deve correr sozinha, com o item preso perto da borda, e a
//que velocidade. Devolve 0 quando nao ha o que rolar.
//
//A velocidade cresce com a profundidade na faixa: encostando na borda ela e
//maxima, e perto do limite da faixa e de 1px por tique. Sem isso, ou a
//rolagem e lenta demais para atravessar uma liturgia grande, ou e rapida
//demais para parar no item certo.
function TListaLiturgia.passoDaAutoRolagem(y: Integer): Integer;
var
  fundo, profundidade: Integer;
begin
  Result := 0;
  if (topoMaximo <= 0) then
    Exit;

  if (y < MARGEM_AUTOROLAGEM) then
  begin
    //Y negativo acontece: com o botao apertado o mouse fica capturado e o
    //controle recebe posicao de fora dele.
    profundidade := MARGEM_AUTOROLAGEM - y;
    if (profundidade > MARGEM_AUTOROLAGEM) then
      profundidade := MARGEM_AUTOROLAGEM;
    if (FTopo > 0) then
      Result := -(1 + (profundidade * PASSO_AUTOROLAGEM) div MARGEM_AUTOROLAGEM);
    Exit;
  end;

  fundo := ClientHeight - MARGEM_AUTOROLAGEM;
  if (y > fundo) then
  begin
    profundidade := y - fundo;
    if (profundidade > MARGEM_AUTOROLAGEM) then
      profundidade := MARGEM_AUTOROLAGEM;
    if (FTopo < topoMaximo) then
      Result := 1 + (profundidade * PASSO_AUTOROLAGEM) div MARGEM_AUTOROLAGEM;
  end;
end;

procedure TListaLiturgia.aoTicarAutoRolagem(Sender: TObject);
var
  passo, antes: Integer;
begin
  if not FMovendo then
  begin
    FTimerRolagem.Enabled := False;
    Exit;
  end;

  passo := passoDaAutoRolagem(FMoveY);
  if (passo = 0) then
  begin
    FTimerRolagem.Enabled := False;
    Exit;
  end;

  antes := FTopo;
  poeTopo(FTopo + passo);
  if (FTopo = antes) then
  begin
    //Chegou na ponta: nao ha mais para onde ir.
    FTimerRolagem.Enabled := False;
    Exit;
  end;

  //O conteudo andou debaixo de um cursor parado, entao o lugar de insercao
  //mudou mesmo sem o mouse mexer.
  FMoveAlvo := alvoDeInsercao(FMoveY);
  Invalidate;
end;

//Liga ou desliga a auto-rolagem conforme onde o cursor esta.
procedure TListaLiturgia.cuidaDaAutoRolagem(y: Integer);
begin
  FMoveY := y;
  FTimerRolagem.Enabled := FMovendo and (passoDaAutoRolagem(y) <> 0);
end;


procedure TListaLiturgia.desenhaMarcaDeInsercao(cv: TCanvas);
var
  y: Integer;
begin
  if (FMoveAlvo < 0) then
    Exit;

  if (FMoveAlvo > High(FItens)) then
    y := FAlturaTotal - FTopo
  else
    y := FY[FMoveAlvo] - FTopo;

  //Nas duas pontas a marca cairia metade fora da area visivel -- e sao
  //justamente as pontas que a auto-rolagem leva o item a visitar.
  if (y < ALTURA_MARCA) then
    y := ALTURA_MARCA;
  if (y > ClientHeight - ALTURA_MARCA) then
    y := ClientHeight - ALTURA_MARCA;

  cv.Brush.Style := bsSolid;
  cv.Brush.Color := COR_ACENTO;
  //O Polygon contorna com a CANETA, nao com o pincel.
  cv.Pen.Style := psClear;
  cv.FillRect(Rect(0, y - (ALTURA_MARCA div 2), larguraUtil,
    y - (ALTURA_MARCA div 2) + ALTURA_MARCA));

  //Dois cantos, para a marca ser lida como "entra aqui" e nao como mais um
  //separador grosso.
  cv.Polygon([Point(0, y - ALTURA_MARCA * 2),
              Point(ALTURA_MARCA * 2, y),
              Point(0, y + ALTURA_MARCA * 2)]);
  cv.Polygon([Point(larguraUtil, y - ALTURA_MARCA * 2),
              Point(larguraUtil - ALTURA_MARCA * 2, y),
              Point(larguraUtil, y + ALTURA_MARCA * 2)]);

  cv.Pen.Style := psSolid;
end;

{ desenho }

//A alca de arrastar: DESENHADA, nao o icone 81 do DM.ico_24x24.
//
//POR QUE NAO O ICONE. Icone de lista de imagens traz as cores dele, escolhidas
//para o fundo que ele tinha no .dfm -- e o `lit_modItem_btmove` era
//`Color = clBlack`. Ou seja: a seta e CLARA, e sobre a linha de um tema claro
//ela simplesmente desaparecia. Os outros icones da tela nao tem esse problema
//porque o fundo deles nao mudou: o do tipo continua sobre a cor do item (era
//`5177344`, o $004F0000) e o lapis e as seis acoes continuam sobre o fundo da
//linha (era o painel do item, `clWhite`).
//
//Desenhando, a cor sai de COR_ACAO, que acompanha o tema -- e o mesmo que foi
//feito com o tique do check, e pelo mesmo motivo.
//
//Duas setas, para cima e para baixo: e o que o icone dizia, e e o que a alca
//faz. Mantido o significado, trocado so o meio de desenhar.
procedure TListaLiturgia.desenhaAlca(cv: TCanvas; const r: TRect;
  fundo: TColor; sob: Boolean);
var
  cx, cy, meia, alt, vao: Integer;
  cor: TColor;
begin
  if (r.Right <= r.Left) then
    Exit;

  if sob then
    cor := COR_ACAO_SOB
  else
    cor := COR_ACAO;

  cx := (r.Left + r.Right) div 2;
  cy := (r.Top + r.Bottom) div 2;
  meia := 5;   //metade da base de cada seta
  alt := 6;    //altura de cada seta
  vao := 3;    //folga entre as duas

  cv.Pen.Style := psClear;
  cv.Brush.Style := bsSolid;
  cv.Brush.Color := cor;

  //Para cima.
  cv.Polygon([Point(cx, cy - vao - alt),
              Point(cx - meia, cy - vao),
              Point(cx + meia, cy - vao)]);

  //Para baixo.
  cv.Polygon([Point(cx, cy + vao + alt),
              Point(cx - meia, cy + vao),
              Point(cx + meia, cy + vao)]);

  cv.Pen.Style := psSolid;
end;

procedure TListaLiturgia.desenhaCheck(cv: TCanvas; const r: TRect;
  marcado, sob: Boolean);
var
  q: TRect;
  lado: Integer;
begin
  //Desenhado aqui, e nao como glifo do uTema: o TGlifo de la e o catalogo do
  //menu de musicas e ja esta anotado como "de passagem" (secao 4k). Cada
  //modulo declara o seu.
  lado := 18;
  q := QuadradoCentral(r, lado);

  cv.Pen.Style := psSolid;
  cv.Pen.Width := 2;
  if marcado then
  begin
    cv.Brush.Style := bsSolid;
    cv.Brush.Color := COR_ACENTO;
    cv.Pen.Color := COR_ACENTO;
  end
  else
  begin
    cv.Brush.Style := bsClear;
    if sob then
      cv.Pen.Color := COR_ACAO_SOB
    else
      cv.Pen.Color := COR_ACAO;
  end;
  cv.RoundRect(q.Left, q.Top, q.Right, q.Bottom, 5, 5);

  if marcado then
  begin
    //O tique: duas linhas, do canto esquerdo ao fundo e do fundo ao topo.
    //Contraste contra o acento, nao a cor do item: a caixa esta preenchida
    //com o acento, e em tema claro ou escuro ele pode ser qualquer um.
    cv.Pen.Color := CorDeTextoSobre(COR_ACENTO);
    cv.MoveTo(q.Left + 4, q.Top + lado div 2);
    cv.LineTo(q.Left + (lado div 2) - 1, q.Bottom - 5);
    cv.LineTo(q.Right - 4, q.Top + 4);
  end;

  cv.Pen.Width := 1;
  cv.Brush.Style := bsSolid;
end;

procedure TListaLiturgia.desenhaDivisoria(cv: TCanvas; i: Integer);
var
  r, rt, rb: TRect;
  cor: TColor;
begin
  r := retanguloItem(i);
  cor := corDoItem(i);

  //A FAIXA COLORIDA NAO PASSA POR BAIXO DA ALCA NEM DO LAPIS, e isso nao e
  //estetica: o lapis e um icone de lista de imagens, desenhado para o fundo
  //claro do painel do item -- era assim no .dfm, onde o `_bticon` colorido
  //era alClient e pegava so o que sobrava depois dos alRight/alLeft. Pondo a
  //cor do bloco por baixo dele, bloco escuro engolia o lapis.
  cv.Brush.Style := bsSolid;
  cv.Brush.Color := COR_ITEM;
  cv.FillRect(r);

  rb := r;
  if not FBloqueado then
    rb.Right := retanguloEditar(r).Left;
  cv.Brush.Color := cor;
  cv.FillRect(rb);

  //O 1px entre dois itens, igual ao do item comum.
  cv.Brush.Color := COR_SEPARADOR;
  cv.FillRect(Rect(r.Left, r.Bottom, r.Right, r.Bottom + 1));

  //Realce de selecao sem perder a cor do bloco: uma barra, nao um
  //preenchimento -- o bloco E a cor dele.
  if (i = FIndice) then
  begin
    cv.Brush.Color := COR_ACENTO;
    cv.FillRect(Rect(r.Left, r.Top, r.Left + LARG_BARRA_NO_AR, r.Bottom));
  end;

  rt := rb;
  if not FBloqueado then
  begin
    desenhaAlca(cv, retanguloAlca(r), COR_ITEM,
      (i = FItemSob) and (FZonaSob = zoAlca));
    DesenhaIcone(cv, retanguloEditar(r), FImagens16, ICONE_EDITAR_16, glNada,
      COR_ACAO, True, COR_ITEM);
  end;

  //A cor do bloco e escolhida pelo USUARIO e pode ser qualquer uma, entao o
  //texto nao segue o tema: ele segue o contraste contra o proprio bloco. O
  //.dfm antigo usava clWhite fixo (UseSkinColor := false), e bloco de cor
  //clara ficava com o nome ilegivel.
  PreparaFonte(cv, 15, True, CorDeTextoSobre(cor));
  DesenhaTexto(cv, rt, FItens[i].titulo, alinCentro);
end;

procedure TListaLiturgia.desenhaItem(cv: TCanvas; i: Integer);
var
  r, rc, ra, rt: TRect;
  ac: TAcaoItem;
  corLinha, corTxt, corFraco, corGlifo, cor: TColor;
  ativa, marcado: Boolean;
  iconeTipo, fimTexto, meio: Integer;
begin
  if EhDivisoria(FItens[i].tipo) then
  begin
    desenhaDivisoria(cv, i);
    Exit;
  end;

  r := retanguloItem(i);
  marcado := FItens[i].marcado;

  if (i = FIndice) then
    corLinha := COR_ITEM_SEL
  else if (i = FItemSob) then
    corLinha := COR_ITEM_SOB
  else if marcado then
    //Item ja realizado: a linha recua para o fundo, em vez de ganhar o azul
    //fixo ($00CED5FF no .dfm) que destoaria de qualquer tema.
    corLinha := Mistura(COR_ITEM, COR_FUNDO, 60)
  else
    corLinha := COR_ITEM;

  cv.Brush.Style := bsSolid;
  cv.Brush.Color := corLinha;
  cv.FillRect(r);

  //O 1px entre dois itens: era o Panel3 alBottom do .dfm.
  cv.Brush.Color := COR_SEPARADOR;
  cv.FillRect(Rect(r.Left, r.Bottom, r.Right, r.Bottom + 1));

  if (i = FIndice) then
  begin
    corTxt := COR_TEXTO_SEL;
    corFraco := Mistura(COR_ITEM_SEL, COR_TEXTO_SEL, 65);
  end
  else if marcado then
  begin
    corTxt := Mistura(corLinha, COR_TEXTO, 55);
    corFraco := Mistura(corLinha, COR_TEXTO, 40);
  end
  else
  begin
    corTxt := COR_TEXTO;
    corFraco := COR_TEXTO_FRACO;
  end;

  //O item que esta no ar ganha uma barra na borda esquerda.
  if (i = FNoAr) then
  begin
    cv.Brush.Color := COR_ACENTO;
    cv.FillRect(Rect(r.Left, r.Top, r.Left + LARG_BARRA_NO_AR, r.Bottom));
  end;

  //A alca de arrastar.
  if not FBloqueado then
    desenhaAlca(cv, retanguloAlca(r), corLinha,
      (i = FItemSob) and (FZonaSob = zoAlca));

  //O quadrado da cor do item, com o icone do tipo em cima. Era o _bticon
  //(TPanel colorido) mais o _bticon_img.
  rc := retanguloCor(r);
  rc := Rect(rc.Left + 2, rc.Top + 6, rc.Right - 2, rc.Bottom - 6);
  cor := corDoItem(i);
  cv.Brush.Style := bsSolid;
  cv.Brush.Color := cor;
  cv.Pen.Style := psClear;
  cv.RoundRect(rc.Left, rc.Top, rc.Right, rc.Bottom, 6, 6);
  cv.Pen.Style := psSolid;

  iconeTipo := IconeDoItem(FItens[i].tipo, FItens[i].subtipo,
    FItens[i].subtitulo);
  if (iconeTipo >= 0) then
    DesenhaIcone(cv, rc, FImagens, iconeTipo, glNada, CorDeTextoSobre(cor),
      True, cor);

  //O check de concluido.
  desenhaCheck(cv, retanguloCheck(r), marcado,
    (i = FItemSob) and (FZonaSob = zoCheck));

  //Titulo e subtitulo, duas linhas como o _texto fazia com o _titulo alTop.
  fimTexto := inicioDasAcoes(r) - MARGEM_TEXTO;
  rt := Rect(retanguloCheck(r).Right + MARGEM_TEXTO, r.Top, fimTexto,
             r.Bottom);
  if (rt.Right > rt.Left) then
  begin
    meio := r.Top + (FH[i] div 2);
    PreparaFonte(cv, 15, True, corTxt, marcado);
    DesenhaTexto(cv, Rect(rt.Left, r.Top + 4, rt.Right, meio + 2),
      FItens[i].titulo, alinEsquerda);

    if (FItens[i].subtitulo <> '') then
    begin
      PreparaFonte(cv, 12, False, corFraco, marcado);
      DesenhaTexto(cv, Rect(rt.Left, meio - 2, rt.Right, r.Bottom - 4),
        FItens[i].subtitulo, alinEsquerda);
    end;
  end;

  //As acoes, cada uma na coluna fixa dela. Percorre as POSSIVEIS: o que nao
  //esta em 'acoes' sai apagado, nao omitido -- coluna vazia nao distingue
  //'esta musica nao tem playback' de 'ninguem usa esta coluna'. E a mesma
  //escolha do menu de musicas; a liturgia antes escondia os dois icones.
  for ac := Low(TAcaoItem) to High(TAcaoItem) do
    if (ac in FItens[i].possiveis) then
    begin
      ra := retanguloAcao(r, ac);
      ativa := (ac in FItens[i].acoes);

      if ativa and (i = FItemSob) and (FZonaSob = zoAcao) and
         (Ord(ac) = FAcaoSob) then
      begin
        cv.Pen.Style := psClear;
        cv.Brush.Style := bsSolid;
        cv.Brush.Color := COR_REALCE;
        cv.RoundRect(ra.Left + 1, ra.Top + 8, ra.Right - 1, ra.Bottom - 8,
          6, 6);
        cv.Pen.Style := psSolid;
        corGlifo := COR_ACAO_SOB;
      end
      else if ativa then
        corGlifo := COR_ACAO
      else
        corGlifo := Mistura(corLinha, COR_ACAO, FORCA_APAGADO);

      DesenhaIcone(cv, ra, FImagens, IconeDaAcao(ac), GlifoDaAcao(ac),
        corGlifo, ativa, corLinha);
    end;

  //O lapis de editar, o unico icone que vem do ico_16x16.
  if not FBloqueado then
  begin
    if (i = FItemSob) and (FZonaSob = zoEditar) then
      corGlifo := COR_ACAO_SOB
    else
      corGlifo := COR_ACAO;
    DesenhaIcone(cv, retanguloEditar(r), FImagens16, ICONE_EDITAR_16, glNada,
      corGlifo, True, corLinha);
  end;
end;

procedure TListaLiturgia.Paint;
var
  i: Integer;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := COR_FUNDO;
  Canvas.FillRect(ClientRect);

  if (Length(FItens) = 0) then
  begin
    PreparaFonte(Canvas, 14, False, COR_TEXTO_FRACO);
    DesenhaTexto(Canvas, ClientRect, 'Nenhum item nesta liturgia',
      alinCentro);
    Exit;
  end;

  //So os itens visiveis. A altura e variavel, entao a faixa sai de teste e
  //nao de divisao.
  for i := 0 to High(FItens) do
    if (FY[i] + FH[i] - FTopo > 0) and (FY[i] - FTopo < ClientHeight) then
      desenhaItem(Canvas, i);

  if FMovendo then
    desenhaMarcaDeInsercao(Canvas);

  DesenhaBarra(Canvas, barra, FZonaBarraSob, FRolando);
end;

{ mouse }

procedure TListaLiturgia.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  it: Integer;
  ac: TAcaoItem;
  z: TZonaLit;
  p: TPoint;
  zb: TZonaBarra;
begin
  inherited;

  if CanFocus then
    SetFocus;

  p := Point(X, Y);

  zb := barra.zonaEm(p);
  if (zb <> zbNada) then
  begin
    if (zb = zbPolegar) then
    begin
      FRolando := True;
      FRolaY := Y;
      FRolaTopo := FTopo;
    end
    else
    begin
      //O passo sai na hora; a repeticao so comeca se o botao continuar
      //apertado depois da primeira espera.
      FZonaBarraPresa := zb;
      passoDaBarra(zb);
      FTimerBarra.Interval := MS_PRIMEIRA_REPETICAO;
      FTimerBarra.Enabled := True;
    end;
    Invalidate;
    Exit;
  end;

  if (Button <> mbLeft) then
    Exit;

  //Slot apagado nao e botao: o clique morre aqui, em vez de escorregar para o
  //corpo do item e reproduzir a musica.
  if slotApagadoEm(p, ac) then
  begin
    FItemPreso := -1;
    FZonaPresa := zoNada;
    Exit;
  end;

  z := zonaEm(p, it, ac);
  FItemPreso := it;
  FZonaPresa := z;
  if (z = zoAcao) then
    FAcaoPresa := Ord(ac)
  else
    FAcaoPresa := -1;

  //Arrastar para reordenar comeca na alca, como hoje.
  if (z = zoAlca) and (it >= 0) then
  begin
    FMovendo := True;
    FMoveDe := it;
    FMoveAlvo := -1;
    FMoveY := Y;
  end;

  if (it >= 0) then
    poeIndice(it);
end;

procedure TListaLiturgia.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  it, novaAcao, alvo: Integer;
  ac, acApagada: TAcaoItem;
  z: TZonaLit;
  b: TBarraRolagem;
  novaZonaBarra: TZonaBarra;
  apagado: Boolean;
begin
  inherited;

  b := barra;

  if FRolando then
  begin
    poeTopo(b.topoDoArraste(Y, FRolaY, FRolaTopo, topoMaximo));
    Exit;
  end;

  if FMovendo then
  begin
    cuidaDaAutoRolagem(Y);
    alvo := alvoDeInsercao(Y);
    if (alvo <> FMoveAlvo) then
    begin
      FMoveAlvo := alvo;
      Invalidate;
    end;
    Exit;
  end;

  //Só o realce dos dois botões e do polegar interessa: trilho não acende.
  novaZonaBarra := b.zonaEm(Point(X, Y));
  if not (novaZonaBarra in [zbSobe, zbDesce, zbPolegar]) then
    novaZonaBarra := zbNada;

  z := zonaEm(Point(X, Y), it, ac);
  if (z = zoAcao) then
    novaAcao := Ord(ac)
  else
    novaAcao := -1;

  apagado := slotApagadoEm(Point(X, Y), acApagada);

  //A mao e o aviso de "da para clicar". Sobre slot apagado ela sai.
  if apagado then
  begin
    if (Cursor <> crArrow) then
      Cursor := crArrow;
  end
  else if (Cursor <> crHandPoint) then
    Cursor := crHandPoint;

  //A legenda. Sobre o corpo do item nao ha dica: o nome ja esta escrito ali.
  if (z = zoAcao) then
    poeDica(NomeDaAcao(ac))
  else if apagado then
    poeDica(NomeDaAcaoApagada(acApagada))
  else if (z = zoAlca) then
    poeDica('Arraste para mudar a ordem')
  else if (z = zoEditar) then
    poeDica('Alterar este item')
  else if (z = zoCheck) then
    poeDica('Marcar como realizado')
  else if (z = zoCor) then
    poeDica('Escolher a cor')
  else
    poeDica('');

  if (it <> FItemSob) or (z <> FZonaSob) or (novaAcao <> FAcaoSob) or
     (novaZonaBarra <> FZonaBarraSob) then
  begin
    FItemSob := it;
    FZonaSob := z;
    FAcaoSob := novaAcao;
    FZonaBarraSob := novaZonaBarra;
    Invalidate;
  end;
end;

procedure TListaLiturgia.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  it, alvo: Integer;
  ac: TAcaoItem;
  z: TZonaLit;
  mesmoAlvo: Boolean;
begin
  //Soltar o botao sempre encerra a repeticao da barra, venha de onde vier.
  FTimerBarra.Enabled := False;
  FZonaBarraPresa := zbNada;

  if FRolando then
  begin
    FRolando := False;
    Invalidate;
    inherited;
    Exit;
  end;

  if FMovendo then
  begin
    FTimerRolagem.Enabled := False;
    alvo := FMoveAlvo;
    FMovendo := False;
    FMoveAlvo := -1;
    Invalidate;

    //Soltar no mesmo lugar nao e mover: alvo igual ao indice, ou um depois
    //dele, deixa a lista como estava.
    if (alvo >= 0) and (FMoveDe >= 0) and (alvo <> FMoveDe) and
       (alvo <> FMoveDe + 1) and Assigned(FOnMover) then
      FOnMover(Self, FMoveDe, alvo);

    FMoveDe := -1;
    FItemPreso := -1;
    FZonaPresa := zoNada;
    inherited;
    Exit;
  end;

  if (Button = mbLeft) and (FItemPreso >= 0) then
  begin
    z := zonaEm(Point(X, Y), it, ac);
    mesmoAlvo := (it = FItemPreso) and (z = FZonaPresa);
    if mesmoAlvo and (z = zoAcao) then
      mesmoAlvo := (Ord(ac) = FAcaoPresa);

    if mesmoAlvo then
      case z of
        zoAcao:
          if Assigned(FOnAcao) then
            FOnAcao(Self, it, ac);
        zoEditar:
          if Assigned(FOnEditar) then
            FOnEditar(Self, it);
        zoCor:
          if Assigned(FOnCor) then
            FOnCor(Self, it);
        zoCheck:
          begin
            FItens[it].marcado := not FItens[it].marcado;
            Invalidate;
            if Assigned(FOnMarcar) then
              FOnMarcar(Self, it, FItens[it].marcado);
          end;
        zoCorpo:
          if Assigned(FOnAbrirItem) then
            FOnAbrirItem(Self, it);
      end;
  end;

  FItemPreso := -1;
  FZonaPresa := zoNada;
  FAcaoPresa := -1;
  inherited;
end;

procedure TListaLiturgia.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  poeDica('');
  if (FItemSob <> -1) or (FZonaSob <> zoNada) or
     (FZonaBarraSob <> zbNada) then
  begin
    FItemSob := -1;
    FZonaSob := zoNada;
    FAcaoSob := -1;
    FZonaBarraSob := zbNada;
    Invalidate;
  end;
end;

function TListaLiturgia.DoMouseWheel(Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  //A altura varia, entao o tique rola por uma medida fixa em vez de "um
  //item" -- com itens de alturas diferentes, um item por tique daria
  //velocidade irregular.
  poeTopo(FTopo - Round(WheelDelta / 120) * (uItensLiturgia.ALTURA_ITEM + 1));
  Result := True;
end;

procedure TListaLiturgia.mostraItem(i: Integer);
begin
  if (i < 0) or (i > High(FItens)) then
    Exit;
  if (FY[i] < FTopo) then
    poeTopo(FY[i] - RespiroDoItem(FItens[i].tipo))
  else if (FY[i] + FH[i] > FTopo + ClientHeight) then
    poeTopo(FY[i] + FH[i] - ClientHeight);
end;

procedure TListaLiturgia.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;

  //OnKeyDown e nao OnKeyUp: o KeyDown repete enquanto a tecla fica
  //pressionada, e navegacao em lista precisa disso (CLAUDE.md, secao 3).
  case Key of
    VK_UP:
      begin
        poeIndice(Max(0, FIndice - 1));
        mostraItem(FIndice);
        Key := 0;
      end;
    VK_DOWN:
      begin
        if (FIndice < 0) then
          poeIndice(0)
        else
          poeIndice(FIndice + 1);
        mostraItem(FIndice);
        Key := 0;
      end;
    //PgUp/PgDn de proposito NAO entram: no LouvorJA elas sao do passador de
    //slides, e o fmMenu.FormKeyUp as leva para fMusica.acaoSlide mesmo com
    //esta aba na frente.
    VK_HOME:
      begin
        poeIndice(0);
        mostraItem(0);
        Key := 0;
      end;
    VK_END:
      begin
        poeIndice(High(FItens));
        mostraItem(FIndice);
        Key := 0;
      end;
    VK_RETURN:
      begin
        if (FIndice >= 0) and Assigned(FOnAbrirItem) then
          FOnAbrirItem(Self, FIndice);
        Key := 0;
      end;
  end;
end;

procedure TListaLiturgia.Resize;
begin
  inherited;
  //Encolher pode deixar o topo acima do maximo.
  poeTopo(FTopo);
  Invalidate;
end;

end.
