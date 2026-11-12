unit uListaMusicas;

//A lista do menu de musicas: UM controle, desenhado por nos.
//
//Substitui o conjunto TDBCtrlGrid + TGridPanel + 6 TbsPngImageView +
//2 TbsSkinDBText + 3 TPanel que o fmListaMusica usa hoje. O TDBCtrlGrid NAO
//EXISTE no LCL e nao tem equivalente (regra 5b do CLAUDE.md), entao ele teria
//de sair de qualquer forma no porte. Este controle e o que entra no lugar.
//
//O que se ganha, alem do porte:
//
//  1. O clique bate com o desenho. Hoje os botoes do item sao um jogo UNICO
//     que o grid reconfigura por linha, e o fmListaMusica precisa de um gancho
//     no WM_PAINT (gridWindowProc + restauraLinhaAtiva) para a linha ativa nao
//     ficar com o layout da ultima linha desenhada. Era isso que deslocava o
//     clique em 40px e o fazia cair no botao vizinho. Aqui o retangulo de cada
//     acao sai de retanguloAcao, e tanto o desenho quanto o teste de clique
//     chamam a MESMA funcao: nao ha como divergirem.
//  2. Nao cria janela por item. Sao 600 hinos em algumas coletaneas.
//  3. Desenha so o que aparece.
//
//PORTE PARA O LAZARUS: trocar a clausula uses. Winapi.Windows esta aqui so
//pelos VK_* (no LCL eles vem do LCLType, com os mesmos nomes) e
//Winapi.Messages so pelo CM_MOUSELEAVE. Vcl.Forms entra apenas pelo
//Application.CancelHint, que existe igual no LCL.

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.ImgList, Vcl.Forms,
  uTema, uMenuMusicas;

const
  //Medidas tiradas do fmListaMusica.dfm atual. CUIDADO: o PanelHeight = 66
  //gravado la NAO era a altura em execucao -- o TDBCtrlGrid recalcula como
  //(altura - rolagem) div RowCount, e com RowCount := ClientHeight / 40 a
  //linha real era de ~40px (secao 3 do CLAUDE.md). O
  //Panel3 de 1px no alBottom, e as colunas absolutas do GridPanel2
  //(50 / 30 / resto / 40 x 6).
  //A linha era de 66px (o PanelHeight do DBCtrlGrid). Em 44 cabem 4 musicas a
  //mais numa janela de 500px, e o icone de 24px continua folgado.
  ALTURA_ITEM = 44;
  ALTURA_SEP = 1;
  PASSO_ITEM = ALTURA_ITEM + ALTURA_SEP;
  //A coluna de icone de 50px saiu: ela desenhava o MESMO icone em todas as
  //linhas, entao nao informava nada e custava um sexto da largura util.
  MARGEM_ESQ = 10;
  LARG_FAIXA = 32;
  LARG_ACAO = 34;
  MARGEM_NOME = 12;
  //Nome mais curto que isto nao vale a pena mostrar: entra na conta da
  //largura minima da janela.
  LARG_MIN_NOME = 130;

  LARG_BARRA = 10;
  MIN_POLEGAR = 32;

  //Os indices dos icones das acoes mudaram para o uMenuMusicas: a liturgia
  //desenha a mesma faixa de seis, e indice repetido em dois lugares e
  //fazenda de bug. O ICONE_ITEM nao foi com eles porque nao e acao -- e
  //estava morto, sem nenhum uso, desde a primeira versao desta unit.

type
  TEventoAcao = procedure(Sender: TObject; indice: Integer;
    acao: TAcaoItem) of object;
  TEventoItem = procedure(Sender: TObject; indice: Integer) of object;

  TListaMusicas = class(TCustomControl)
  private
    FItens: TItensMenu;
    FTopo: Integer;           //rolagem, em pixels
    FIndice: Integer;         //item selecionado, -1 = nenhum
    FItemSob: Integer;        //item sob o mouse
    FAcaoSob: Integer;        //Ord() da acao sob o mouse, -1 = nenhuma
    FSlots: Integer;          //colunas de acao reservadas na direita
    FProjetando: Integer;     //item que esta sendo projetado, -1 = nenhum
    FItemPreso: Integer;      //onde o botao do mouse foi apertado
    FAcaoPresa: Integer;
    FArrastando: Boolean;
    FArrasteY: Integer;
    FArrasteTopo: Integer;
    FPolegarSob: Boolean;
    FImagens: TCustomImageList;
    FOnRolou: TNotifyEvent;
    FOnAcao: TEventoAcao;
    FOnAbrirItem: TEventoItem;
    FOnSelecionar: TEventoItem;
    function alturaTotal: Integer;
    function topoMaximo: Integer;
    function larguraUtil: Integer;
    procedure poeTopo(v: Integer);
    procedure poeIndice(v: Integer);
    function retanguloItem(i: Integer): TRect;
    function itemEm(y: Integer): Integer;
    function retanguloAcao(i: Integer; acao: TAcaoItem): TRect;
    function inicioDasAcoes(const r: TRect): Integer;
    //Ponto caiu num slot DESENHADO mas apagado? Serve para o clique nao
    //vazar para o corpo do item, que abriria a musica.
    function slotApagadoEm(const p: TPoint; out acao: TAcaoItem): Boolean;
    //Troca a legenda conforme o que esta sob o cursor.
    procedure poeDica(const texto: string);
    function acaoEm(const p: TPoint; out item, slot: Integer;
      out acao: TAcaoItem): Boolean;
    function alturaPolegar: Integer;
    function retanguloPolegar: TRect;
    procedure desenhaItem(cv: TCanvas; i: Integer);
    procedure desenhaBarra(cv: TCanvas);
    procedure poeProjetando(v: Integer);
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
    procedure defineItens(const itens: TItensMenu);
    function quantidade: Integer;
    function temBarra: Boolean;
    procedure mostraItem(i: Integer);
    function primeiroVisivel: Integer;

    //Até onde a lista pode encolher antes de deixar de funcionar: abaixo
    //disso a coluna do nome some atrás das ações, que têm largura fixa.
    //Quem conhece essas medidas é este controle, não o form.
    function larguraMinima: Integer;
    function alturaMinima: Integer;
    //A posicao do item no dataset. NAO e o indice na tela: a lista pode estar
    //filtrada pela busca, e ai os dois divergem.
    function posDoItem(i: Integer): Integer;
    property indice: Integer read FIndice write poeIndice;
    //Qual item esta no ar agora. Desenhado com barra de destaque, para o
    //operador saber de onde veio o que o povo esta vendo.
    property projetando: Integer read FProjetando write poeProjetando;
    //Os icones de verdade (DM.ico_24x24). Sem lista, valem os glifos.
    property imagens: TCustomImageList read FImagens write FImagens;
    //Disparado quando a rolagem muda: serve para quem precisa acompanhar o
    //primeiro item visivel, como o dataset que alimenta a tela projetada.
    property OnRolou: TNotifyEvent read FOnRolou write FOnRolou;
    property OnAcao: TEventoAcao read FOnAcao write FOnAcao;
    property OnAbrirItem: TEventoItem read FOnAbrirItem write FOnAbrirItem;
    property OnSelecionar: TEventoItem read FOnSelecionar write FOnSelecionar;
  end;

//Qual glifo e qual icone desenham cada acao. Ficam aqui e nao no uMenuMusicas
//porque aquela unit e pura e nao conhece nem o tema nem a lista de imagens.
function GlifoDaAcao(acao: TAcaoItem): TGlifo;

implementation

function GlifoDaAcao(acao: TAcaoItem): TGlifo;
begin
  case acao of
    acSlideCantado: Result := glSlideCantado;
    acSlidePlayback: Result := glSlidePlayback;
    acSlideSemAudio: Result := glSlideSemAudio;
    acAudioCantado: Result := glAudioCantado;
    acAudioPlayback: Result := glAudioPlayback;
    acLetra: Result := glLetra;
  else
    Result := glNada;
  end;
end;

{ TListaMusicas }

constructor TListaMusicas.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIndice := -1;
  FItemSob := -1;
  FAcaoSob := -1;
  FItemPreso := -1;
  FAcaoPresa := -1;
  //O form atual usa crHandPoint em tudo: o item inteiro e clicavel.
  Cursor := crHandPoint;
  TabStop := True;
  //A legenda de cada acao. O texto e trocado no MouseMove, conforme o botao
  //sob o cursor -- e por isso que nao ha Hint fixo.
  //
  //O ParentShowHint vai explicito: o SetShowHint da VCL so o desliga quando o
  //valor MUDA (Vcl.Controls.pas:6312), e depender de o padrao ser False seria
  //depender de detalhe de implementacao -- no porte, de outra.
  ParentShowHint := False;
  ShowHint := True;
  //Desenho inteiro de uma vez. Sem isto a troca de realce pisca, e era esse o
  //efeito de "scan" que apareceu na liturgia (secao 4j do CLAUDE.md).
  DoubleBuffered := True;
end;

procedure TListaMusicas.defineItens(const itens: TItensMenu);
var
  i: Integer;
begin
  FItens := itens;
  FTopo := 0;
  FIndice := -1;
  FItemSob := -1;
  FAcaoSob := -1;
  FProjetando := -1;

  //As colunas de acao sao FIXAS: cada acao tem sempre a mesma posicao, e a
  //que nao se aplica deixa o lugar vazio. E o contrario do que o DBCtrlGrid
  //fazia (empacotar para a direita), que e o que faz o mesmo x significar
  //coisas diferentes em linhas diferentes -- e errar o clique num culto.
  //
  //Mas reservar as colunas numa lista em que NENHUM item tem acao (pasta so
  //com mp3 avulso) seria jogar fora um terco da largura, entao a reserva so
  //existe se alguem usar.
  FSlots := 0;
  for i := 0 to High(FItens) do
    //'possiveis', nao 'acoes': item sem playback continua ocupando as seis
    //colunas, so que duas delas apagadas.
    if (FItens[i].possiveis <> []) then
    begin
      FSlots := Ord(High(TAcaoItem)) + 1;
      Break;
    end;

  Invalidate;
end;

procedure TListaMusicas.poeProjetando(v: Integer);
begin
  if (v < -1) then
    v := -1;
  if (v <> FProjetando) then
  begin
    FProjetando := v;
    Invalidate;
  end;
end;

function TListaMusicas.larguraMinima: Integer;
begin
  //Número + nome legível + todas as colunas de ação + a barra. As ações são
  //reservadas sempre (FSlots), então o pior caso é o que vale aqui.
  Result := MARGEM_ESQ + LARG_FAIXA + MARGEM_NOME + LARG_MIN_NOME +
            (Ord(High(TAcaoItem)) + 1) * LARG_ACAO + LARG_BARRA;
end;

function TListaMusicas.alturaMinima: Integer;
begin
  //Três linhas: menos que isso a lista deixa de ser lista.
  Result := 3 * PASSO_ITEM;
end;

function TListaMusicas.posDoItem(i: Integer): Integer;
begin
  if (i >= 0) and (i <= High(FItens)) then
    Result := FItens[i].pos
  else
    Result := -1;
end;

function TListaMusicas.quantidade: Integer;
begin
  Result := Length(FItens);
end;

function TListaMusicas.alturaTotal: Integer;
begin
  Result := Length(FItens) * PASSO_ITEM;
end;

function TListaMusicas.temBarra: Boolean;
begin
  Result := alturaTotal > ClientHeight;
end;

function TListaMusicas.larguraUtil: Integer;
begin
  Result := ClientWidth;
  if temBarra then
    Dec(Result, LARG_BARRA);
end;

function TListaMusicas.topoMaximo: Integer;
begin
  Result := alturaTotal - ClientHeight;
  if (Result < 0) then
    Result := 0;
end;

procedure TListaMusicas.poeTopo(v: Integer);
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

function TListaMusicas.primeiroVisivel: Integer;
begin
  if (Length(FItens) = 0) then
  begin
    Result := -1;
    Exit;
  end;

  Result := FTopo div PASSO_ITEM;
  if (Result < 0) then
    Result := 0;
  if (Result > High(FItens)) then
    Result := High(FItens);
end;

procedure TListaMusicas.poeIndice(v: Integer);
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

function TListaMusicas.retanguloItem(i: Integer): TRect;
var
  t: Integer;
begin
  t := i * PASSO_ITEM - FTopo;
  Result := Rect(0, t, larguraUtil, t + ALTURA_ITEM);
end;

function TListaMusicas.itemEm(y: Integer): Integer;
begin
  Result := (y + FTopo) div PASSO_ITEM;
  //A faixa de 1px entre dois itens nao pertence a nenhum dos dois.
  if ((y + FTopo) mod PASSO_ITEM) >= ALTURA_ITEM then
    Result := -1
  else if (Result < 0) or (Result > High(FItens)) then
    Result := -1;
end;

function TListaMusicas.inicioDasAcoes(const r: TRect): Integer;
begin
  Result := r.Right - FSlots * LARG_ACAO;
end;

function TListaMusicas.retanguloAcao(i: Integer; acao: TAcaoItem): TRect;
var
  r: TRect;
  x: Integer;
begin
  //A coluna da acao e o Ord dela, sempre. Nao depende de quais outras acoes o
  //item tem -- e e isso que faz o clique bater com o desenho em qualquer
  //linha.
  r := retanguloItem(i);
  x := inicioDasAcoes(r) + Ord(acao) * LARG_ACAO;
  Result := Rect(x, r.Top, x + LARG_ACAO, r.Bottom);
end;

function TListaMusicas.acaoEm(const p: TPoint; out item, slot: Integer;
  out acao: TAcaoItem): Boolean;
var
  ac: TAcaoItem;
begin
  Result := False;
  slot := -1;
  acao := acSlideCantado;

  item := itemEm(p.Y);
  if (item < 0) or (p.X >= larguraUtil) then
    Exit;

  for ac := Low(TAcaoItem) to High(TAcaoItem) do
    if (ac in FItens[item].acoes) and PtInRect(retanguloAcao(item, ac), p) then
    begin
      acao := ac;
      slot := Ord(ac);
      Result := True;
      Exit;
    end;
end;

function TListaMusicas.slotApagadoEm(const p: TPoint;
  out acao: TAcaoItem): Boolean;
var
  item: Integer;
  ac: TAcaoItem;
begin
  Result := False;
  acao := acSlideCantado;

  item := itemEm(p.Y);
  if (item < 0) or (p.X >= larguraUtil) then
    Exit;

  for ac := Low(TAcaoItem) to High(TAcaoItem) do
    if (ac in FItens[item].possiveis) and not (ac in FItens[item].acoes) and
       PtInRect(retanguloAcao(item, ac), p) then
    begin
      acao := ac;
      Result := True;
      Exit;
    end;
end;

procedure TListaMusicas.poeDica(const texto: string);
begin
  if (texto = Hint) then
    Exit;

  Hint := texto;
  //A janela de dica que ja esta na tela NAO troca de texto sozinha quando o
  //Hint muda: ela foi montada com o texto antigo. Cancelar faz a proxima
  //parada do mouse montar outra, com o texto novo. Sem isto, andar de um
  //botao para o vizinho mostra a legenda errada.
  Application.CancelHint;
end;

function TListaMusicas.alturaPolegar: Integer;
begin
  Result := (ClientHeight * ClientHeight) div Max(1, alturaTotal);
  if (Result < MIN_POLEGAR) then
    Result := MIN_POLEGAR;
  if (Result > ClientHeight) then
    Result := ClientHeight;
end;

function TListaMusicas.retanguloPolegar: TRect;
var
  h, y: Integer;
begin
  h := alturaPolegar;
  y := 0;
  if (topoMaximo > 0) then
    y := ((ClientHeight - h) * FTopo) div topoMaximo;
  Result := Rect(ClientWidth - LARG_BARRA, y, ClientWidth, y + h);
end;

procedure TListaMusicas.desenhaBarra(cv: TCanvas);
var
  rp: TRect;
begin
  cv.Brush.Style := bsSolid;
  cv.Brush.Color := COR_TRILHO;
  cv.FillRect(Rect(ClientWidth - LARG_BARRA, 0, ClientWidth, ClientHeight));

  rp := retanguloPolegar;
  cv.Pen.Style := psClear;
  if FPolegarSob or FArrastando then
    cv.Brush.Color := COR_POLEGAR_SOB
  else
    cv.Brush.Color := COR_POLEGAR;
  cv.RoundRect(rp.Left + 2, rp.Top + 2, rp.Right - 2, rp.Bottom - 2, 6, 6);
  cv.Pen.Style := psSolid;
end;

procedure TListaMusicas.desenhaItem(cv: TCanvas; i: Integer);
var
  r, rc, ra: TRect;
  ac: TAcaoItem;
  fimNome: Integer;
  corGlifo: TColor;
  corTxt, corFraco: TColor;
  corLinha: TColor;
  ativa: Boolean;
begin
  r := retanguloItem(i);

  cv.Brush.Style := bsSolid;
  if (i = FIndice) then
    corLinha := COR_ITEM_SEL
  else if (i = FItemSob) then
    corLinha := COR_ITEM_SOB
  else
    corLinha := COR_ITEM;
  cv.Brush.Color := corLinha;
  cv.FillRect(r);

  //Na linha selecionada o texto vai na cor do tema para selecao: num tema
  //claro a faixa selecionada costuma ser escura, e o nome sumiria nela.
  if (i = FIndice) then
  begin
    corTxt := COR_TEXTO_SEL;
    corFraco := Mistura(COR_ITEM_SEL, COR_TEXTO_SEL, 65);
  end
  else
  begin
    corTxt := COR_TEXTO;
    corFraco := COR_TEXTO_FRACO;
  end;

  //A linha de 1px entre os itens: era o Panel3 alBottom do .dfm.
  cv.Brush.Color := COR_SEPARADOR;
  cv.FillRect(Rect(r.Left, r.Bottom, r.Right, r.Bottom + ALTURA_SEP));

  //O item que esta no ar ganha uma barra na borda esquerda.
  if (i = FProjetando) then
  begin
    cv.Brush.Color := COR_ACENTO;
    cv.FillRect(Rect(r.Left, r.Top, r.Left + 3, r.Bottom));
  end;

  //Numero da faixa, a direita da propria coluna.
  rc := Rect(r.Left + MARGEM_ESQ, r.Top, r.Left + MARGEM_ESQ + LARG_FAIXA,
             r.Bottom);
  PreparaFonte(cv, 14, False, corFraco);
  DesenhaTexto(cv, rc, IntToStr(FItens[i].faixa), alinDireita);

  fimNome := inicioDasAcoes(r);

  //Nome: ocupa o que sobra entre a faixa e as acoes.
  rc := Rect(rc.Right + MARGEM_NOME, r.Top, fimNome - MARGEM_NOME, r.Bottom);
  PreparaFonte(cv, 15, True, corTxt);
  DesenhaTexto(cv, rc, FItens[i].nome, alinEsquerda);

  //Acoes, cada uma na coluna fixa dela. Percorre as POSSIVEIS: o que nao
  //esta em 'acoes' e desenhado apagado, nao omitido -- coluna vazia nao
  //distingue 'esta musica nao tem playback' de 'ninguem usa esta coluna'.
  for ac := Low(TAcaoItem) to High(TAcaoItem) do
    if (ac in FItens[i].possiveis) then
    begin
      ra := retanguloAcao(i, ac);
      ativa := (ac in FItens[i].acoes);

      if ativa and (i = FItemSob) and (Ord(ac) = FAcaoSob) then
      begin
        cv.Pen.Style := psClear;
        cv.Brush.Style := bsSolid;
        cv.Brush.Color := COR_REALCE;
        cv.RoundRect(ra.Left + 1, ra.Top + 4, ra.Right - 1, ra.Bottom - 4,
          6, 6);
        cv.Pen.Style := psSolid;
        corGlifo := COR_ACAO_SOB;
      end
      else if ativa then
        corGlifo := COR_ACAO
      else
        //Apagado. A cor serve ao glifo de reserva; para o icone de imagem
        //quem apaga e o DesenhaIcone, que precisa da cor da LINHA para
        //misturar -- e ela muda com selecao e com o mouse.
        corGlifo := Mistura(corLinha, COR_ACAO, FORCA_APAGADO);

      DesenhaIcone(cv, ra, FImagens, IconeDaAcao(ac), GlifoDaAcao(ac),
        corGlifo, ativa, corLinha);
    end;
end;

procedure TListaMusicas.Paint;
var
  i, pri, ult: Integer;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := COR_FUNDO;
  Canvas.FillRect(ClientRect);

  if (Length(FItens) = 0) then
  begin
    PreparaFonte(Canvas, 14, False, COR_TEXTO_FRACO);
    DesenhaTexto(Canvas, ClientRect, 'Nenhuma musica nesta colet' + #226 +
      'nea', alinCentro);
    Exit;
  end;

  //So os itens visiveis sao desenhados.
  pri := FTopo div PASSO_ITEM;
  if (pri < 0) then
    pri := 0;
  ult := (FTopo + ClientHeight) div PASSO_ITEM;
  if (ult > High(FItens)) then
    ult := High(FItens);

  for i := pri to ult do
    desenhaItem(Canvas, i);

  if temBarra then
    desenhaBarra(Canvas);
end;

procedure TListaMusicas.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  it, slot: Integer;
  ac: TAcaoItem;
  p: TPoint;
begin
  inherited;

  if CanFocus then
    SetFocus;

  p := Point(X, Y);

  if temBarra and (X >= ClientWidth - LARG_BARRA) then
  begin
    if PtInRect(retanguloPolegar, p) then
    begin
      FArrastando := True;
      FArrasteY := Y;
      FArrasteTopo := FTopo;
    end
    else if (Y < retanguloPolegar.Top) then
      poeTopo(FTopo - ClientHeight)
    else
      poeTopo(FTopo + ClientHeight);
    Invalidate;
    Exit;
  end;

  if (Button <> mbLeft) then
    Exit;

  //Slot apagado nao e botao: o clique morre aqui, em vez de escorregar para
  //o corpo do item e abrir a musica -- que era o que acontecia enquanto a
  //coluna ficava vazia, e que seria pior agora que ela tem desenho.
  if slotApagadoEm(p, ac) then
  begin
    FItemPreso := -1;
    FAcaoPresa := -1;
    Exit;
  end;

  if acaoEm(p, it, slot, ac) then
  begin
    FItemPreso := it;
    FAcaoPresa := slot;
  end
  else
  begin
    FItemPreso := itemEm(Y);
    FAcaoPresa := -1;
  end;

  poeIndice(FItemPreso);
end;

procedure TListaMusicas.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  it, slot, novoItem, novaAcao: Integer;
  ac, acApagada: TAcaoItem;
  faixa: Integer;
  sobPolegar, apagado: Boolean;
begin
  inherited;

  if FArrastando then
  begin
    faixa := ClientHeight - alturaPolegar;
    if (faixa > 0) then
      poeTopo(FArrasteTopo + ((Y - FArrasteY) * topoMaximo) div faixa);
    Exit;
  end;

  sobPolegar := temBarra and PtInRect(retanguloPolegar, Point(X, Y));

  novoItem := itemEm(Y);
  if acaoEm(Point(X, Y), it, slot, ac) then
    novaAcao := slot
  else
    novaAcao := -1;

  apagado := slotApagadoEm(Point(X, Y), acApagada);

  //A mao e o aviso de 'da para clicar'. Sobre slot apagado ela sai.
  if apagado then
  begin
    if (Cursor <> crArrow) then
      Cursor := crArrow;
  end
  else if (Cursor <> crHandPoint) then
    Cursor := crHandPoint;

  //A legenda. Sobre o corpo do item nao ha dica: o nome ja esta escrito ali.
  if (novaAcao >= 0) then
    poeDica(NomeDaAcao(ac))
  else if apagado then
    poeDica(NomeDaAcaoApagada(acApagada))
  else
    poeDica('');

  if (novoItem <> FItemSob) or (novaAcao <> FAcaoSob) or
     (sobPolegar <> FPolegarSob) then
  begin
    FItemSob := novoItem;
    FAcaoSob := novaAcao;
    FPolegarSob := sobPolegar;
    Invalidate;
  end;
end;

procedure TListaMusicas.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  it, slot: Integer;
  ac: TAcaoItem;
  mesmoAlvo: Boolean;
begin
  if FArrastando then
  begin
    FArrastando := False;
    Invalidate;
    inherited;
    Exit;
  end;

  if (Button = mbLeft) and (FItemPreso >= 0) then
  begin
    if acaoEm(Point(X, Y), it, slot, ac) then
      mesmoAlvo := (it = FItemPreso) and (slot = FAcaoPresa)
    else
    begin
      it := itemEm(Y);
      slot := -1;
      mesmoAlvo := (it = FItemPreso) and (FAcaoPresa = -1);
    end;

    if mesmoAlvo then
    begin
      if (slot >= 0) then
      begin
        if Assigned(FOnAcao) then
          FOnAcao(Self, it, ac);
      end
      else if Assigned(FOnAbrirItem) then
        FOnAbrirItem(Self, it);
    end;
  end;

  FItemPreso := -1;
  FAcaoPresa := -1;
  inherited;
end;

procedure TListaMusicas.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  poeDica('');
  if (FItemSob <> -1) or (FAcaoSob <> -1) or FPolegarSob then
  begin
    FItemSob := -1;
    FAcaoSob := -1;
    FPolegarSob := False;
    Invalidate;
  end;
end;

function TListaMusicas.DoMouseWheel(Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  //Um item por tique, que e o que o TDBCtrlGrid fazia.
  poeTopo(FTopo - Round(WheelDelta / 120) * PASSO_ITEM);
  Result := True;
end;

procedure TListaMusicas.mostraItem(i: Integer);
var
  t: Integer;
begin
  if (i < 0) or (i > High(FItens)) then
    Exit;
  t := i * PASSO_ITEM;
  if (t < FTopo) then
    poeTopo(t)
  else if (t + ALTURA_ITEM > FTopo + ClientHeight) then
    poeTopo(t + ALTURA_ITEM - ClientHeight);
end;

procedure TListaMusicas.KeyDown(var Key: Word; Shift: TShiftState);
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
    //esta janela na frente. Engolir aqui quebraria quem esta projetando.
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

procedure TListaMusicas.Resize;
begin
  inherited;
  //Encolher a janela pode deixar o topo acima do maximo.
  poeTopo(FTopo);
  Invalidate;
end;

end.
