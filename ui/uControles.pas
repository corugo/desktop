unit uControles;

//Os controles chatos (sem skin) que substituem os do BusinessSkinForm:
//
//  TPainelLiso  <- TPanel com Color + ParentBackground. O TPanel tematizado do
//                  Windows nao aceita cor chapada sem briga, e ParentBackground
//                  nao existe igual no LCL. Um TCustomControl que so preenche
//                  resolve os dois casos em 15 linhas.
//  TBotaoChato  <- TbsSkinSpeedButton e TbsSkinMenuSpeedButton
//  TemaPopup    <- SkinPopupMenu: um TPopupMenu comum, desenhado escuro
//
//PORTE PARA O LAZARUS: trocar a clausula uses. CM_MOUSEENTER/CM_MOUSELEAVE
//existem nos dois frameworks (no LCL vindos do Controls), e sao o unico
//detalhe de mensagem desta unit.

interface

uses
  Winapi.Messages, System.Classes, System.SysUtils, System.Types,
  Vcl.Graphics, Vcl.Controls, Vcl.Menus, Vcl.ImgList,
  uTema;

type
  TPainelLiso = class(TCustomControl)
  private
    FCor: TColor;
    procedure poeCor(v: TColor);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property cor: TColor read FCor write poeCor;
  end;

  TBotaoChato = class(TGraphicControl)
  private
    FGlifo: TGlifo;
    FSob: Boolean;
    FPressionado: Boolean;
    FSelecionado: Boolean;
    FMostraSeta: Boolean;
    FCorFundo: TColor;
    FImagens: TCustomImageList;
    FIndiceImagem: Integer;
    procedure poeGlifo(v: TGlifo);
    procedure poeSelecionado(v: Boolean);
    procedure poeMostraSeta(v: Boolean);
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    //Largura que o botao precisa para o texto nao ser cortado. O
    //TbsSkinSpeedButton tinha WidthWithCaption/WidthWithoutCaption vindos do
    //skin; aqui a conta e feita com a fonte de verdade.
    function larguraIdeal: Integer;
    property glifo: TGlifo read FGlifo write poeGlifo;
    //Seleção que FICA, diferente do FPressionado, que só vale enquanto o
    //botão do mouse está apertado. É o que permite usar o botão como aba ou
    //como item de uma escolha entre vários.
    property selecionado: Boolean read FSelecionado write poeSelecionado;
    property mostraSeta: Boolean read FMostraSeta write poeMostraSeta;
    property corFundo: TColor read FCorFundo write FCorFundo;
    //Icone de verdade; nao havendo lista, vale o glifo desenhado.
    property imagens: TCustomImageList read FImagens write FImagens;
    property indiceImagem: Integer read FIndiceImagem write FIndiceImagem;
  published
    property Caption;
    property Enabled;
    property Hint;
    property ShowHint;
    property Visible;
    property OnClick;
  end;

  //Uma entrada de menu que leva um GLIFO DESENHADO no lugar do icone.
  //
  //Existe porque nem tudo que um menu precisa dizer esta na lista de imagens:
  //as setas de "inserir acima/abaixo" nao tem par na ico_24x24 (ha a de baixo
  //e nao ha a de cima), e icone de lista de imagens ainda carrega a cor DELE,
  //que e a armadilha que ja fez a alca de arrastar sumir em tema claro. Glifo
  //desenhado sai em COR_TEXTO e vale nos sete temas.
  //
  //E um DESCENDENTE e nao um campo escondido em Tag/HelpContext porque o Tag
  //ja carrega o tag da acao nas entradas de "Abrir", e porque assim o tipo
  //diz o que e. TMenuItem aceita descendente no Add nos dois frameworks.
  TItemMenuGlifo = class(TMenuItem)
  public
    glifo: TGlifo;
  end;

  //Desenha os itens de um TPopupMenu comum com as cores do tema. O que fica
  //de fora e a MOLDURA da janela do menu, que e do sistema: isso o skin
  //pintava e aqui nao da, a nao ser trocando o popup por um form proprio.
  TTemaPopup = class
  public
    procedure aplica(menu: TMenuItem);
    procedure mede(Sender: TObject; ACanvas: TCanvas;
      var Width, Height: Integer);
    procedure desenha(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
      Selected: Boolean);
  end;

//O texto de uma entrada de menu, SEM o acelerador que a VCL insere no
//Caption. Publica porque e parte do contrato de quem desenha menu -- ver o
//comentario da implementacao.
function textoDoItem(it: TMenuItem): string;

var
  TemaPopup: TTemaPopup;

implementation

const
  MARGEM_BOTAO = 8;
  LADO_GLIFO = 24;
  ESPACO_GLIFO = 6;
  LARG_SETA = 16;
  ALTURA_FONTE = 13;

{ TPainelLiso }

constructor TPainelLiso.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCor := COR_FUNDO;
  //Sem isto a troca de cor de fundo pisca quando o pai realinha os filhos --
  //foi o mesmo remedio usado na renderizacao da liturgia.
  DoubleBuffered := True;
end;

procedure TPainelLiso.poeCor(v: TColor);
begin
  if (FCor <> v) then
  begin
    FCor := v;
    Invalidate;
  end;
end;

procedure TPainelLiso.Paint;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FCor;
  Canvas.FillRect(ClientRect);
end;

{ TBotaoChato }

constructor TBotaoChato.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCorFundo := COR_FUNDO;
  FGlifo := glNada;
  FIndiceImagem := -1;
  Height := 32;
  Width := 120;
  Cursor := crHandPoint;
end;

procedure TBotaoChato.poeSelecionado(v: Boolean);
begin
  if (FSelecionado <> v) then
  begin
    FSelecionado := v;
    Invalidate;
  end;
end;

procedure TBotaoChato.poeGlifo(v: TGlifo);
begin
  if (FGlifo <> v) then
  begin
    FGlifo := v;
    Invalidate;
  end;
end;

procedure TBotaoChato.poeMostraSeta(v: Boolean);
begin
  if (FMostraSeta <> v) then
  begin
    FMostraSeta := v;
    Invalidate;
  end;
end;

procedure TBotaoChato.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  FSob := True;
  Invalidate;
end;

procedure TBotaoChato.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  FSob := False;
  FPressionado := False;
  Invalidate;
end;

procedure TBotaoChato.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if (Button = mbLeft) then
  begin
    FPressionado := True;
    Invalidate;
  end;
end;

procedure TBotaoChato.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  FPressionado := False;
  Invalidate;
  inherited;
end;

function TBotaoChato.larguraIdeal: Integer;
begin
  PreparaFonte(Canvas, ALTURA_FONTE, False, COR_TEXTO);
  Result := MARGEM_BOTAO + LADO_GLIFO + ESPACO_GLIFO +
            Canvas.TextWidth(Caption) + MARGEM_BOTAO;
  if FMostraSeta then
    Inc(Result, LARG_SETA);
end;

procedure TBotaoChato.Paint;
var
  r, rg, rt, rs: TRect;
  corTexto, fundo: TColor;
begin
  r := ClientRect;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FCorFundo;
  Canvas.FillRect(r);

  //O fundo de verdade por baixo do ícone e do texto. Era sempre o FCorFundo,
  //o que só não aparecia porque misturar contra a cor errada muda apenas
  //ícone apagado -- com a seleção, que é escura em tema claro, apareceria.
  fundo := FCorFundo;

  if Enabled and (FPressionado or FSelecionado or FSob) then
  begin
    Canvas.Pen.Style := psClear;
    if (FPressionado or FSelecionado) then
      fundo := COR_ITEM_SEL
    else
      fundo := COR_REALCE;
    Canvas.Brush.Color := fundo;
    Canvas.RoundRect(r.Left, r.Top, r.Right, r.Bottom, 6, 6);
    Canvas.Pen.Style := psSolid;
  end;

  if not Enabled then
    corTexto := COR_TEXTO_FRACO
  //Em tema claro a seleção é escura: com COR_TEXTO o nome sumiria dentro
  //dela. É a mesma razão da linha selecionada das listas.
  else if (FPressionado or FSelecionado) then
    corTexto := COR_TEXTO_SEL
  else
    corTexto := COR_TEXTO;

  rg := Rect(r.Left + MARGEM_BOTAO, r.Top, r.Left + MARGEM_BOTAO + LADO_GLIFO,
             r.Bottom);
  if (FImagens <> nil) or (FGlifo <> glNada) then
    DesenhaIcone(Canvas, rg, FImagens, FIndiceImagem, FGlifo, corTexto,
      Enabled, fundo);

  rt := Rect(rg.Right + ESPACO_GLIFO, r.Top, r.Right - MARGEM_BOTAO, r.Bottom);
  if FMostraSeta then
    Dec(rt.Right, LARG_SETA);

  PreparaFonte(Canvas, ALTURA_FONTE, False, corTexto);
  DesenhaTexto(Canvas, rt, Caption, alinEsquerda);

  if FMostraSeta then
  begin
    rs := Rect(r.Right - MARGEM_BOTAO - LARG_SETA, r.Top,
               r.Right - MARGEM_BOTAO, r.Bottom);
    DesenhaGlifo(Canvas, QuadradoCentral(rs, LADO_GLIFO), glSetaBaixo,
      corTexto);
  end;
end;

{ TTemaPopup }

//O CAPTION NAO E O TEXTO: a VCL insere o acelerador por conta propria.
//TMenu nasce com AutoHotkeys = maAutomatic e o InternalRethinkHotkeys
//REESCREVE o Caption de cada entrada inserindo o & quando o menu e exibido --
//"Abrir" vira "A&brir". Quem desenha sozinho tem de tirar, porque o
//TextOut nao trata prefixo nenhum e o & sai na tela.
//
//Tirar aqui e nao desligar o AutoHotkeys do menu de proposito (regra 5b): a
//propriedade e da VCL e o TMenu do LCL nao a tem, enquanto o & como marca de
//acelerador existe nos dois. Assim o atalho por letra continua funcionando.
//O && e um & de verdade, como em qualquer uma das duas.
function textoDoItem(it: TMenuItem): string;
var
  i: Integer;
begin
  Result := '';
  i := 1;
  while (i <= Length(it.Caption)) do
  begin
    if (it.Caption[i] = '&') then
    begin
      Inc(i);
      if (i > Length(it.Caption)) then
        Break;
    end;
    Result := Result + it.Caption[i];
    Inc(i);
  end;
end;

procedure TTemaPopup.aplica(menu: TMenuItem);
var
  i: Integer;
  raiz: TMenu;
begin
  //SEM ATALHO POR LETRA. A VCL insere o acelerador sozinha: TMenu nasce com
  //AutoHotkeys = maAutomatic e o InternalRethinkHotkeys REESCREVE o Caption de
  //cada entrada pondo um & quando o menu e exibido. Nao e nosso e nao se quer:
  //o menu e de mouse, e a letra sublinhada so polui.
  //
  //Guardado por IFDEF porque o TMenu do LCL nao tem essa propriedade -- la nao
  //ha insercao automatica, entao o porte nao precisa de equivalente.
  raiz := menu.GetParentMenu;
  if (raiz <> nil) then
  begin
    {$IFNDEF FPC}
    raiz.AutoHotkeys := maManual;
    {$ENDIF}
  end;

  //Recursivo: submenu tambem precisa. Os eventos ficam no proprio TMenuItem,
  //nos dois frameworks, com a mesma assinatura.
  for i := 0 to menu.Count - 1 do
  begin
    menu.Items[i].OnMeasureItem := mede;
    menu.Items[i].OnDrawItem := desenha;
    if (menu.Items[i].Count > 0) then
      aplica(menu.Items[i]);
  end;
end;

procedure TTemaPopup.mede(Sender: TObject; ACanvas: TCanvas;
  var Width, Height: Integer);
var
  it: TMenuItem;
begin
  it := TMenuItem(Sender);
  PreparaFonte(ACanvas, ALTURA_FONTE, it.Default, COR_TEXTO);

  if (it.Caption = '-') then
  begin
    Height := 7;
    Exit;
  end;

  Width := ACanvas.TextWidth(textoDoItem(it)) + 2 * MARGEM_BOTAO +
           LADO_GLIFO + ESPACO_GLIFO;
  //30 e nao 26 por causa do icone: o DesenhaIcone NAO redimensiona -- a
  //imagem sai no tamanho NATIVO da lista --, entao um icone da ico_24x24
  //ocupa 24 e numa linha de 26 encostaria em cima e embaixo.
  Height := 30;
end;

procedure TTemaPopup.desenha(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
  Selected: Boolean);
var
  it: TMenuItem;
  menu: TMenu;
  r, calha: TRect;
  y: Integer;
  fundo, corTexto: TColor;
begin
  it := TMenuItem(Sender);

  if Selected then
    fundo := COR_REALCE
  else
    fundo := COR_ITEM;

  if it.Enabled then
    corTexto := COR_TEXTO
  else
    corTexto := COR_TEXTO_FRACO;

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := fundo;
  ACanvas.FillRect(ARect);

  if (it.Caption = '-') then
  begin
    y := (ARect.Top + ARect.Bottom) div 2;
    ACanvas.Brush.Color := COR_SEPARADOR;
    ACanvas.FillRect(Rect(ARect.Left + 4, y, ARect.Right - 4, y + 1));
    Exit;
  end;

  r := ARect;
  Inc(r.Left, MARGEM_BOTAO);
  Dec(r.Right, MARGEM_BOTAO);

  //A CALHA DO ICONE, sempre reservada: entrada com icone e entrada sem icone
  //no mesmo menu tem de alinhar o texto na mesma coluna.
  calha := Rect(r.Left, r.Top, r.Left + LADO_GLIFO, r.Bottom);

  if it.Checked then
    DesenhaGlifo(ACanvas, QuadradoCentral(calha, 16), glSetaBaixo, COR_TEXTO)
  else if (it is TItemMenuGlifo) and
          (TItemMenuGlifo(it).glifo <> glNada) then
    DesenhaGlifo(ACanvas, QuadradoCentral(calha, LADO_GLIFO),
      TItemMenuGlifo(it).glifo, corTexto)
  else
  begin
    //O icone vem da lista do PROPRIO menu (TMenu.Images), que e o caminho
    //padrao e existe igual no LCL. Entrada desabilitada sai APAGADA, nao
    //escondida -- a mesma escolha ja feita na lista e no seletor de modo --,
    //e por isso o fundo da linha precisa ser passado: o apagado mistura o
    //icone com a cor de tras, e misturar com a errada deixaria o icone num
    //quadrado de cor diferente.
    menu := it.GetParentMenu;
    if (menu <> nil) and (menu.Images <> nil) and (it.ImageIndex >= 0) then
      DesenhaIcone(ACanvas, calha, menu.Images, it.ImageIndex, glNada,
        COR_TEXTO, it.Enabled, fundo);
  end;

  Inc(r.Left, LADO_GLIFO + ESPACO_GLIFO);

  PreparaFonte(ACanvas, ALTURA_FONTE, it.Default, corTexto);
  DesenhaTexto(ACanvas, r, textoDoItem(it), alinEsquerda);
end;

initialization
  TemaPopup := TTemaPopup.Create;

finalization
  TemaPopup.Free;

end.
