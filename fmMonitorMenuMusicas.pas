unit fmMonitorMenuMusicas;

//O menu de músicas PROJETADO — o que a congregação vê.
//
//Era uma cópia da tela do operador: mesmo `TDBCtrlGrid`, mesmo layout, e tudo
//em pixel fixo vindo do `.dfm` (capa 137x137, título 65, fonte do item 40).
//Agora é uma grade própria (`uGradeMusicas`), com **tudo proporcional à
//altura da tela** — ver o cabeçalho daquela unit para o porquê.
//
//NÃO HÁ `.DFM`: a tela é montada em código, como a do operador. Fora o ganho
//no porte (não há formulário para converter), é o que permite recalcular as
//medidas no `Resize` — e esta janela é dimensionada depois de criada, pelo
//`fmMenu`, com o tamanho do monitor escolhido.

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.StdCtrls,
  uTema, uControles, uMenuMusicas, uGradeMusicas;

type
  TfMonitorMenuMusicas = class(TForm)
  private
    pnlTopo: TPainelLiso;
    grade: TGradeMusicas;
    procedure montaTela;
    procedure aoRedimensionar(Sender: TObject);
    procedure aoAtivar(Sender: TObject);
    procedure aoFechar(Sender: TObject; var Action: TCloseAction);
    procedure aoTeclaSolta(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CreateParams(var Params: TCreateParams); override;
  public
    //Lidos de fora pelo fmIndex.copiaDadosTelaExtendida, que copia o que está
    //na tela do operador. Os nomes são os mesmos de antes, de propósito.
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    imgCapa: TImage;

    constructor Create(AOwner: TComponent); override;

    //A lista que a congregação vê, e qual item está no ar.
    procedure defineItens(const itens: TItensMenu);
    procedure destaca(indice: Integer);
    procedure mostraItem(indice: Integer);
  end;

var
  fMonitorMenuMusicas: TfMonitorMenuMusicas;

implementation

uses fmMenu, fmListaMusica;

const
  //Fração da altura da tela que o cabeçalho ocupa. Era 137px fixos, que numa
  //tela de 1080 é pouco e numa de 768 é muito.
  FRACAO_CABECALHO = 0.14;
  ALTURA_MIN_CABECALHO = 64;

{ construção }

constructor TfMonitorMenuMusicas.Create(AOwner: TComponent);
begin
  //CreateNew e não Create: não há .dfm para carregar.
  inherited CreateNew(AOwner);

  Caption := 'Lista de Músicas';
  BorderStyle := bsNone;
  Color := COR_PROJ_FUNDO;
  Font.Name := FONTE_UI;
  KeyPreview := True;
  Width := 600;
  Height := 400;

  OnResize := aoRedimensionar;
  OnActivate := aoAtivar;
  OnClose := aoFechar;
  OnKeyUp := aoTeclaSolta;

  montaTela;
end;

procedure TfMonitorMenuMusicas.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if (fmIndex.ckMesmaJanela.checked = true) then Exit;
  Params.WndParent := 0;
end;

procedure TfMonitorMenuMusicas.montaTela;
begin
  pnlTopo := TPainelLiso.Create(Self);
  pnlTopo.Parent := Self;
  pnlTopo.Align := alTop;
  pnlTopo.Height := ALTURA_MIN_CABECALHO;
  pnlTopo.cor := COR_PROJ_FUNDO;

  imgCapa := TImage.Create(Self);
  imgCapa.Parent := pnlTopo;
  imgCapa.Align := alLeft;
  imgCapa.Stretch := True;

  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent := pnlTopo;
  lblTitulo.AutoSize := False;
  lblTitulo.Alignment := taLeftJustify;
  lblTitulo.Layout := tlBottom;
  lblTitulo.Transparent := True;
  lblTitulo.Font.Name := FONTE_UI;
  lblTitulo.Font.Color := COR_PROJ_TEXTO;
  lblTitulo.Caption := '';

  lblSubtitulo := TLabel.Create(Self);
  lblSubtitulo.Parent := pnlTopo;
  lblSubtitulo.AutoSize := False;
  lblSubtitulo.Alignment := taLeftJustify;
  lblSubtitulo.Layout := tlTop;
  lblSubtitulo.Transparent := True;
  lblSubtitulo.Font.Name := FONTE_UI;
  lblSubtitulo.Font.Color := COR_PROJ_FRACO;
  lblSubtitulo.Caption := '';

  grade := TGradeMusicas.Create(Self);
  grade.Parent := Self;
  grade.Align := alClient;
end;

{ layout proporcional }

procedure TfMonitorMenuMusicas.aoRedimensionar(Sender: TObject);
var
  h, margem, meio: Integer;
begin
  if (pnlTopo = nil) then
    Exit;

  h := Max(ALTURA_MIN_CABECALHO, Round(ClientHeight * FRACAO_CABECALHO));
  pnlTopo.Height := h;

  //A capa é quadrada e tem a altura do cabeçalho — então ela também cresce
  //com a tela, em vez dos 137px fixos de antes.
  imgCapa.Width := h;

  margem := h div 6;
  meio := h div 2;

  lblTitulo.Left := h + margem;
  lblTitulo.Top := 0;
  lblTitulo.Width := Max(0, ClientWidth - lblTitulo.Left - margem);
  lblTitulo.Height := meio;
  lblTitulo.Font.Height := -Round(h * 0.40);

  lblSubtitulo.Left := lblTitulo.Left;
  lblSubtitulo.Top := meio;
  lblSubtitulo.Width := lblTitulo.Width;
  lblSubtitulo.Height := h - meio;
  lblSubtitulo.Font.Height := -Round(h * 0.20);
end;

{ conteúdo }

procedure TfMonitorMenuMusicas.defineItens(const itens: TItensMenu);
begin
  grade.defineItens(itens);
end;

procedure TfMonitorMenuMusicas.destaca(indice: Integer);
begin
  grade.destaque := indice;
end;

procedure TfMonitorMenuMusicas.mostraItem(indice: Integer);
begin
  grade.mostraItem(indice);
end;

{ eventos }

procedure TfMonitorMenuMusicas.aoAtivar(Sender: TObject);
begin
  //É daqui que o botão da tela do operador sabe que há projeção no ar.
  if (fListaMusica <> nil) then
    fListaMusica.projetando := True;
end;

procedure TfMonitorMenuMusicas.aoFechar(Sender: TObject;
  var Action: TCloseAction);
begin
  fmIndex.fadeJanela(Self, 0);

  if (fListaMusica <> nil) then
    fListaMusica.projetando := False;
end;

procedure TfMonitorMenuMusicas.aoTeclaSolta(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  fmIndex.FormKeyUp(Sender, Key, Shift);
end;

end.
