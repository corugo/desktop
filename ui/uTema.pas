unit uTema;

//A aparencia das telas novas, num lugar so: cores, fonte, desenho de texto e
//glifos. Mora em ui/ porque serve qualquer modulo, nao so o menu de musicas.
//
//Primeira peca do abandono do BusinessSkinForm, e esse e o ganho principal
//sobre o skin: trocar a cara do programa passa a ser editar UM arquivo, em vez
//de cacar propriedade de skin em dezenas de componentes espalhados pelos .dfm.
//As cores nao sao fixas: o AplicaPaleta as traz do skin ativo, entao a tela
//nova acompanha o tema do programa em vez de ser uma ilha.
//
//DUAS COISAS AQUI AINDA SAO DO MENU DE MUSICAS, e estao de passagem:
//
//  TGlifo      -- 9 dos 12 glifos sao as acoes do menu de musicas. Quando
//                 entrar o segundo modulo, ele vai querer glifos proprios e
//                 este enum viraria um catalogo de tudo. O certo e cada modulo
//                 declarar os seus e esta unit ficar so com o DesenhaGlifo.
//                 Nao feito agora de proposito: com um consumidor so, o
//                 recorte seria adivinhacao -- que e como nasceu o emaranhado
//                 do TDBCtrlGrid que esta tela acabou de desfazer.
//  COR_PROJ_*  -- sao da PROJECAO, nao do tema, e por desenho NAO seguem o
//                 skin (ver o comentario delas). Pertencem a um uTemaProjecao
//                 em ui/musicas, junto de quem as usa.
//
//PORTE PARA O LAZARUS: trocar a clausula uses (Vcl.Graphics -> Graphics,
//System.Types -> Types, System.Classes -> Classes). Nao ha WinAPI nenhuma
//nesta unit.

interface

uses
  System.Classes, System.SysUtils, System.Types, System.UITypes,
  Vcl.Graphics, Vcl.ImgList,
  //So pelo TAcaoItem, do GlifoDaAcao la embaixo. O uMenuMusicas e unit PURA
  //(sem VCL, sem Windows, sem form), entao isto nao cria ciclo nem custo de
  //porte.
  uMenuMusicas;

const
  //Quanto do icone SOBRA num botao apagado, em porcentagem -- o resto e a cor
  //do fundo da linha. O proprio TbsPngImageList ja apaga quando recebe
  //Enabled = False, mas com alfa 127 fixo (50%), e 50% nao deu contraste
  //suficiente contra os ativos. O componente nao deixa escolher o valor, por
  //isso a mistura e feita aqui. E o unico numero a mexer para calibrar.
  FORCA_APAGADO = 26;

  //As cores da PROJECAO sao constantes e NAO seguem o skin, de proposito.
  //
  //O skin veste a interface do operador, que ele olha de perto, num monitor.
  //O que e projetado e visto pela congregacao, de longe, numa tela de igreja,
  //quase sempre com a luz baixa: ali fundo escuro com texto claro e o certo,
  //valha o tema que valer. E o mesmo criterio que o fMusica ja segue.
  COR_PROJ_FUNDO    = TColor($001A1A1A);
  COR_PROJ_TEXTO    = TColor($00FFFFFF);
  COR_PROJ_FRACO    = TColor($008D8D8D);
  COR_PROJ_DESTAQUE = TColor($00353A2D);
  COR_PROJ_ACENTO   = TColor($00A5CA5D);

  //Uma fonte so, nomeada num lugar so. No Lazarus/Linux nao existe Tahoma;
  //string vazia faz os dois frameworks usarem a fonte padrao do sistema, que
  //e provavelmente o que o porte vai querer.
  FONTE_UI = 'Tahoma';

//As cores sao VARIAVEIS, nao constantes, e e de proposito: a tela segue o tema
//do programa, e quem manda nele e o skin ativo -- ver AplicaPaleta.
//
//Os valores abaixo sao so o padrao de partida, usado enquanto ninguem aplicou
//paleta nenhuma (e num console de teste, que nao tem skin). Eles vieram do
//fmListaMusica.dfm antigo, que guardava as cores em decimal: 2302755 = $232323
//(fundo), 3487029 = $353535 (item), 5395026 = $525252 (a linha de 1px).
//
//Cuidado ao escrever cor na mao: TColor e $00BBGGRR nos dois frameworks, entao
//para cor que NAO seja cinza usar CorRGB, senao vermelho vira azul sem avisar.
var
  COR_FUNDO: TColor = TColor($00232323);
  COR_ITEM: TColor = TColor($00353535);
  COR_ITEM_SOB: TColor = TColor($003F3F3F);
  COR_ITEM_SEL: TColor = TColor($004A4A4A);
  COR_SEPARADOR: TColor = TColor($00525252);
  COR_TEXTO: TColor = TColor($00FFFFFF);
  //Texto por cima da linha selecionada. Num tema claro a selecao costuma ser
  //escura, entao sem esta cor o nome sumiria dentro dela.
  COR_TEXTO_SEL: TColor = TColor($00FFFFFF);
  COR_TEXTO_FRACO: TColor = TColor($00A8A8A8);
  COR_ACAO: TColor = TColor($00C8C8C8);
  COR_ACAO_SOB: TColor = TColor($00FFFFFF);
  COR_REALCE: TColor = TColor($00505050);
  //Destaque do item que esta no ar agora.
  COR_ACENTO: TColor = TColor($00759E1D);
  COR_TRILHO: TColor = TColor($002B2B2B);
  COR_POLEGAR: TColor = TColor($005A5A5A);
  COR_POLEGAR_SOB: TColor = TColor($007D7D7D);

type
  TGlifo = (
    glNada,
    glNota,            //o TIPO musica: duas colcheias ligadas (notaDupla)
    glPasta,           //arquivo de coletanea personalizada
    glSlideCantado,    //Tag 1 do fmListaMusica atual
    glSlidePlayback,   //Tag 2
    glSlideSemAudio,   //Tag 3
    glAudioCantado,    //Tag 4
    glAudioPlayback,   //Tag 5
    glLetra,           //Tag 6
    glReproduzirTodas,
    glProjetar,
    glSetaBaixo,
    glBloco,           //a divisoria: lista com marcador
    //Inserir item ACIMA / ABAIXO deste, no menu de contexto da liturgia.
    //
    //NAO reaproveitam o glSetaBaixo acima: aquele e o marcador de "tem menu
    //suspenso" do TBotaoChato, e mesmo desenho para coisas diferentes
    //confunde -- o mesmo argumento que ja separou a notaDupla da `nota`.
    //Estes levam a BARRA do lado para onde o item vai, que e o que diz
    //"entra aqui" em vez de so "para cima".
    glItemAcima,
    glItemAbaixo);

  TAlinhaTexto = (alinEsquerda, alinCentro, alinDireita);

function CorRGB(r, g, b: Byte): TColor;

//Mistura de duas cores, com pesoB de 0 a 100. E como as cores derivadas (o
//realce, a linha entre itens, o texto fraco) saem das poucas cores que o tema
//de fato define -- assim a tela funciona com skin claro ou escuro sem precisar
//de uma tabela para cada caso.
function Mistura(a, b: TColor; pesoB: Integer): TColor;

//Luminancia 0..255, com os pesos de sempre (30/59/11). Exportada porque e o
//que mede contraste, e os testes em console conferem por ela em vez de
//refazer a conta -- refazer e como o espelho em .ps1 que errava antes do
//codigo.
function Luminancia(c: TColor): Integer;

//Esta cor e escura? E a luminancia abaixo da metade.
function CorEscura(c: TColor): Boolean;

//Branco ou quase-preto, o que tiver contraste SOBRE a cor dada. Serve para
//texto escrito em cima de cor que o USUARIO escolheu -- a do bloco da
//liturgia, por exemplo -- e que portanto pode ser qualquer uma.
function CorDeTextoSobre(c: TColor): TColor;

//O tema atual e escuro? Decidido pela luminancia do fundo. Quem precisa saber
//e quem pinta algo FORA do nosso desenho, como a barra de titulo do sistema.
function TemaEscuro: Boolean;

//Aplica a paleta do tema, derivando o resto das cores.
//
//Os parametros sao TColor puro de proposito: esta unit nao pode conhecer o
//BusinessSkinForm (ela e pura, regra do porte). Quem busca as cores no skin e
//o fmListaMusica, passando DM.bsSkinData1.SkinColors.* -- e no porte sera
//outro alguem, sem que nada aqui mude.
//
//Paleta sem sentido (fundo igual ao texto, que e o que um skin nao carregado
//devolve) e ignorada: melhor o padrao do que uma tela preta no preto.
procedure AplicaPaleta(fundo, item, texto, selecao, textoSelecao, sombra,
  acento: TColor);

//Um quadrado de lado 'lado' centrado em r. Os glifos sao quadrados; as colunas
//do item nao.
function QuadradoCentral(const r: TRect; lado: Integer): TRect;

//Desenha o glifo dentro de r, numa grade logica de 24x24 escalada para r.
//
//Glifos DESENHADOS, usados so quando nao ha lista de imagens: e o que permite
//a tela existir sem o DM.ico_24x24, que e um TbsPngImageList -- ou seja, bsfd.
//Quem desenha icone de verdade e DesenhaIcone, logo abaixo.
procedure DesenhaGlifo(cv: TCanvas; const r: TRect; glifo: TGlifo; cor: TColor);

//Qual glifo desenha cada uma das seis acoes de musica.
//
//Mora aqui, e nao no uMenuMusicas junto dos ICONE_*, porque decide sobre o
//TGlifo -- que e deste arquivo -- e aquela unit e PURA, sem conhecer tema nem
//lista de imagens. Foi justamente por isso que ela NAO acompanhou os ICONE_*
//quando eles sairam do uListaMusicas: o par ficou pela metade, e esta sendo
//concluido aqui. Tem dois consumidores, a lista de musicas e a da liturgia.
function GlifoDaAcao(acao: TAcaoItem): TGlifo;

//Desenha o icone 'indice' da lista, centrado em r; nao havendo lista ou nao
//existindo o indice, cai no glifo desenhado.
//
//O parametro e TCustomImageList, NAO o tipo do bsfd: o DM.ico_24x24 e um
//TbsPngImageList, que descende de TCustomImageList e sobrescreve o DoDraw --
//entao o Draw padrao ja sai com transparencia. Trocar aquele image list por um
//TImageList comum um dia nao muda nada aqui, e o LCL tem TCustomImageList com
//o mesmo Draw. E o unico ponto da tela que toca em lista de imagens.
procedure DesenhaIcone(cv: TCanvas; const r: TRect; lista: TCustomImageList;
  indice: Integer; alternativo: TGlifo; cor: TColor;
  habilitado: Boolean = True; fundo: TColor = clNone);

procedure PreparaFonte(cv: TCanvas; altura: Integer; negrito: Boolean;
  cor: TColor; riscado: Boolean = False);

//Texto de uma linha, centrado na vertical, com reticencias quando nao couber.
//
//Escrito com TextOut/TextWidth de proposito: TCanvas.TextRect tem assinaturas
//DIFERENTES na VCL e no LCL, e seria o unico ponto do desenho a precisar de
//conversao no porte.
procedure DesenhaTexto(cv: TCanvas; const r: TRect; const s: string;
  alinha: TAlinhaTexto);

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

function CorRGB(r, g, b: Byte): TColor;
begin
  Result := TColor(r or (g shl 8) or (b shl 16));
end;

function Mistura(a, b: TColor; pesoB: Integer): TColor;
var
  pa: Integer;
begin
  if (pesoB < 0) then
    pesoB := 0;
  if (pesoB > 100) then
    pesoB := 100;
  pa := 100 - pesoB;

  //Os bytes saem por aritmetica, nao por GetRValue, que vem do Windows.
  Result := CorRGB(
    ((a and $FF) * pa + (b and $FF) * pesoB) div 100,
    (((a shr 8) and $FF) * pa + ((b shr 8) and $FF) * pesoB) div 100,
    (((a shr 16) and $FF) * pa + ((b shr 16) and $FF) * pesoB) div 100);
end;

//Luminancia aproximada, com os pesos de sempre (30/59/11).
//
//O TColor e $00BBGGRR, entao o vermelho esta no byte BAIXO -- trocar a ordem
//faz a conta PARECER certa e dar resultado invertido em cor saturada. O
//ColorToRGB resolve cor de sistema (clBtnFace e companhia), que nao tem os
//bytes no valor.
function Luminancia(c: TColor): Integer;
var
  v: Integer;
begin
  v := ColorToRGB(c);
  Result := ((v and $FF) * 30 + ((v shr 8) and $FF) * 59 +
             ((v shr 16) and $FF) * 11) div 100;
end;

function CorEscura(c: TColor): Boolean;
begin
  Result := Luminancia(c) < 128;
end;

function CorDeTextoSobre(c: TColor): TColor;
begin
  //Quase-preto, e nao preto: sobre cor clara o preto puro fica duro.
  if CorEscura(c) then
    Result := TColor($00FFFFFF)
  else
    Result := TColor($00202020);
end;

function TemaEscuro: Boolean;
begin
  Result := CorEscura(COR_FUNDO);
end;

procedure AplicaPaleta(fundo, item, texto, selecao, textoSelecao, sombra,
  acento: TColor);
begin
  //Skin que nao carregou devolve tudo igual (normalmente zero). Nesse caso o
  //padrao escrito nas variaveis e melhor do que o que viesse dali.
  if (item = texto) or (fundo = texto) then
    Exit;

  //O CARTAO NUNCA E MAIS ESCURO QUE A SUPERFICIE DO PROGRAMA.
  //
  //O `item` chega como cWindow, que e a cor de CAIXA DE TEXTO do skin, e
  //nos dois temas escuros daqui ela e PRETO PURO -- enquanto o cBtnFace,
  //que e a cor dos paineis, e ardosia (55,66,79) no "Escuro - Cinza" e
  //preto no "Escuro - Preto". Medido descompactando o [SKINCOLORS] de
  //dentro de cada skin (scratchpad/teste/mede-skins.ps1), nao suposto.
  //
  //Resultado: a lista saia PRETA nos dois, e no cinza ficava um buraco no
  //meio de um programa ardosia -- foi o que o usuario relatou, na liturgia
  //e no painel das coletaneas, que leem a mesma paleta.
  //
  //A lista nao e uma caixa de texto: no .dfm antigo cada item era um
  //TbsSkinPanel com SkinDataName = 'panel', ou seja a superficie do
  //programa. Entao o piso do cartao e o fundo. Nos temas claros isto nao
  //muda nada (branco ja e mais claro que o $F1F1F1 do painel).
  if (Luminancia(item) < Luminancia(fundo)) then
    item := fundo;

  COR_FUNDO := fundo;
  COR_ITEM := item;
  COR_TEXTO := texto;
  COR_ITEM_SEL := selecao;
  COR_TEXTO_SEL := textoSelecao;
  COR_ACENTO := acento;

  //As derivadas. Misturar com o TEXTO (e nao clarear ou escurecer por um
  //valor fixo) e o que faz isso valer nos dois sentidos: num tema claro a
  //mistura escurece, num escuro ela clareia.
  COR_ITEM_SOB := Mistura(item, selecao, 20);
  COR_SEPARADOR := Mistura(item, sombra, 45);
  COR_TEXTO_FRACO := Mistura(item, texto, 55);
  COR_ACAO := Mistura(item, texto, 78);
  COR_ACAO_SOB := texto;
  COR_REALCE := Mistura(fundo, texto, 14);
  COR_TRILHO := Mistura(fundo, sombra, 30);
  COR_POLEGAR := Mistura(fundo, texto, 30);
  COR_POLEGAR_SOB := Mistura(fundo, texto, 50);
end;

function QuadradoCentral(const r: TRect; lado: Integer): TRect;
var
  x, y: Integer;
begin
  x := r.Left + ((r.Right - r.Left) - lado) div 2;
  y := r.Top + ((r.Bottom - r.Top) - lado) div 2;
  Result := Rect(x, y, x + lado, y + lado);
end;

type
  //Um pixel de DIB de 24 bits. A ordem na MEMORIA e B,G,R -- ao contrario do
  //TColor, que e $00BBGGRR e tem o vermelho no byte baixo.
  TPixelBGR = packed record
    b, g, r: Byte;
  end;
  PPixelBGR = ^TPixelBGR;

var
  //Rascunho reaproveitado entre desenhos: a tela e pintada por uma thread so
  //(a da interface), entao um por unit basta. Isto e MAIS BARATO que o caminho
  //do componente, que clonava o PNG a cada icone apagado.
  rascunhoApagado: TBitmap = nil;

  //Os dois do antisserrilhado do glifo: a mascara ampliada e o retangulo
  //de destino ja composto. Mesmo motivo do de cima -- uma thread so pinta.
  mascaraGlifo: TBitmap = nil;
  alvoGlifo: TBitmap = nil;

//PORTE: esta e a unica rotina da unit que toca em pixel. O ScanLine existe no
//TBitmap da VCL; no LCL o acesso e por TLazIntfImage. Uma funcao a reescrever.
procedure desenhaApagado(cv: TCanvas; x, y: Integer; lista: TCustomImageList;
  indice: Integer; fundo: TColor);
var
  bmp: TBitmap;
  c: TColor;
  fr, fg, fb: Integer;
  lin, col: Integer;
  p: PPixelBGR;
begin
  if (rascunhoApagado = nil) then
  begin
    rascunhoApagado := TBitmap.Create;
    rascunhoApagado.PixelFormat := pf24bit;
  end;
  bmp := rascunhoApagado;

  if (bmp.Width <> lista.Width) or (bmp.Height <> lista.Height) then
  begin
    bmp.Width := lista.Width;
    bmp.Height := lista.Height;
  end;

  //Pinta a cor da LINHA e desenha o icone inteiro em cima: o alfa do PNG
  //resolve contra essa cor e o resultado fica opaco. E por isso que a cor do
  //fundo precisa vir de fora -- linha normal, sob o mouse e selecionada tem
  //cada uma a sua.
  c := ColorToRGB(fundo);
  bmp.Canvas.Brush.Style := bsSolid;
  bmp.Canvas.Brush.Color := c;
  bmp.Canvas.FillRect(Rect(0, 0, bmp.Width, bmp.Height));
  lista.Draw(bmp.Canvas, 0, 0, indice, True);

  fr := c and $FF;
  fg := (c shr 8) and $FF;
  fb := (c shr 16) and $FF;

  //Cada pixel volta na direcao do fundo, sobrando FORCA_APAGADO%.
  for lin := 0 to bmp.Height - 1 do
  begin
    p := PPixelBGR(bmp.ScanLine[lin]);
    for col := 0 to bmp.Width - 1 do
    begin
      p^.b := Byte(fb + ((p^.b - fb) * FORCA_APAGADO) div 100);
      p^.g := Byte(fg + ((p^.g - fg) * FORCA_APAGADO) div 100);
      p^.r := Byte(fr + ((p^.r - fr) * FORCA_APAGADO) div 100);
      Inc(p);
    end;
  end;

  cv.Draw(x, y, bmp);
end;

procedure DesenhaIcone(cv: TCanvas; const r: TRect; lista: TCustomImageList;
  indice: Integer; alternativo: TGlifo; cor: TColor;
  habilitado: Boolean; fundo: TColor);
var
  x, y: Integer;
begin
  //clNone = 'nao me disseram': cai na cor normal da linha.
  if (fundo = clNone) then
    fundo := COR_ITEM;

  if (lista <> nil) and (indice >= 0) and (indice < lista.Count) then
  begin
    x := r.Left + ((r.Right - r.Left) - lista.Width) div 2;
    y := r.Top + ((r.Bottom - r.Top) - lista.Height) div 2;
    if habilitado then
      lista.Draw(cv, x, y, indice, True)
    else
      //NAO usa o Enabled = False do componente: ele tem alfa 127 fixo. Ver o
      //desenhaApagado logo acima.
      desenhaApagado(cv, x, y, lista, indice, fundo);
    Exit;
  end;

  //Sem lista de imagens, o glifo desenhado faz o mesmo papel misturando a
  //cor com o fundo, que e o que 'apagado' significa num tema qualquer.
  if not habilitado then
    cor := Mistura(fundo, cor, FORCA_APAGADO);
  DesenhaGlifo(cv, QuadradoCentral(r, 24), alternativo, cor);
end;

procedure PreparaFonte(cv: TCanvas; altura: Integer; negrito: Boolean;
  cor: TColor; riscado: Boolean);
begin
  cv.Font.Name := FONTE_UI;
  //Negativo = altura do caractere, nos dois frameworks. Positivo seria a
  //altura da celula, que e o que o .dfm antigo usa -- e por isso rende letra
  //menor do que o numero sugere.
  cv.Font.Height := -altura;
  //O riscado e o item de liturgia ja realizado: era [fsBold, fsStrikeOut]
  //no TbsSkinStdLabel. fsStrikeOut existe igual no LCL.
  cv.Font.Style := [];
  if negrito then
    cv.Font.Style := cv.Font.Style + [fsBold];
  if riscado then
    cv.Font.Style := cv.Font.Style + [fsStrikeOut];
  cv.Font.Color := cor;
  cv.Brush.Style := bsClear;
end;

procedure DesenhaTexto(cv: TCanvas; const r: TRect; const s: string;
  alinha: TAlinhaTexto);
var
  t: string;
  larg, w, h, x, y: Integer;
begin
  if (s = '') then
    Exit;

  larg := r.Right - r.Left;
  if (larg <= 0) then
    Exit;

  t := s;
  w := cv.TextWidth(t);

  if (w > larg) then
  begin
    while (Length(t) > 1) and (cv.TextWidth(t + '...') > larg) do
      Delete(t, Length(t), 1);
    t := t + '...';
    w := cv.TextWidth(t);
  end;

  h := cv.TextHeight('Ag');

  case alinha of
    alinCentro: x := r.Left + (larg - w) div 2;
    alinDireita: x := r.Right - w;
  else
    x := r.Left;
  end;

  y := r.Top + ((r.Bottom - r.Top) - h) div 2;

  cv.Brush.Style := bsClear;
  cv.TextOut(x, y, t);
end;

//O glifo CRU, sem suavizar: e o que desenha de fato. Quem chama de fora e
//o DesenhaGlifo logo abaixo, que o usa como mascara.
procedure desenhaGlifoCru(cv: TCanvas; const r: TRect; glifo: TGlifo;
  cor: TColor);

  function px(x: Integer): Integer;
  begin
    Result := r.Left + (x * (r.Right - r.Left)) div 24;
  end;

  function py(y: Integer): Integer;
  begin
    Result := r.Top + (y * (r.Bottom - r.Top)) div 24;
  end;

  function pt(x, y: Integer): TPoint;
  begin
    Result.X := px(x);
    Result.Y := py(y);
  end;

  //A espessura TEM de escalar junto com o glifo. O Pen.Width e em pixels e
  //nao acompanha o retangulo -- e o DesenhaGlifo agora desenha isto aqui
  //AMPLIADO, para servir de mascara. Sem esta conta as linhas sairiam
  //finas 4x e os glifos de traco virariam fio de cabelo.
  function esp(n: Integer): Integer;
  begin
    Result := Round(n * (r.Right - r.Left) / 24);
    if (Result < 1) then
      Result := 1;
  end;

  procedure linha(x1, y1, x2, y2: Integer);
  begin
    cv.Pen.Style := psSolid;
    cv.Pen.Color := cor;
    cv.Pen.Width := esp(2);
    cv.MoveTo(px(x1), py(y1));
    cv.LineTo(px(x2), py(y2));
  end;

  procedure moldura(x1, y1, x2, y2: Integer);
  begin
    cv.Pen.Style := psSolid;
    cv.Pen.Color := cor;
    cv.Pen.Width := esp(2);
    cv.Brush.Style := bsClear;
    cv.Rectangle(px(x1), py(y1), px(x2), py(y2));
  end;

  procedure play(x, y, tam: Integer);
  begin
    cv.Pen.Style := psClear;
    cv.Brush.Style := bsSolid;
    cv.Brush.Color := cor;
    cv.Polygon([pt(x, y), pt(x, y + tam), pt(x + tam, y + tam div 2)]);
    cv.Pen.Style := psSolid;
  end;

  procedure nota(x: Integer);
  begin
    cv.Pen.Style := psClear;
    cv.Brush.Style := bsSolid;
    cv.Brush.Color := cor;
    cv.Ellipse(px(x), py(15), px(x + 8), py(21));
    cv.Pen.Style := psSolid;
    linha(x + 7, 18, x + 7, 4);
    linha(x + 7, 4, x + 14, 6);
  end;

  //Duas colcheias ligadas pela barra -- a nota de DUAS PERNAS.
  //
  //NAO reaproveita a `nota` acima de proposito: aquela e a ACAO 'audio
  //cantado' (glAudioCantado/glAudioPlayback), e as duas aparecem na mesma
  //tela da liturgia -- o tipo do item a esquerda e a faixa de acoes a
  //direita. Mesmo desenho para coisas diferentes confunde, e o playback
  //ainda precisa do espaco da barrinha em x = 20.
  //
  //Tudo preenchido, sem Pen: a espessura do Pen NAO escala junto com o
  //glifo, entao num retangulo maior o traco sairia fino demais.
  //Uma cabeca de nota: elipse INCLINADA, como na notacao de verdade.
  //
  //Sai de Polygon e nao de Ellipse porque o Ellipse do GDI e sempre alinhado
  //aos eixos, e a inclinacao e justamente o que faz a cabeca parecer uma nota
  //em vez de um ponto. Recebe Double porque o centro cai em meia unidade da
  //grade -- arredondar antes deslocaria a cabeca em 1px, que aqui e muito.
  procedure cabeca(cx, cy, larg, alt: Double);
  const
    LADOS = 16;      //poligono de 16 lados ja e redondo nesta escala
    INCL  = -0.42;   //radianos, ~24 graus: a ponta direita sobe
  var
    i: Integer;
    a, ex, ey, sn, cs: Double;
    pts: array[0..LADOS - 1] of TPoint;
  begin
    sn := Sin(INCL);
    cs := Cos(INCL);
    for i := 0 to LADOS - 1 do
    begin
      a := 2 * Pi * i / LADOS;
      ex := (larg / 2) * Cos(a);
      ey := (alt / 2) * Sin(a);
      pts[i].X := r.Left + Round((cx + ex * cs - ey * sn) * (r.Right - r.Left) / 24);
      pts[i].Y := r.Top  + Round((cy + ex * sn + ey * cs) * (r.Bottom - r.Top) / 24);
    end;
    cv.Polygon(pts);
  end;

  //Duas colcheias ligadas pela barra -- a nota de DUAS PERNAS.
  //
  //NAO reaproveita a `nota` simples acima de proposito: aquela e a ACAO
  //'audio cantado' (glAudioCantado/glAudioPlayback), e as duas aparecem na
  //mesma tela da liturgia -- o tipo do item a esquerda e a faixa de acoes a
  //direita. Mesmo desenho para coisas diferentes confunde, e o playback ainda
  //precisa do espaco da barrinha em x = 20.
  //
  //AS MEDIDAS SAIRAM DO EMOJI, nao do chute: o U+266B foi reamostrado nesta
  //mesma grade de 24 (scratchpad/teste/mede-emoji.ps1) e o que ele mostrou foi
  //que a nota e quase QUADRADA (59x62 na imagem) e ocupa a grade inteira. A
  //versao anterior era larga e baixa, e era isso que a deixava estranha.
  //Uma linha da lista com marcador: o ponto e a barra.
  procedure itemLista(y: Integer);
  begin
    cv.Ellipse(px(1), py(y), px(6), py(y + 5));
    cv.RoundRect(px(9), py(y), px(23), py(y + 5), esp(5), esp(5));
  end;

  procedure notaDupla;
  const
    X1    = 6;    //x da haste esquerda
    X2    = 20;   //x da direita
    HASTE = 3;
    TOPO  = 2;    //y do topo da barra, do lado esquerdo
    SOBE  = 2;    //quanto ela sobe da esquerda para a direita
    BARRA = 4;    //espessura dela
    //As duas cabecas em ALTURAS DIFERENTES, como duas notas ligadas pela
    //barra. Na mesma linha elas encostam uma na outra -- nao cabe afastar
    //mais dentro de 24 -- e viram um borrao so.
    PE1   = 19;   //centro da cabeca da esquerda
    PE2   = 17;   //a da direita fica mais alta
    CAB_L = 9;
    CAB_A = 7;    //mais larga que alta, como cabeca de nota de verdade
  begin
    //CANETA LIGADA, na mesma cor do pincel. Com psClear o GDI preenche a
    //figura MENOS a borda, e numa cabeca deste tamanho isso nao deixa quase
    //nada: a primeira versao saiu com dois pontinhos no lugar delas.
    cv.Pen.Style := psSolid;
    cv.Pen.Width := esp(1);
    cv.Pen.Color := cor;
    cv.Brush.Style := bsSolid;
    cv.Brush.Color := cor;

    //As duas hastes, cada uma descendo ate a sua cabeca.
    cv.Rectangle(px(X1), py(TOPO), px(X1 + HASTE), py(PE1));
    cv.Rectangle(px(X2), py(TOPO - SOBE), px(X2 + HASTE), py(PE2));

    //A barra, inclinada como no simbolo: sobe da esquerda para a direita.
    cv.Polygon([pt(X1, TOPO), pt(X2 + HASTE, TOPO - SOBE),
                pt(X2 + HASTE, TOPO - SOBE + BARRA), pt(X1, TOPO + BARRA)]);

    //As cabecas, penduradas a esquerda da ponta de cada haste.
    cabeca(X1 + HASTE - CAB_L / 2, PE1, CAB_L, CAB_A);
    cabeca(X2 + HASTE - CAB_L / 2, PE2, CAB_L, CAB_A);
  end;
begin
  case glifo of
    glNota:
      notaDupla;

    glPasta:
      begin
        cv.Pen.Style := psClear;
        cv.Brush.Style := bsSolid;
        cv.Brush.Color := cor;
        cv.Polygon([pt(3, 6), pt(10, 6), pt(12, 9), pt(21, 9), pt(21, 19),
                    pt(3, 19)]);
        cv.Pen.Style := psSolid;
      end;

    glSlideCantado:
      begin
        moldura(3, 5, 21, 20);
        play(9, 9, 7);
      end;

    glSlidePlayback:
      begin
        moldura(3, 5, 21, 20);
        play(7, 9, 7);
        linha(17, 9, 17, 16);
      end;

    glSlideSemAudio:
      begin
        moldura(3, 5, 21, 20);
        linha(7, 11, 17, 11);
        linha(7, 15, 14, 15);
      end;

    glAudioCantado:
      nota(5);

    glAudioPlayback:
      begin
        nota(2);
        linha(20, 5, 20, 20);
      end;

    glLetra:
      begin
        linha(4, 9, 20, 9);
        linha(4, 14, 16, 14);
        linha(4, 19, 20, 19);
      end;

    glReproduzirTodas:
      begin
        play(3, 8, 8);
        play(12, 8, 8);
      end;

    glProjetar:
      begin
        moldura(2, 5, 22, 17);
        linha(12, 17, 12, 20);
        linha(8, 20, 16, 20);
      end;

    glSetaBaixo:
      begin
        cv.Pen.Style := psClear;
        cv.Brush.Style := bsSolid;
        cv.Brush.Color := cor;
        cv.Polygon([pt(8, 10), pt(16, 10), pt(12, 16)]);
        cv.Pen.Style := psSolid;
      end;

    glBloco:
      begin
        //Tres pontos e tres barras: a divisoria agrupa os itens abaixo
        //dela, e e isso que o desenho diz.
        //
        //CANETA LIGADA na mesma cor: com psClear o GDI preenche a figura
        //menos a borda, e o ponto tem 5x5 -- do tamanho exato que sumiu
        //quando a cabeca da nota foi desenhada assim.
        cv.Pen.Style := psSolid;
        cv.Pen.Width := esp(1);
        cv.Pen.Color := cor;
        cv.Brush.Style := bsSolid;
        cv.Brush.Color := cor;
        itemLista(3);
        itemLista(10);
        itemLista(17);
      end;

    glItemAcima, glItemAbaixo:
      begin
        //CANETA LIGADA na mesma cor, e nao psClear: a haste tem 4 unidades de
        //largura, e com psClear o GDI preenche a figura menos a borda -- do
        //tamanho exato que sumiu quando a cabeca da nota foi desenhada assim.
        cv.Pen.Style := psSolid;
        cv.Pen.Width := esp(1);
        cv.Pen.Color := cor;
        cv.Brush.Style := bsSolid;
        cv.Brush.Color := cor;

        if (glifo = glItemAcima) then
        begin
          //A barra em cima: e para la que o item novo vai.
          cv.Rectangle(px(4), py(2), px(20), py(5));
          cv.Rectangle(px(10), py(12), px(14), py(22));
          cv.Polygon([pt(5, 13), pt(19, 13), pt(12, 7)]);
        end
        else
        begin
          cv.Rectangle(px(4), py(19), px(20), py(22));
          cv.Rectangle(px(10), py(2), px(14), py(12));
          cv.Polygon([pt(5, 11), pt(19, 11), pt(12, 17)]);
        end;
      end;
  end;

  cv.Pen.Width := 1;
end;

//O glifo, com as bordas suavizadas.
//
//POR QUE PRECISA DISSO: o GDI nao suaviza NADA -- Polygon, Ellipse e Rectangle
//saem com a borda em degrau. Num glifo de 24px feito de diagonais (a nota
//inclinada, a barra inclinada, o triangulo do play) o degrau tem o tamanho do
//traco, e o desenho parece quadriculado. Foi o que o usuario viu na nota.
//
//COMO: desenha numa mascara ESCALA vezes maior, preto sobre branco, e depois
//cada pixel do destino recebe a cor misturada com o que ja estava ali, na
//proporcao de quanto do bloco ESCALA x ESCALA ficou preto. E o filtro de caixa
//de sempre -- a mesma ideia da mascara da arte do .slja (secao 4m), e pelo
//mesmo motivo: desenhar com alfa por primitiva compoe duas vezes na emenda.
//
//O FUNDO VEM DA PROPRIA TELA (CopyRect), nao por parametro: o glifo e pintado
//sobre a cor que o usuario escolheu para o item, sobre o botao da trilha ou
//sobre a linha realcada, e nenhum chamador sabe dizer qual e.
procedure DesenhaGlifo(cv: TCanvas; const r: TRect; glifo: TGlifo; cor: TColor);
const
  ESCALA = 4;        //4x4 = 17 niveis de cobertura, de sobra nesta escala
  LADO_MAX = 160;    //acima disto o degrau ja nao aparece e a mascara custa
var
  w, h, lin, col, sx, sy, soma: Integer;
  c: TColor;
  vr, vg, vb: Integer;
  pm, pa: PPixelBGR;
  linhas: array[0 .. ESCALA - 1] of PPixelBGR;
begin
  if (glifo = glNada) then
    Exit;

  w := r.Right - r.Left;
  h := r.Bottom - r.Top;
  if (w <= 0) or (h <= 0) then
    Exit;

  if (w > LADO_MAX) or (h > LADO_MAX) then
  begin
    desenhaGlifoCru(cv, r, glifo, cor);
    Exit;
  end;

  if (mascaraGlifo = nil) then
  begin
    mascaraGlifo := TBitmap.Create;
    mascaraGlifo.PixelFormat := pf24bit;
    alvoGlifo := TBitmap.Create;
    alvoGlifo.PixelFormat := pf24bit;
  end;

  if (mascaraGlifo.Width <> w * ESCALA) or
     (mascaraGlifo.Height <> h * ESCALA) then
    mascaraGlifo.SetSize(w * ESCALA, h * ESCALA);
  if (alvoGlifo.Width <> w) or (alvoGlifo.Height <> h) then
    alvoGlifo.SetSize(w, h);

  //A mascara, ampliada: preto sobre branco.
  mascaraGlifo.Canvas.Brush.Style := bsSolid;
  mascaraGlifo.Canvas.Brush.Color := clWhite;
  mascaraGlifo.Canvas.FillRect(Rect(0, 0, mascaraGlifo.Width,
    mascaraGlifo.Height));
  desenhaGlifoCru(mascaraGlifo.Canvas, Rect(0, 0, w * ESCALA, h * ESCALA),
    glifo, clBlack);

  //O que ja esta na tela naquele retangulo, para misturar contra.
  alvoGlifo.Canvas.CopyRect(Rect(0, 0, w, h), cv, r);

  c := ColorToRGB(cor);
  vr := c and $FF;
  vg := (c shr 8) and $FF;
  vb := (c shr 16) and $FF;

  for lin := 0 to h - 1 do
  begin
    for sy := 0 to ESCALA - 1 do
      linhas[sy] := PPixelBGR(mascaraGlifo.ScanLine[lin * ESCALA + sy]);
    pa := PPixelBGR(alvoGlifo.ScanLine[lin]);

    for col := 0 to w - 1 do
    begin
      soma := 0;
      for sy := 0 to ESCALA - 1 do
      begin
        pm := linhas[sy];
        Inc(pm, col * ESCALA);
        for sx := 0 to ESCALA - 1 do
        begin
          //Preto = coberto. A mascara nao tem meio-tom nenhum, justamente
          //porque o GDI nao suaviza -- o meio-tom nasce aqui, da contagem.
          if (pm^.r < 128) then
            Inc(soma);
          Inc(pm);
        end;
      end;

      if (soma > 0) then
      begin
        pa^.b := Byte(pa^.b + ((vb - pa^.b) * soma) div (ESCALA * ESCALA));
        pa^.g := Byte(pa^.g + ((vg - pa^.g) * soma) div (ESCALA * ESCALA));
        pa^.r := Byte(pa^.r + ((vr - pa^.r) * soma) div (ESCALA * ESCALA));
      end;
      Inc(pa);
    end;
  end;

  cv.Draw(r.Left, r.Top, alvoGlifo);
end;
initialization

finalization
  rascunhoApagado.Free;
  mascaraGlifo.Free;
  alvoGlifo.Free;

end.
