//  Barra de rolagem desenhada, com os dois botoes de passo.
//
//  POR QUE ESTA UNIT EXISTE. A barra nasceu duas vezes, copiada palavra por
//  palavra: TListaMusicas e TListaLiturgia tinham o mesmo LARG_BARRA, o mesmo
//  MIN_POLEGAR, o mesmo alturaPolegar, o mesmo retanguloPolegar, o mesmo
//  desenhaBarra e o mesmo teste de clique, mudando so o nome dos campos. Com
//  os botoes nas pontas a conta dobra de tamanho -- o polegar deixa de andar
//  na altura inteira e passa a andar dentro do trilho --, e manter duas copias
//  disso e fazenda de bug: quando uma muda, a outra fica.
//
//  O QUE ELA NAO FAZ. Nao guarda estado. O topo da rolagem continua sendo do
//  controle, que e quem sabe rolar; aqui so entram a geometria, o desenho e o
//  teste de clique. Tambem nao ha temporizador: repetir enquanto o botao fica
//  apertado depende de Invalidate e de campos do controle, entao mora la.
//
//  PORTE (regra 5b). Depende de Vcl.Graphics (TCanvas, TColor) e do uTema.
//  No Lazarus muda so a clausula uses: Polygon, FillRect e RoundRect existem
//  iguais no LCL.

unit uBarraRolagem;

interface

uses
  System.Types, System.Math, Vcl.Graphics, uTema;

const
  //Era 10 e ficava fina demais para acertar com o mouse. 16 e a largura
  //confortavel, e e o lado do botao quadrado das pontas.
  LARG_BARRA = 16;

  //Botao quadrado. Abaixo de uns 3 botoes de altura nao cabe trilho util,
  //e nesse caso a barra sai sem botao nenhum.
  ALT_BOTAO = LARG_BARRA;

  //Polegar nunca some, por menor que seja a proporcao visivel.
  MIN_POLEGAR = 28;

type
  //Onde um ponto caiu dentro da barra.
  TZonaBarra = (
    zbNada,           //fora da barra
    zbSobe,           //botao de cima
    zbDesce,          //botao de baixo
    zbPolegar,
    zbPaginaAcima,    //trilho, acima do polegar
    zbPaginaAbaixo
  );

  //Geometria da barra para um estado (tamanho do controle + rolagem).
  //Montada por MontaBarra e descartada em seguida: e valor, nao objeto.
  TBarraRolagem = record
    visivel: Boolean;
    temBotoes: Boolean;
    area: TRect;        //a barra inteira, da borda direita do controle
    btSobe: TRect;
    btDesce: TRect;
    trilho: TRect;      //o que sobra entre os botoes
    polegar: TRect;

    function zonaEm(const p: TPoint): TZonaBarra;

    //Topo correspondente a um arraste do polegar. yAtual e o cursor agora,
    //yInicial e topoInicial sao o estado de quando o arraste comecou.
    function topoDoArraste(yAtual, yInicial, topoInicial,
      topoMaximo: Integer): Integer;
  end;

function MontaBarra(larguraCliente, alturaCliente, alturaTotal,
  topo, topoMaximo: Integer): TBarraRolagem;

procedure DesenhaBarra(cv: TCanvas; const b: TBarraRolagem;
  zonaSob: TZonaBarra; arrastando: Boolean);

implementation

function MontaBarra(larguraCliente, alturaCliente, alturaTotal,
  topo, topoMaximo: Integer): TBarraRolagem;
var
  alt, y, faixa: Integer;
begin
  Result.visivel := (alturaTotal > alturaCliente) and (alturaCliente > 0);
  Result.temBotoes := False;
  Result.area := Rect(0, 0, 0, 0);
  Result.btSobe := Rect(0, 0, 0, 0);
  Result.btDesce := Rect(0, 0, 0, 0);
  Result.trilho := Rect(0, 0, 0, 0);
  Result.polegar := Rect(0, 0, 0, 0);

  if not Result.visivel then
    Exit;

  Result.area := Rect(larguraCliente - LARG_BARRA, 0,
                      larguraCliente, alturaCliente);

  //Sem altura para os dois botoes mais um trilho que preste, a barra fica
  //so com o trilho. Melhor que botao espremido que ninguem acerta.
  Result.temBotoes := (alturaCliente >= (ALT_BOTAO * 2 + MIN_POLEGAR));

  if Result.temBotoes then
  begin
    Result.btSobe := Rect(Result.area.Left, 0,
                          Result.area.Right, ALT_BOTAO);
    Result.btDesce := Rect(Result.area.Left, alturaCliente - ALT_BOTAO,
                           Result.area.Right, alturaCliente);
    Result.trilho := Rect(Result.area.Left, ALT_BOTAO,
                          Result.area.Right, alturaCliente - ALT_BOTAO);
  end
  else
    Result.trilho := Result.area;

  //Proporcao do visivel sobre o total, aplicada ao TRILHO e nao a altura
  //do controle: e dentro dele que o polegar anda.
  alt := (Result.trilho.Height * alturaCliente) div Max(1, alturaTotal);
  if (alt < MIN_POLEGAR) then
    alt := MIN_POLEGAR;
  if (alt > Result.trilho.Height) then
    alt := Result.trilho.Height;

  faixa := Result.trilho.Height - alt;
  y := Result.trilho.Top;
  if (topoMaximo > 0) and (faixa > 0) then
    Inc(y, (faixa * topo) div topoMaximo);

  Result.polegar := Rect(Result.area.Left, y, Result.area.Right, y + alt);
end;

function TBarraRolagem.zonaEm(const p: TPoint): TZonaBarra;
begin
  Result := zbNada;
  if not visivel then
    Exit;
  if not PtInRect(area, p) then
    Exit;

  if temBotoes and PtInRect(btSobe, p) then
    Exit(zbSobe);
  if temBotoes and PtInRect(btDesce, p) then
    Exit(zbDesce);
  if PtInRect(polegar, p) then
    Exit(zbPolegar);

  if (p.Y < polegar.Top) then
    Result := zbPaginaAcima
  else
    Result := zbPaginaAbaixo;
end;

function TBarraRolagem.topoDoArraste(yAtual, yInicial, topoInicial,
  topoMaximo: Integer): Integer;
var
  faixa: Integer;
begin
  Result := topoInicial;

  faixa := trilho.Height - polegar.Height;
  if (faixa <= 0) then
    Exit;

  Result := topoInicial + ((yAtual - yInicial) * topoMaximo) div faixa;
end;

//Triangulo cheio apontando para cima ou para baixo, centrado no retangulo.
procedure desenhaSeta(cv: TCanvas; const r: TRect; paraCima: Boolean;
  cor: TColor);
var
  cx, cy, lado: Integer;
begin
  cx := (r.Left + r.Right) div 2;
  cy := (r.Top + r.Bottom) div 2;

  //Metade da base. Deixa respiro nas bordas do botao.
  lado := Max(3, (Min(r.Width, r.Height) - 7) div 2);

  cv.Brush.Style := bsSolid;
  cv.Brush.Color := cor;
  cv.Pen.Style := psClear;

  if paraCima then
    cv.Polygon([Point(cx, cy - lado + 1),
                Point(cx + lado, cy + lado - 1),
                Point(cx - lado, cy + lado - 1)])
  else
    cv.Polygon([Point(cx, cy + lado - 1),
                Point(cx + lado, cy - lado + 1),
                Point(cx - lado, cy - lado + 1)]);

  cv.Pen.Style := psSolid;
end;

procedure DesenhaBarra(cv: TCanvas; const b: TBarraRolagem;
  zonaSob: TZonaBarra; arrastando: Boolean);

  //Fundo do botao so aparece sob o mouse: barra parada fica limpa.
  procedure fundoBotao(const r: TRect; aceso: Boolean);
  begin
    if not aceso then
      Exit;
    cv.Brush.Color := COR_POLEGAR;
    cv.FillRect(r);
  end;

var
  cor: TColor;
begin
  if not b.visivel then
    Exit;

  cv.Brush.Style := bsSolid;
  cv.Brush.Color := COR_TRILHO;
  cv.FillRect(b.area);

  if b.temBotoes then
  begin
    fundoBotao(b.btSobe, zonaSob = zbSobe);
    fundoBotao(b.btDesce, zonaSob = zbDesce);

    //A seta usa a cor das acoes, que acompanha o tema -- o mesmo criterio da
    //alca de arrastar da liturgia, e pelo mesmo motivo: icone de lista de
    //imagens traria a cor dele e sumiria em metade dos temas.
    if (zonaSob = zbSobe) then cor := COR_ACAO_SOB else cor := COR_ACAO;
    desenhaSeta(cv, b.btSobe, True, cor);

    if (zonaSob = zbDesce) then cor := COR_ACAO_SOB else cor := COR_ACAO;
    desenhaSeta(cv, b.btDesce, False, cor);
  end;

  cv.Pen.Style := psClear;
  if arrastando or (zonaSob = zbPolegar) then
    cv.Brush.Color := COR_POLEGAR_SOB
  else
    cv.Brush.Color := COR_POLEGAR;
  cv.RoundRect(b.polegar.Left + 3, b.polegar.Top + 2,
               b.polegar.Right - 3, b.polegar.Bottom - 2, 6, 6);
  cv.Pen.Style := psSolid;
end;

end.
