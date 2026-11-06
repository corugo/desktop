unit uMenuMusicas;

//Modelo do item do menu de musicas.
//
//Unit PURA no molde do uAgendados/uLiturgiaTroca (regra 5b do CLAUDE.md): sem
//VCL, sem Windows, sem referencia a form e sem DataSet. Porta para o Lazarus
//sem alterar uma linha.
//
//O desenho e deliberado: hoje o fmListaMusica le o registro atual do
//TDBCtrlGrid dentro do OnPaintPanel, e e dai que vem a complicacao toda --
//um jogo unico de botoes reconfigurado por linha, o estado da linha ativa
//guardado em campo do form e devolvido depois do WM_PAINT. Com a lista
//recebendo os itens de uma vez, essa engenhoca deixa de existir.

interface

type
  //A ordem e a mesma dos Tags 1..6 dos botoes do fmListaMusica atual, e e
  //tambem a ordem em que eles aparecem da esquerda para a direita. Manter
  //assim e o que faz a integracao ser so trocar quem desenha.
  TAcaoItem = (
    acSlideCantado,    //Tag 1 -- bsPngImageView1
    acSlidePlayback,   //Tag 2 -- btSlidePB
    acSlideSemAudio,   //Tag 3 -- btSlideLetra
    acAudioCantado,    //Tag 4 -- btMusica
    acAudioPlayback,   //Tag 5 -- btMusicaPB
    acLetra);          //Tag 6 -- btLetra

  TAcoesItem = set of TAcaoItem;

  TItemMenu = record
    faixa: Integer;
    nome: string;
    //O que este item FAZ. So estas sao clicaveis.
    acoes: TAcoesItem;
    //O que este item MOSTRA, que e um superconjunto de 'acoes': o que esta
    //aqui e nao esta la aparece em cinza, apagado, sem reagir ao clique.
    //
    //Antes a coluna simplesmente ficava vazia, e vazio nao diz nada: musica
    //sem playback parecia igual a uma coluna que ninguem usa. O botao apagado
    //diz que a acao existe e que esta musica nao a tem.
    possiveis: TAcoesItem;
    //0 = musica do acervo, 1 = arquivo de pasta. Virou numero em vez de TGlifo
    //para esta unit nao depender do tema (que depende de Graphics).
    tipo: Integer;
    //Posicao do registro no dataset, contando de zero. Guardada porque a lista
    //pode estar FILTRADA: o indice do item na tela deixa de ser o do dataset, e
    //e por este campo que o cursor e posicionado antes de agir.
    pos: Integer;
  end;

  TItensMenu = array of TItemMenu;

const
  TIPO_ACERVO = 0;
  TIPO_ARQUIVO = 1;

//Tag do fmListaMusica <-> acao. A ida aceita qualquer inteiro, porque o Tag
//vem de componente e pode ser qualquer coisa.
function AcaoDoTag(tag: Integer; out acao: TAcaoItem): Boolean;
function TagDaAcao(acao: TAcaoItem): Integer;

function NomeDaAcao(acao: TAcaoItem): string;
function NomeDaAcaoApagada(acao: TAcaoItem): string;
function ContaAcoes(const acoes: TAcoesItem): Integer;

//Decide quais botoes um item do ACERVO oferece, com a mesma regra do
//DBCtrlGridPaintPanel de hoje: no acervo tudo existe, menos o playback, que
//depende de URL_INSTRUMENTAL estar preenchido.
function PossiveisDoAcervo: TAcoesItem;
function PossiveisDaPasta(ehSlide: Boolean): TAcoesItem;
function AcoesDoAcervo(temPlayback: Boolean): TAcoesItem;

//A mesma coisa para coletanea personalizada (o outro ramo do mesmo metodo).
function AcoesDaPasta(ehSlide, temCantado, temPlayback, temAudio,
  temAudioPB: Boolean): TAcoesItem;

//Texto sem acento, para o filtro achar "Oracao" quando o nome e "Oracao" com
//cedilha e til. Mapa fixo do Latin-1, sem depender de localidade.
function SemAcento(const s: string): string;

//Os itens que casam com o termo digitado. Termo so de digitos casa pelo NUMERO
//da faixa (prefixo, para ir estreitando conforme digita); qualquer outra coisa
//casa por pedaco do nome, sem acento e sem distinguir maiuscula.
//
//Funcao pura de proposito: e a regra que mais vale testar, e assim da para
//exercita-la num console sem subir a interface.
function FiltraItens(const itens: TItensMenu; const termo: string): TItensMenu;

//Amostra para exercitar a tela sem banco e sem pasta (testes e demonstracao).
function ItensDeAmostra: TItensMenu;

implementation

uses
  System.SysUtils;

const
  ACENTOS_DE   = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
  ACENTOS_PARA = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';

function SemAcento(const s: string): string;
var
  i, k: Integer;
begin
  Result := s;
  for i := 1 to Length(Result) do
  begin
    k := Pos(Result[i], ACENTOS_DE);
    if (k > 0) then
      Result[i] := ACENTOS_PARA[k];
  end;
end;

function FiltraItens(const itens: TItensMenu; const termo: string): TItensMenu;
var
  t: string;
  i, j, n: Integer;
  soDigitos: Boolean;
begin
  t := Trim(termo);

  if (t = '') then
  begin
    Result := itens;
    Exit;
  end;

  soDigitos := True;
  for j := 1 to Length(t) do
    if (t[j] < '0') or (t[j] > '9') then
    begin
      soDigitos := False;
      Break;
    end;

  t := UpperCase(SemAcento(t));

  SetLength(Result, Length(itens));
  n := 0;

  for i := 0 to High(itens) do
    //Pos(...) = 1 e "comeca com": digitar 1 traz 1, 10, 100 -- e nao 21.
    if (soDigitos and (Pos(t, IntToStr(itens[i].faixa)) = 1)) or
       (Pos(t, UpperCase(SemAcento(itens[i].nome))) > 0) then
    begin
      Result[n] := itens[i];
      Inc(n);
    end;

  SetLength(Result, n);
end;

function AcaoDoTag(tag: Integer; out acao: TAcaoItem): Boolean;
begin
  Result := (tag >= 1) and (tag <= Ord(High(TAcaoItem)) + 1);
  if Result then
    acao := TAcaoItem(tag - 1)
  else
    acao := acSlideCantado;
end;

function TagDaAcao(acao: TAcaoItem): Integer;
begin
  Result := Ord(acao) + 1;
end;

function NomeDaAcaoApagada(acao: TAcaoItem): string;
begin
  //O conjunto nao guarda o MOTIVO da ausencia -- e no acervo ele e sempre o
  //mesmo (a musica nao tem playback), mas numa pasta pode ser falta do
  //arquivo cantado, do playback ou da faixa dentro do pacote. Entao a legenda
  //diz o que seria e que nao da, sem inventar causa.
  Result := NomeDaAcao(acao);
  if (Result <> '') then
    Result := Result + ' (indisponível)';
end;

function NomeDaAcao(acao: TAcaoItem): string;
begin
  case acao of
    acSlideCantado: Result := 'Slide cantado';
    acSlidePlayback: Result := 'Slide playback';
    acSlideSemAudio: Result := 'Slide sem áudio';
    acAudioCantado: Result := 'Áudio cantado';
    acAudioPlayback: Result := 'Áudio playback';
    acLetra: Result := 'Letra da música';
  else
    Result := '';
  end;
end;

function ContaAcoes(const acoes: TAcoesItem): Integer;
var
  ac: TAcaoItem;
begin
  Result := 0;
  for ac := Low(TAcaoItem) to High(TAcaoItem) do
    if (ac in acoes) then
      Inc(Result);
end;

function PossiveisDoAcervo: TAcoesItem;
begin
  //No acervo as seis existem; o que varia e so o par de playback, que
  //depende de URL_INSTRUMENTAL. Logo, as seis colunas aparecem sempre.
  Result := [acSlideCantado, acSlidePlayback, acSlideSemAudio,
    acAudioCantado, acAudioPlayback, acLetra];
end;

function PossiveisDaPasta(ehSlide: Boolean): TAcoesItem;
begin
  //Arquivo que nao e pacote de slides continua sem botao NENHUM -- nem
  //apagado. O corpo do item abre o arquivo, e seis colunas mortas numa pasta
  //de mp3 seriam um terco da largura gasto em nada.
  if not ehSlide then
    Exit([]);

  //A letra sozinha nunca entra nas personalizadas (exigiria outro form),
  //entao ela nao aparece nem apagada: nao e indisponibilidade deste item, e
  //ausencia do recurso.
  Result := [acSlideCantado, acSlidePlayback, acSlideSemAudio,
    acAudioCantado, acAudioPlayback];
end;

function AcoesDoAcervo(temPlayback: Boolean): TAcoesItem;
begin
  Result := [acSlideCantado, acSlideSemAudio, acAudioCantado, acLetra];
  if temPlayback then
    Result := Result + [acSlidePlayback, acAudioPlayback];
end;

function AcoesDaPasta(ehSlide, temCantado, temPlayback, temAudio,
  temAudioPB: Boolean): TAcoesItem;
begin
  Result := [];

  //Fora dos pacotes de slides nao ha botao algum: o item e so o corpo, que
  //abre o arquivo. E assim que esta hoje.
  if not ehSlide then
    Exit;

  Result := [acSlideSemAudio];

  //Sem versao cantada o item e so playback: o botao de cantado abriria o
  //mesmo arquivo do botao de playback.
  if temCantado then
    Result := Result + [acSlideCantado];
  if temPlayback then
    Result := Result + [acSlidePlayback];

  //Sem faixa no pacote nao ha o que tocar sozinho.
  if temCantado and temAudio then
    Result := Result + [acAudioCantado];
  if temPlayback and temAudioPB then
    Result := Result + [acAudioPlayback];

  //A letra sozinha nao entra nas personalizadas: exigiria outro form.
end;

function ItensDeAmostra: TItensMenu;

  procedure poe(var itens: TItensMenu; const nome: string;
    acoes: TAcoesItem);
  var
    i: Integer;
  begin
    i := Length(itens);
    SetLength(itens, i + 1);
    itens[i].faixa := i + 1;
    itens[i].possiveis := PossiveisDoAcervo;
    itens[i].nome := nome;
    itens[i].acoes := acoes;
    itens[i].tipo := TIPO_ACERVO;
    itens[i].pos := i;
  end;

var
  r: TItensMenu;
begin
  SetLength(r, 0);

  //Variedade de proposito: o que precisa ficar provado e que o numero de
  //botoes muda de linha para linha SEM desalinhar o clique -- que e o defeito
  //que o fmListaMusica de hoje teve de contornar com um gancho no WM_PAINT.
  poe(r, 'Bendito Rei', AcoesDoAcervo(True));
  poe(r, 'Firme nas Promessas', AcoesDoAcervo(False));
  poe(r, 'Perto Quero Estar', AcoesDoAcervo(True));
  poe(r, 'Castelo Forte', AcoesDoAcervo(False));
  poe(r, 'Rude Cruz', AcoesDoAcervo(True));
  poe(r, 'Grandioso Es Tu', AcoesDoAcervo(True));
  poe(r, 'Saudosa Lembranca', AcoesDaPasta(True, True, False, True, False));
  poe(r, 'Tudo Entregarei', AcoesDaPasta(True, False, True, False, True));
  poe(r, 'Nome Precioso', AcoesDoAcervo(False));
  poe(r, 'Chuvas de Bencaos', AcoesDoAcervo(True));
  poe(r, 'Vem a Mim', AcoesDaPasta(False, False, False, False, False));
  poe(r, 'Mais Perto Quero Estar', AcoesDoAcervo(True));
  poe(r, 'Ao Deus de Abraao Louvai', AcoesDoAcervo(False));
  poe(r, 'Jesus, Minha Luz', AcoesDoAcervo(True));
  poe(r, 'Qual Mensagem de Alegria', AcoesDaPasta(True, True, True, True, True));
  poe(r, 'Ja Vem Chegando a Manha', AcoesDoAcervo(True));
  poe(r, 'Avante, Jovens, Avante', AcoesDoAcervo(False));
  poe(r, 'Um Nome Mais Lindo Nao Ha', AcoesDoAcervo(True));
  poe(r, 'Sublime Graca', AcoesDoAcervo(True));
  poe(r, 'Deus Cuida de Mim', AcoesDaPasta(True, True, True, False, False));

  r[6].tipo := TIPO_ARQUIVO;
  r[7].tipo := TIPO_ARQUIVO;
  r[10].tipo := TIPO_ARQUIVO;
  r[14].tipo := TIPO_ARQUIVO;
  r[19].tipo := TIPO_ARQUIVO;

  Result := r;
end;

end.
