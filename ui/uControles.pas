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
    FMostraSeta: Boolean;
    FCorFundo: TColor;
    FImagens: TCustomImageList;
    FIndiceImagem: Integer;
    procedure poeGlifo(v: TGlifo);
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
  corTexto: TColor;
begin
  r := ClientRect;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FCorFundo;
  Canvas.FillRect(r);

  if Enabled and (FPressionado or FSob) then
  begin
    Canvas.Pen.Style := psClear;
    if FPressionado then
      Canvas.Brush.Color := COR_ITEM_SEL
    else
      Canvas.Brush.Color := COR_REALCE;
    Canvas.RoundRect(r.Left, r.Top, r.Right, r.Bottom, 6, 6);
    Canvas.Pen.Style := psSolid;
  end;

  if Enabled then
    corTexto := COR_TEXTO
  else
    corTexto := COR_TEXTO_FRACO;

  rg := Rect(r.Left + MARGEM_BOTAO, r.Top, r.Left + MARGEM_BOTAO + LADO_GLIFO,
             r.Bottom);
  if (FImagens <> nil) or (FGlifo <> glNada) then
    DesenhaIcone(Canvas, rg, FImagens, FIndiceImagem, FGlifo, corTexto,
      Enabled, FCorFundo);

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

procedure TTemaPopup.aplica(menu: TMenuItem);
var
  i: Integer;
begin
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

  Width := ACanvas.TextWidth(it.Caption) + 2 * MARGEM_BOTAO + LADO_GLIFO;
  Height := 26;
end;

procedure TTemaPopup.desenha(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
  Selected: Boolean);
var
  it: TMenuItem;
  r: TRect;
  y: Integer;
begin
  it := TMenuItem(Sender);

  ACanvas.Brush.Style := bsSolid;
  if Selected then
    ACanvas.Brush.Color := COR_REALCE
  else
    ACanvas.Brush.Color := COR_ITEM;
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

  if it.Checked then
  begin
    DesenhaGlifo(ACanvas, QuadradoCentral(Rect(r.Left, r.Top,
      r.Left + LADO_GLIFO, r.Bottom), 16), glSetaBaixo, COR_TEXTO);
  end;
  Inc(r.Left, LADO_GLIFO);

  if it.Enabled then
    PreparaFonte(ACanvas, ALTURA_FONTE, it.Default, COR_TEXTO)
  else
    PreparaFonte(ACanvas, ALTURA_FONTE, it.Default, COR_TEXTO_FRACO);

  DesenhaTexto(ACanvas, r, it.Caption, alinEsquerda);
end;

initialization
  TemaPopup := TTemaPopup.Create;

finalization
  TemaPopup.Free;

end.
