unit uItensLiturgia;

//O item da liturgia: o modelo e as regras, sem nada que desenhe.
//
//Unit pura, no modelo da regra 5b -- sem VCL, sem Windows, sem referencia a
//form. Porta para o Lazarus sem alterar uma linha.
//
//O QUE ISTO SUBSTITUI. Hoje o `carregaItemLiturgia` (196 linhas no fmMenu.pas)
//faz tres coisas de uma vez: le os parametros do item, decide o icone e o
//tamanho, e CLONA de 8 a 14 componentes por item com `CopyComponent`, achando
//cada um depois por `FindComponent(item + '_bticon_img')`. Sao 24 buscas por
//nome montado. Aqui ficam as duas primeiras coisas; o desenho e de quem
//desenha, e o item passa a ser indice de array em vez de componente com nome.
//
//AS SEIS ACOES SAO AS MESMAS DO MENU DE MUSICAS, conferido byte a byte: os
//`lit_modItem_icomus1..6` do fmMenu.dfm trazem os indices 76, 82, 77, 75, 35 e
//63 nos Tags 1..6 -- identicos aos do `uMenuMusicas`, e com a mesma regra de
//playback (`URL_INSTRUMENTAL <> ''`). Por isso esta unit nao redeclara acao
//nenhuma: ela usa o `TAcaoItem` de la. Foi o aparecimento deste segundo
//consumidor que tirou os indices de dentro do controle da lista de musicas.

interface

uses
  uMenuMusicas;

const
  //Os tipos, como o INI guarda. O `bloco` e a grafia nova de `categoria` e o
  //`itens-agendados` a de `itensagendados` -- as duas valem na leitura, como o
  //uLiturgiaTroca ja fazia.
  TIPO_ANOTACAO        = 'anotacao';
  TIPO_ARQUIVO         = 'arquivo';
  TIPO_BLOCO           = 'bloco';
  TIPO_BLOCO_LEGADO    = 'categoria';
  TIPO_AGENDADOS       = 'itens-agendados';
  TIPO_AGENDADOS_LEGADO = 'itensagendados';
  TIPO_MUSICA          = 'musica';
  TIPO_SITE            = 'site';

  //Os subtipos que o INI guarda. Os tres primeiros valem so para musica, e
  //HOJE NADA OS LE: o icone do item de musica deixou de depender da
  //coletanea -- ver o IconeDoItem. Ficam porque nomeiam valor que esta
  //gravado em liturgia de usuario e que o fmLiturgia continua escrevendo.
  SUB_HASD = 'hasd';
  SUB_JA   = 'ja';
  SUB_DIV  = 'div';
  SUB_DIR  = 'dir';
  SUB_ARQ  = 'arq';

  //A chave que guarda o modo de abertura, e o modo que vale quando ela nao
  //existe. Ver ModoDoParam.
  CHAVE_MODO = 'modo';
  MODO_PADRAO = acSlideCantado;

  //Indices no DM.ico_24x24, lidos dos lit_modItem* do fmMenu.dfm. Estavam
  //espalhados pelo carregaItemLiturgia como numero cru.
  //
  //OS QUATRO DE MUSICA (47 HASD, 46 Novo Tempo, 45 Diversas, 60 outra) NAO
  //ESTAO AQUI, e nao e esquecimento. Eram LOGOTIPO DE COLETANEA: diziam de
  //que album a musica veio, que nao e o que o item E. E, como a alca de
  //arrastar (secao 4k), foram desenhados para o fundo escuro que o
  //lit_modItem_bticon tinha (Color = $004F0000), entao sobre item de cor
  //clara eles desapareciam. Musica passou a ser uma NOTA DESENHADA, que
  //tira a cor do tema: o IconeDoItem devolve -1 e quem desenha usa o
  //glNota do uTema.
  ICONE_SITE_YOUTUBE = 38;
  ICONE_SITE         = 49;
  ICONE_PASTA        = 32;
  ICONE_ARQUIVO      = 4;
  ICONE_ANOTACAO     = 63;
  ICONE_AGENDADOS    = 83;

  //O 81 (a seta de arrastar) NAO esta aqui de proposito: ele foi desenhado
  //para fundo preto (o lit_modItem_btmove era Color = clBlack) e desaparecia
  //em tema claro. A alca passou a ser desenhada pelo uListaLiturgia, com cor
  //do tema -- ver o desenhaAlca de la.

  //O lapis de editar e o UNICO que nao vem do ico_24x24: o
  //lit_modItem_btedit usa o DM.ico_16x16.
  ICONE_EDITAR_16 = 16;

  //Alturas do .dfm de hoje: item comum 56, divisoria 36 com 20 de respiro em
  //cima (era Margins.Top).
  ALTURA_ITEM       = 56;
  ALTURA_DIVISORIA  = 36;
  RESPIRO_DIVISORIA = 20;

  //O que o `cor` traz quando o item nao tem cor gravada. E o mesmo default
  //que o carregaItemLiturgia usa nos tres lerParam de cor.
  COR_PADRAO = '$004F0000';

type
  TItemLiturgia = record
    //O nome da secao no INI/JSON. Era o nome do componente; agora e so
    //identidade -- quem localiza o item na tela e o indice no array.
    ident: string;

    tipo: string;
    subtipo: string;

    //O rotulo de cima (chave `item`) e o de baixo (chave `subitem`, ou o
    //texto do arquivo agendado, que o chamador resolve porque depende de
    //data e de dataset).
    titulo: string;
    subtitulo: string;

    //Como o INI guarda: `$00BBGGRR` ou identificador (`clNavy`). Fica texto
    //aqui de proposito: converter exige Graphics, que esta unit nao usa.
    cor: string;

    //`checked` igual a hoje.
    marcado: Boolean;

    //So valem para tipo musica. `acoes` e o que o item FAZ; `possiveis` e o
    //que ele MOSTRA -- o que esta em possiveis e nao em acoes sai apagado,
    //igual ao menu de musicas.
    acoes: TAcoesItem;
    possiveis: TAcoesItem;

    //Como o clique no CORPO do item abre a musica (chave `modo`). So vale
    //para tipo musica, e o padrao e o MODO_PADRAO -- ver ModoDoParam.
    modo: TAcaoItem;
  end;

  TItensLiturgia = array of TItemLiturgia;

//Divisoria e o item que nao e tocavel: a reproducao tem `if tipo <>
//'categoria'` em dois pontos, e na tela ele e uma barra colorida com o titulo
//centralizado, sem icone, sem check e sem acao.
function EhDivisoria(const tipo: string): Boolean;
function EhMusica(const tipo: string): Boolean;

//Mesma deteccao do carregaItemLiturgia de hoje, que olha quatro formas.
function EhYoutube(const url: string): Boolean;

//O icone do tipo, no ico_24x24. -1 quando o tipo nao tem icone DA LISTA:
//divisoria, que nao tem icone nenhum, e musica, que e desenhada como nota
//-- ver o comentario dos ICONE_* e o EhMusica.
function IconeDoItem(const tipo, subtipo, subitem: string): Integer;

//Altura da linha, e o respiro que vem antes dela.
function AlturaDoItem(const tipo: string): Integer;
function RespiroDoItem(const tipo: string): Integer;

//As seis acoes do item de musica. Delegam para o uMenuMusicas: a regra e a
//mesma, e tela que repete regra e tela que diverge com o tempo.
function AcoesDaMusica(temPlayback: Boolean): TAcoesItem;
function PossiveisDaMusica: TAcoesItem;

//O modo guardado na chave `modo`, que diz como o clique no CORPO do item
//abre a musica.
//
//VALOR AUSENTE E O MODO_PADRAO, E ISSO PRESERVA O COMPORTAMENTO ANTIGO BYTE A
//BYTE: o clique no corpo sempre passou `tag = 0` ao executaItemLiturgia, que
//cai no ramo final com txt vazio (porque tag <> 2) e `tag < 3` verdadeiro --
//ou seja exatamente o tag 1, o slide cantado. Entao liturgia gravada antes
//desta chave existir continua abrindo igual, sem migracao nenhuma.
//
//O acLetra (tag 6) NAO e modo: ele nao e um jeito de abrir a musica, e ja tem
//botao proprio na faixa de acoes. Valor que caia nele volta ao padrao.
function ModoDoParam(const v: string): TAcaoItem;

//O valor a gravar na chave. Vazio para o padrao, porque campo vazio nao e
//gravado (TStringList.Values[x] := '' apaga a entrada) e assim o arquivo de
//quem nao mexeu no modo continua sem a chave.
function ParamDoModo(modo: TAcaoItem): string;

//A tag ao lado do nome aparece SO quando o modo nao e o padrao: item comum
//fica sem tag, e a tag passa a significar "atencao, este abre diferente".
function MostraTagDoModo(const tipo: string; modo: TAcaoItem): Boolean;

implementation

uses
  System.SysUtils;

function EhDivisoria(const tipo: string): Boolean;
begin
  Result := SameText(tipo, TIPO_BLOCO) or SameText(tipo, TIPO_BLOCO_LEGADO);
end;

function EhMusica(const tipo: string): Boolean;
begin
  Result := SameText(tipo, TIPO_MUSICA);
end;

function EhYoutube(const url: string): Boolean;
var
  u: string;
begin
  u := LowerCase(url);
  Result := (Pos('.youtube.', u) > 0) or (Pos('/youtube.', u) > 0)
         or (Pos('.youtu.be.', u) > 0) or (Pos('/youtu.be.', u) > 0);
end;

function IconeDoItem(const tipo, subtipo, subitem: string): Integer;
begin
  Result := -1;

  //Musica nao entra: ela e desenhada como nota, pelos dois motivos do
  //comentario dos ICONE_*.
  if SameText(tipo, TIPO_SITE) then
  begin
    if EhYoutube(subitem) then
      Result := ICONE_SITE_YOUTUBE
    else
      Result := ICONE_SITE;
  end
  else if SameText(tipo, TIPO_ARQUIVO) then
  begin
    if SameText(subtipo, SUB_DIR) then
      Result := ICONE_PASTA
    else if SameText(subtipo, SUB_ARQ) then
      Result := ICONE_ARQUIVO;
  end
  else if SameText(tipo, TIPO_ANOTACAO) then
    Result := ICONE_ANOTACAO
  else if SameText(tipo, TIPO_AGENDADOS)
       or SameText(tipo, TIPO_AGENDADOS_LEGADO) then
    Result := ICONE_AGENDADOS;
end;

function AlturaDoItem(const tipo: string): Integer;
begin
  if EhDivisoria(tipo) then
    Result := ALTURA_DIVISORIA
  else
    Result := ALTURA_ITEM;
end;

function RespiroDoItem(const tipo: string): Integer;
begin
  if EhDivisoria(tipo) then
    Result := RESPIRO_DIVISORIA
  else
    Result := 0;
end;

function AcoesDaMusica(temPlayback: Boolean): TAcoesItem;
begin
  Result := AcoesDoAcervo(temPlayback);
end;

function PossiveisDaMusica: TAcoesItem;
begin
  Result := PossiveisDoAcervo;
end;

function ModoDoParam(const v: string): TAcaoItem;
begin
  if not AcaoDoTag(StrToIntDef(Trim(v), 0), Result) then
    Result := MODO_PADRAO
  else if (Result = acLetra) then
    Result := MODO_PADRAO;
end;

function ParamDoModo(modo: TAcaoItem): string;
begin
  if (modo = MODO_PADRAO) or (modo = acLetra) then
    Result := ''
  else
    Result := IntToStr(TagDaAcao(modo));
end;

function MostraTagDoModo(const tipo: string; modo: TAcaoItem): Boolean;
begin
  Result := EhMusica(tipo) and (modo <> MODO_PADRAO) and (modo <> acLetra);
end;

end.
