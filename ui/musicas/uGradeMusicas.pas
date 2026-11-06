unit uGradeMusicas;

//A grade de musicas PROJETADA, a que a congregacao ve.
//
//Controle proprio, e nao o TListaMusicas da tela do operador, porque os dois
//comportamentos sao diferentes de verdade: aqui nao ha hover, nao ha botao de
//acao, nao ha rolagem por pixel nem barra -- ha paginacao -- e as medidas sao
//fracao da tela em vez de pixel fixo. Forcar os dois na mesma classe traria de
//volta o emaranhado que o DBCtrlGrid tinha. O que de fato se compartilha (cor,
//fonte e desenho de texto) mora no uTema, e e de la que vem.
//
//O DEFEITO QUE ISTO CORRIGE. A tela projetada era copia da do operador, com
//tudo em pixel fixo vindo do .dfm (titulo 65, capa 137x137, fonte do item 40).
//O RowCount := ClientHeight / 80 fazia o TDBCtrlGrid dividir a altura em
//linhas de ~80px -- isso era proporcional --, mas a FONTE nao acompanhava.
//Resultado: numa tela maior apareciam MAIS musicas, nao musicas MAIORES, com
//texto de ~30px dentro de linha de 80. Para quem esta no fundo da igreja isso
//e o contrario do que se quer.
//
//Aqui a conta e outra: o numero de linhas por tela e fixo, a altura da linha
//sai da altura da tela, e a fonte sai da altura da linha. Tela maior = texto
//maior.
//
//PORTE PARA O LAZARUS: trocar a clausula uses. Nao ha WinAPI nenhuma.

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Graphics, Vcl.Controls,
  uTema, uMenuMusicas;

const
  //Quantas musicas cabem numa tela projetada. Menos linhas = letra maior; e o
  //unico botao que regula legibilidade contra quantidade.
  LINHAS_PROJECAO = 10;
  COLUNAS_PROJECAO = 2;

type
  TGradeMusicas = class(TCustomControl)
  private
    FItens: TItensMenu;
    FLinhas: Integer;
    FColunas: Integer;
    FDestaque: Integer;
    FPagina: Integer;
    function itensPorPagina: Integer;
    function alturaLinha: Integer;
    function larguraColuna: Integer;
    function retanguloDoLugar(coluna, linha: Integer): TRect;
    procedure poeDestaque(v: Integer);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure defineItens(const itens: TItensMenu);
    //Leva a pagina ate o item, sem destacar.
    procedure mostraItem(i: Integer);
    function quantidade: Integer;
    property linhas: Integer read FLinhas write FLinhas;
    property colunas: Integer read FColunas write FColunas;
    //O item que esta no ar. Destacar e tambem virar a pagina ate ele.
    property destaque: Integer read FDestaque write poeDestaque;
  end;

implementation

{ TGradeMusicas }

constructor TGradeMusicas.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLinhas := LINHAS_PROJECAO;
  FColunas := COLUNAS_PROJECAO;
  FDestaque := -1;
  FPagina := 0;
  DoubleBuffered := True;
end;

procedure TGradeMusicas.defineItens(const itens: TItensMenu);
begin
  FItens := itens;
  FPagina := 0;
  FDestaque := -1;
  Invalidate;
end;

function TGradeMusicas.quantidade: Integer;
begin
  Result := Length(FItens);
end;

function TGradeMusicas.itensPorPagina: Integer;
begin
  Result := FLinhas * FColunas;
  if (Result < 1) then
    Result := 1;
end;

function TGradeMusicas.alturaLinha: Integer;
begin
  Result := ClientHeight div FLinhas;
  if (Result < 1) then
    Result := 1;
end;

function TGradeMusicas.larguraColuna: Integer;
begin
  Result := ClientWidth div FColunas;
  if (Result < 1) then
    Result := 1;
end;

function TGradeMusicas.retanguloDoLugar(coluna, linha: Integer): TRect;
var
  x, y: Integer;
begin
  x := coluna * larguraColuna;
  y := linha * alturaLinha;
  Result := Rect(x, y, x + larguraColuna, y + alturaLinha);
end;

procedure TGradeMusicas.mostraItem(i: Integer);
var
  p: Integer;
begin
  if (i < 0) or (i > High(FItens)) then
    Exit;

  p := i div itensPorPagina;
  if (p <> FPagina) then
  begin
    FPagina := p;
    Invalidate;
  end;
end;

procedure TGradeMusicas.poeDestaque(v: Integer);
begin
  if (v < -1) then
    v := -1;
  if (v > High(FItens)) then
    v := High(FItens);

  if (v <> FDestaque) then
  begin
    FDestaque := v;
    Invalidate;
  end;

  //Virar a pagina acontece mesmo quando o destaque nao mudou: a pagina pode
  //ter sido trocada por outro caminho e o item precisa voltar a aparecer.
  mostraItem(FDestaque);
end;

procedure TGradeMusicas.Resize;
begin
  inherited;
  //Mudou a tela, mudou quantos itens cabem: a pagina atual pode nem existir
  //mais. Reancora pelo destaque, que e o que importa mostrar.
  if (FDestaque >= 0) then
    FPagina := FDestaque div itensPorPagina;
  Invalidate;
end;

procedure TGradeMusicas.Paint;
var
  cv: TCanvas;
  c, l, idx, base, hLinha, recuo, largNum: Integer;
  r, rn, rt: TRect;
  corTexto, corNum: TColor;
begin
  cv := Canvas;

  cv.Brush.Style := bsSolid;
  cv.Brush.Color := COR_PROJ_FUNDO;
  cv.FillRect(ClientRect);

  if (Length(FItens) = 0) then
    Exit;

  hLinha := alturaLinha;
  //A fonte sai da altura da linha: e isto que faz tela maior virar texto
  //maior, em vez de mais linhas.
  recuo := hLinha div 5;
  largNum := Round(larguraColuna * 0.16);
  base := FPagina * itensPorPagina;

  for c := 0 to FColunas - 1 do
    for l := 0 to FLinhas - 1 do
    begin
      //Preenchimento por COLUNA: a primeira coluna vai do 1 ao N, a segunda
      //continua dali. E como se le uma lista de hinos impressa.
      idx := base + c * FLinhas + l;
      if (idx > High(FItens)) then
        Continue;

      r := retanguloDoLugar(c, l);

      if (idx = FDestaque) then
      begin
        cv.Brush.Style := bsSolid;
        cv.Brush.Color := COR_PROJ_DESTAQUE;
        cv.FillRect(Rect(r.Left + recuo div 2, r.Top + recuo div 4,
          r.Right - recuo, r.Bottom - recuo div 4));
        corTexto := COR_PROJ_ACENTO;
        corNum := COR_PROJ_ACENTO;
      end
      else
      begin
        corTexto := COR_PROJ_TEXTO;
        corNum := COR_PROJ_FRACO;
      end;

      rn := Rect(r.Left + recuo, r.Top, r.Left + recuo + largNum, r.Bottom);
      PreparaFonte(cv, Round(hLinha * 0.40), False, corNum);
      DesenhaTexto(cv, rn, IntToStr(FItens[idx].faixa), alinDireita);

      rt := Rect(rn.Right + recuo, r.Top, r.Right - recuo, r.Bottom);
      PreparaFonte(cv, Round(hLinha * 0.40), False, corTexto);
      DesenhaTexto(cv, rt, FItens[idx].nome, alinEsquerda);
    end;
end;

end.
