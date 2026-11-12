unit fmListaMusica;

//O menu de músicas de uma coletânea, sem BusinessSkinForm.
//
//Substitui a versão que usava TbsBusinessSkinForm, TbsSkinStdLabel,
//TbsSkinSpeedButton, TbsSkinMenuSpeedButton, TbsSkinDBText, TbsPngImageView e
//TDBCtrlGrid. A aparência é a mesma; o que muda é quem desenha.
//
//NÃO HÁ .DFM: a tela é montada em código. Além de não haver arquivo de
//formulário para converter num porte para o Lazarus, é o que permite trocar a
//lista inteira por um controle só.
//
//O TDBCtrlGrid saiu porque não existe no LCL e não tem equivalente, mas ele já
//custava caro aqui: os botões de cada linha eram um jogo ÚNICO que o grid
//reconfigurava por linha, e por isso a linha ativa ficava com o layout da
//última linha desenhada -- o que deslocava o clique em 40px e obrigava a um
//gancho no WM_PAINT (gridWindowProc + restauraLinhaAtiva + seis campos de
//estado). Nada disso existe mais: no TListaMusicas o retângulo de cada ação
//sai de uma função só, usada tanto pelo desenho quanto pelo teste de clique.
//
//O que esta tela continua pedindo ao fmIndex é o mesmo de antes:
//dbctrlMusicasClick (acervo), abreSlidesArquivo/abrirArquivo (pasta),
//abreLetraMusicaAlbum/abreSlidesPasta (reproduzir todas) e a projeção do menu.

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Menus,
  uTema, uControles, uMenuMusicas, uListaMusicas, uJanela;

type
  TfListaMusica = class(TForm)
  private
    pnlTopo: TPainelLiso;
    pnlDireita: TPainelLiso;
    lista: TListaMusicas;
    btProjetar: TBotaoChato;
    btTodas: TBotaoChato;
    edtBusca: TEdit;
    popMonitores: TPopupMenu;
    //Todos os itens da coletânea. A lista pode estar mostrando um subconjunto,
    //porque o filtro da busca age aqui e não no dataset.
    FTodos: TItensMenu;
    //Só para levar o Tag ao fmIndex.dbctrlMusicasClick, que lê
    //TComponent(Sender).Tag. Era esse o papel dos TbsPngImageView do .dfm.
    emissor: TComponent;
    FProjetando: Boolean;
    procedure poeProjetando(v: Boolean);
    procedure montaTela;
    procedure montaPopupMonitores;
    procedure arrumaCabecalho;
    procedure ajustaLarguraMinima;
    procedure aplicaFiltro(Sender: TObject);
    procedure mostraBusca(quantos: Integer);
    procedure carregaAcervo;
    procedure carregaPasta;
    procedure posicionaNoItem(indice: Integer);
    procedure atualizaRotuloProjecao;
    function monitorEscolhido: Integer;
    procedure aoRedimensionar(Sender: TObject);
    procedure aoAtivar(Sender: TObject);
    procedure aoMostrar(Sender: TObject);
    procedure aoTeclaSolta(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure aoRodaBaixo(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure aoRodaCima(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure cliqueProjetar(Sender: TObject);
    procedure cliqueTodas(Sender: TObject);
    procedure cliqueMonitor(Sender: TObject);
    procedure cliqueFecharProjecao(Sender: TObject);
    procedure listaAcao(Sender: TObject; indice: Integer; acao: TAcaoItem);
    procedure listaAbrir(Sender: TObject; indice: Integer);
    procedure listaRolou(Sender: TObject);
  public
    id_album: integer;
    dir: string;
    inicio: Boolean;

    //Lidos de fora: o fmMenu preenche os três ao abrir a tela, e o
    //copiaDadosTelaExtendida copia título, subtítulo e capa para a projeção.
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    imgCapa: TImage;
    //A faixa de botões do cabeçalho. O fmMenu esconde ela para pasta.
    pnlBotoes: TPainelLiso;

    constructor Create(AOwner: TComponent); override;

    //Coletânea do acervo (um álbum do banco) ou pasta de coletânea
    //personalizada. É o que o DBCtrlGrid.DataSource dizia antes: o fmMenu
    //deixa 'dir' vazio para álbum e preenchido para pasta.
    function ehAcervo: Boolean;

    //Todos os itens da coletânea, na ordem do dataset — é o que a tela
    //projetada recebe. Não é o que está na lista: ela pode estar filtrada
    //pela busca, e a projeção mostra a coletânea inteira.
    function itensDaTela: TItensMenu;

    //Projetar o menu, ou fechar se já está projetando. Substitui o
    //btExp_MenuMusicasClick de antes; o fmMenu chama daqui pelo F5/F9.
    procedure projetarMenu;

    //"Dá para projetar agora?" -- é o que o ImageIndex = 53 do botão skinado
    //dizia: existe botão e não há projeção no ar.
    function podeProjetar: Boolean;

    //Ligado pelo próprio fMonitorMenuMusicas ao abrir e ao fechar, que é de
    //onde o estado vinha antes (ele escrevia o ImageIndex do botão).
    property projetando: Boolean read FProjetando write poeProjetando;
  end;

var
  fListaMusica: TfListaMusica;

implementation

uses fmMenu, dmComponentes, fmMonitorMenuMusicas, uGradeMusicas, Data.DB;

const
  //O cabeçalho era de 137px, com título e subtítulo centrados e muito ar: um
  //quarto de uma janela de 500px gasto em quase nada. Em 72 ele cabe numa
  //faixa só, e as três músicas a mais aparecem na lista.
  ALTURA_CABECALHO = 72;
  LADO_CAPA = 72;            //quadrado, encostado na esquerda
  //Os dois botoes empilhados: 30 + 8 + 30 = 68, dentro dos 72 do cabecalho.
  ALTURA_BOTAO = 30;
  ESPACO_BOTOES = 8;
  //Abaixo disto o nome do album deixa de caber: entra na conta do minimo.
  LARGURA_MIN_TITULO = 150;
  MARGEM_BOTOES = 10;

  //Busca só em coletânea grande. Numa de 10 faixas o campo seria ruído: a
  //lista inteira já está na tela. É o mesmo número do limite da projeção,
  //por um motivo só: passando de uma tela de itens, achar pelo nome vale
  //mais que percorrer a lista. Vale também para a coletânea personalizada --
  //o carregaPasta chama o mesmo mostraBusca.
  LIMITE_BUSCA = 20;

  //Projetar o menu só vale enquanto ele cabe numa tela: passar página na
  //projeção tira da vista o que a congregação já estava lendo.
  //
  //DERIVADO da grade, e não um número solto: mexer em LINHAS_PROJECAO ou em
  //COLUNAS_PROJECAO no uGradeMusicas traz este limite junto. E o critério é o
  //TAMANHO, nunca o ID do álbum.
  MAX_ITENS_PROJECAO = LINHAS_PROJECAO * COLUNAS_PROJECAO;

  //Nome do botão de projeção no fmIndex. É a chave que o expandirAreaPorNome
  //e o monitor_tp_config usam para saber do que se trata.
  BOTAO_PROJECAO = 'btExp_MenuMusicas';

  //Índices no DM.ico_24x24, os mesmos que o .dfm antigo usava. O 53 é
  //"projetar" e o 54 é "projetando" -- a dupla que o botão skinado trocava.
  ICONE_TODAS = 6;
  ICONE_PROJETAR = 53;
  ICONE_PROJETANDO = 54;

{ construção }

constructor TfListaMusica.Create(AOwner: TComponent);
begin
  //CreateNew e não Create: não há .dfm para carregar.
  inherited CreateNew(AOwner);

  //A paleta vem do skin ativo, e tem de ser aplicada ANTES de montar a tela:
  //os controles leem as cores no construtor deles.
  //
  //Esta tela era a única ilha escura do programa — as cores `#232323`/`#353535`
  //vinham escritas no .dfm antigo, não do tema. Agora ela segue o tema, seja
  //ele claro ou escuro, e trocar de skin troca a lista junto.
  //
  //É o único ponto do código novo que toca no BusinessSkinForm, e toca só para
  //ler números: o uTema continua sem conhecê-lo.
  fmIndex.aplicaTemaDaInterface;

  Color := COR_FUNDO;
  Font.Name := FONTE_UI;
  Font.Height := -11;
  Width := 700;
  Height := 500;
  Position := poScreenCenter;
  BorderIcons := [biSystemMenu, biMaximize];
  KeyPreview := True;

  OnResize := aoRedimensionar;
  OnActivate := aoAtivar;
  OnShow := aoMostrar;
  OnKeyUp := aoTeclaSolta;
  OnMouseWheelDown := aoRodaBaixo;
  OnMouseWheelUp := aoRodaCima;

  emissor := TComponent.Create(Self);

  montaTela;
  montaPopupMonitores;
end;

procedure TfListaMusica.montaTela;
begin
  //A ordem importa: alTop primeiro, alClient por último.
  pnlTopo := TPainelLiso.Create(Self);
  pnlTopo.Parent := Self;
  pnlTopo.Align := alTop;
  pnlTopo.Height := ALTURA_CABECALHO;
  pnlTopo.cor := COR_FUNDO;

  imgCapa := TImage.Create(Self);
  imgCapa.Parent := pnlTopo;
  imgCapa.Align := alLeft;
  imgCapa.Width := LADO_CAPA;
  imgCapa.Stretch := True;

  pnlDireita := TPainelLiso.Create(Self);
  pnlDireita.Parent := pnlTopo;
  pnlDireita.Align := alClient;
  pnlDireita.cor := COR_FUNDO;

  //Os botões passaram a dividir a faixa com o título, em vez de ocupar uma
  //linha própria embaixo dele.
  pnlBotoes := TPainelLiso.Create(Self);
  pnlBotoes.Parent := pnlDireita;
  pnlBotoes.Align := alRight;
  pnlBotoes.Width := 280;
  pnlBotoes.cor := COR_FUNDO;

  //Título e subtítulo alinhados à esquerda, um sobre o outro. Centrado só
  //fazia sentido quando o cabeçalho tinha 137px de altura para preencher.
  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent := pnlDireita;
  lblTitulo.AutoSize := False;
  lblTitulo.Alignment := taLeftJustify;
  lblTitulo.Layout := tlCenter;
  lblTitulo.Transparent := True;
  lblTitulo.Font.Name := FONTE_UI;
  lblTitulo.Font.Height := -19;
  lblTitulo.Font.Color := COR_TEXTO;
  lblTitulo.Caption := '';

  lblSubtitulo := TLabel.Create(Self);
  lblSubtitulo.Parent := pnlDireita;
  lblSubtitulo.AutoSize := False;
  lblSubtitulo.Alignment := taLeftJustify;
  lblSubtitulo.Layout := tlCenter;
  lblSubtitulo.Transparent := True;
  lblSubtitulo.Font.Name := FONTE_UI;
  lblSubtitulo.Font.Height := -12;
  lblSubtitulo.Font.Color := COR_TEXTO_FRACO;
  lblSubtitulo.Caption := '';

  //A busca só aparece em coletânea grande (ver mostraBusca). Ela filtra os
  //itens já carregados, não refaz consulta: o custo por tecla é percorrer um
  //array de algumas centenas de posições.
  edtBusca := TEdit.Create(Self);
  edtBusca.Parent := pnlDireita;
  edtBusca.Font.Name := FONTE_UI;
  edtBusca.Font.Height := -12;
  edtBusca.TextHint := 'Filtrar por número ou nome';
  edtBusca.OnChange := aplicaFiltro;
  edtBusca.Visible := False;

  btTodas := TBotaoChato.Create(Self);
  btTodas.Parent := pnlBotoes;
  btTodas.imagens := DM.ico_24x24;
  btTodas.indiceImagem := ICONE_TODAS;
  btTodas.glifo := glReproduzirTodas;
  btTodas.Caption := 'Reproduzir Todas';
  btTodas.OnClick := cliqueTodas;

  btProjetar := TBotaoChato.Create(Self);
  btProjetar.Parent := pnlBotoes;
  btProjetar.imagens := DM.ico_24x24;
  btProjetar.indiceImagem := ICONE_PROJETAR;
  btProjetar.glifo := glProjetar;
  btProjetar.mostraSeta := True;
  btProjetar.Caption := 'Projetar Menu';
  btProjetar.OnClick := cliqueProjetar;

  lista := TListaMusicas.Create(Self);
  lista.Parent := Self;
  lista.Align := alClient;
  lista.imagens := DM.ico_24x24;
  lista.OnAcao := listaAcao;
  lista.OnAbrirItem := listaAbrir;
  lista.OnRolou := listaRolou;
end;

procedure TfListaMusica.montaPopupMonitores;
begin
  popMonitores := TPopupMenu.Create(Self);
  //É o que faz os itens passarem pelo desenho do tema.
  popMonitores.OwnerDraw := True;
end;

{ layout }

procedure TfListaMusica.arrumaCabecalho;
var
  topo, larg, sobra, alturaBloco: Integer;
begin
  if (btTodas = nil) or (btProjetar = nil) then
    Exit;

  //Os dois botões ficam EMPILHADOS, não lado a lado: projetar em cima,
  //reproduzir embaixo. Assim a faixa da direita lê como um bloco só -- um
  //módulo de ações do álbum -- em vez de uma fileira que compete com o título.
  //
  //Posicionados à mão, e não por Margins, porque o LCL não tem Margins --
  //tem BorderSpacing, que é outra coisa.
  btProjetar.Width := btProjetar.larguraIdeal;
  btTodas.Width := btTodas.larguraIdeal;

  //Os dois saem com a mesma largura, senão o bloco fica com degrau.
  larg := btTodas.Width;
  if btProjetar.Visible and (btProjetar.Width > larg) then
    larg := btProjetar.Width;
  btProjetar.Width := larg;
  btTodas.Width := larg;

  //Altura total do que está visível, para centralizar o bloco na vertical.
  alturaBloco := 0;
  if btProjetar.Visible then
    Inc(alturaBloco, ALTURA_BOTAO);
  if btTodas.Visible then
  begin
    if alturaBloco > 0 then
      Inc(alturaBloco, ESPACO_BOTOES);
    Inc(alturaBloco, ALTURA_BOTAO);
  end;

  topo := (ALTURA_CABECALHO - alturaBloco) div 2;

  btProjetar.Height := ALTURA_BOTAO;
  btProjetar.Left := MARGEM_BOTOES;
  btProjetar.Top := topo;
  if btProjetar.Visible then
    Inc(topo, ALTURA_BOTAO + ESPACO_BOTOES);

  btTodas.Height := ALTURA_BOTAO;
  btTodas.Left := MARGEM_BOTOES;
  btTodas.Top := topo;

  //A faixa dos botões encolhe para o que eles realmente ocupam, devolvendo o
  //resto da largura para o título.
  pnlBotoes.Width := larg + 2 * MARGEM_BOTOES;

  sobra := Max(60, pnlDireita.ClientWidth - pnlBotoes.Width - 2 * MARGEM_BOTOES);

  lblTitulo.Left := MARGEM_BOTOES;
  lblTitulo.Width := sobra;
  lblTitulo.Height := 24;

  //Com busca: título em cima, campo embaixo. Sem busca: título e subtítulo.
  if edtBusca.Visible then
  begin
    lblTitulo.Top := 8;
    lblSubtitulo.Visible := False;
    edtBusca.Left := MARGEM_BOTOES;
    edtBusca.Top := 36;
    edtBusca.Width := Min(sobra, 280);
    edtBusca.Height := 26;
  end
  else
  begin
    lblTitulo.Top := 14;
    lblSubtitulo.Visible := True;
    lblSubtitulo.Left := MARGEM_BOTOES;
    lblSubtitulo.Top := 38;
    lblSubtitulo.Width := sobra;
    lblSubtitulo.Height := 20;
  end;

  ajustaLarguraMinima;
end;

procedure TfListaMusica.ajustaLarguraMinima;
var
  minCabecalho, minTudo: Integer;
begin
  //A janela é redimensionável, e estreitando demais o cabeçalho se atropela:
  //a capa e o bloco de botões têm largura própria, então quem encolhe é só o
  //título — até sumir. A lista tem o mesmo problema do outro lado, porque as
  //colunas de ação são fixas.
  //
  //O mínimo é CALCULADO, não um número escolhido a dedo: a largura do botão
  //depende da legenda ("Projetar Menu (Monitor 10)") e da fonte, que mudam.
  minCabecalho := LADO_CAPA + pnlBotoes.Width + LARGURA_MIN_TITULO +
                  2 * MARGEM_BOTOES;

  minTudo := Max(minCabecalho, lista.larguraMinima);

  //Constraints vale sobre a Width da janela, que inclui a borda.
  Inc(minTudo, Width - ClientWidth);

  if (Constraints.MinWidth <> minTudo) then
    Constraints.MinWidth := minTudo;

  if (Constraints.MinHeight = 0) then
    Constraints.MinHeight := ALTURA_CABECALHO + lista.alturaMinima +
                             (Height - ClientHeight);
end;

procedure TfListaMusica.mostraBusca(quantos: Integer);
begin
  edtBusca.Visible := (quantos > LIMITE_BUSCA);
  arrumaCabecalho;
end;

procedure TfListaMusica.aplicaFiltro(Sender: TObject);
begin
  //FiltraItens é função pura do uMenuMusicas: o dataset não é reconsultado, e
  //cada item carrega a posição dele (pos) para o cursor ser achado depois.
  lista.defineItens(FiltraItens(FTodos, edtBusca.Text));
end;

procedure TfListaMusica.aoRedimensionar(Sender: TObject);
begin
  arrumaCabecalho;
end;

procedure TfListaMusica.aoMostrar(Sender: TObject);
begin
  //Só faz sentido com tema escuro: com um claro, escurecer a barra de título
  //deixaria a moldura destoando do resto do programa.
  if TemaEscuro then
    EscureceBarraDeTitulo(Handle);
end;

{ carga }

function TfListaMusica.itensDaTela: TItensMenu;
begin
  Result := FTodos;
end;

function TfListaMusica.ehAcervo: Boolean;
begin
  //O fmMenu deixa 'dir' vazio para álbum do banco e preenchido para pasta de
  //coletânea personalizada. Antes isso era dito pelo DataSource do grid.
  Result := (Trim(dir) = '');
end;

procedure TfListaMusica.carregaAcervo;
var
  itens: TItensMenu;
  n: Integer;
begin
  DM.qrMUSICAS.Close;
  DM.qrMUSICAS.ParamByName('ID_ALBUM').Value := id_album;
  DM.qrMUSICAS.Open;

  SetLength(itens, 0);
  n := 0;

  DM.qrMUSICAS.First;
  while not DM.qrMUSICAS.Eof do
  begin
    SetLength(itens, n + 1);
    itens[n].faixa := DM.qrMUSICAS.FieldByName('FAIXA').AsInteger;
    itens[n].nome := DM.qrMUSICAS.FieldByName('NOME').AsString;
    itens[n].tipo := TIPO_ACERVO;
    //A posição no dataset, que o filtro da busca precisa preservar.
    itens[n].pos := n;
    //A mesma regra do DBCtrlGridPaintPanel: no acervo tudo existe, menos o
    //playback, que depende de URL_INSTRUMENTAL estar preenchido.
    itens[n].acoes := AcoesDoAcervo(
      DM.qrMUSICAS.FieldByName('URL_INSTRUMENTAL').AsString <> '');
    //As seis colunas aparecem sempre; as que este item nao faz saem
    //apagadas, para 'sem playback' nao parecer 'coluna sem uso'.
    itens[n].possiveis := PossiveisDoAcervo;
    Inc(n);
    DM.qrMUSICAS.Next;
  end;
  DM.qrMUSICAS.First;

  FTodos := itens;
  btTodas.Visible := True;
  btProjetar.Visible := (n <= MAX_ITENS_PROJECAO);
  //O subtítulo do álbum vem do fmMenu; só preenche se ele não mandou nada.
  if (Trim(lblSubtitulo.Caption) = '') then
    lblSubtitulo.Caption := Format('%d músicas', [n]);
  mostraBusca(n);
  aplicaFiltro(nil);

  atualizaRotuloProjecao;

  if (fMonitorMenuMusicas <> nil) then
    fmIndex.copiaDadosTelaExtendida();
end;

procedure TfListaMusica.carregaPasta;
var
  sr: TSearchRec;
  iRetorno: Integer;
  i, n: Integer;
  naoSlides, naFila, semAudio: Integer;
  ext, nome, chave, arqCantado, arqPB: string;
  ehPB, ehSlide, temAudio, temAudioPB: Boolean;
  ordem, dados: TStringList;
  itens: TItensMenu;
begin
  if not DM.cdsArquivos.Active then
    DM.cdsArquivos.CreateDataSet;
  DM.cdsArquivos.Open;
  DM.cdsArquivos.EmptyDataSet;

  //IncludeTrailingPathDelimiter no lugar do antigo "soma '\' e colapsa '\\'":
  //aquele StringReplace era global, então estragava caminho de rede
  //(\\servidor\pasta virava \servidor\pasta).
  dir := IncludeTrailingPathDelimiter(dir);

  if not DirectoryExists(dir) then
    Exit;

  naoSlides := 0;
  naFila := 0;
  semAudio := 0;

  //Cada entrada de "ordem" é uma música da lista: a chave ordena e o objeto
  //carrega o que foi encontrado para ela na pasta.
  //  [0] nome exibido  [1] arquivo cantado  [2] arquivo playback  [3] é slide
  ordem := TStringList.Create;
  try
    iRetorno := FindFirst(dir + '*.*', faAnyFile, sr);
    try
      while iRetorno = 0 do
      begin
        if (sr.Name <> '.') and (sr.Name <> '..') and
           ((sr.Attr and faDirectory) = 0) then
        begin
          ext := LowerCase(ExtractFileExt(sr.Name));

          //O .ini não é conteúdo da coletânea: é arquivo de controle do
          //próprio Windows (desktop.ini) e só poluiria a lista.
          if (ext = '.ini') then
          begin
            iRetorno := FindNext(sr);
            Continue;
          end;

          nome := Trim(ChangeFileExt(sr.Name, ''));
          ehSlide := (ext = '.slja') or (ext = '.lja');

          if ehSlide then
          begin
            //Cantado e playback são dois arquivos, mas uma música só na
            //lista. O sufixo de playback é reconhecido pelo fmMenu, que
            //devolve o nome sem ele.
            ehPB := fmIndex.ehNomePlayback(nome);
            chave := LowerCase(nome);
          end
          else
          begin
            //Arquivo comum não pareia com nada; entra como item avulso.
            ehPB := False;
            chave := LowerCase(sr.Name);
          end;

          i := ordem.IndexOf(chave);
          if (i < 0) or not ehSlide then
          begin
            dados := TStringList.Create;
            //A primeira grafia encontrada é a que aparece na lista.
            dados.Add(nome);
            dados.Add('');
            dados.Add('');
            if ehSlide then dados.Add('1') else dados.Add('0');
            i := ordem.AddObject(chave, dados);
          end;

          dados := TStringList(ordem.Objects[i]);
          if ehPB
            then dados[2] := dir + sr.Name
            else dados[1] := dir + sr.Name;

          if not ehSlide then
            Inc(naoSlides);
        end;
        iRetorno := FindNext(sr);
      end;
    finally
      FindClose(sr);
    end;

    ordem.Sort;

    SetLength(itens, 0);
    n := 0;

    for i := 0 to ordem.Count - 1 do
    begin
      dados := TStringList(ordem.Objects[i]);
      ehSlide := (dados[3] = '1');
      arqCantado := dados[1];
      arqPB := dados[2];

      //Um pacote sem música, ou com a música desligada nas opções, se comporta
      //como se fosse só letra: nada toca.
      temAudio := (arqCantado <> '') and fmIndex.slidesTemAudio(arqCantado);
      temAudioPB := (arqPB <> '') and fmIndex.slidesTemAudio(arqPB);

      //A fila toca a versão cantada; só quando ela não existe é que o
      //playback assume o lugar dela.
      if (arqCantado <> '') then
      begin
        Inc(naFila);
        if not temAudio then
          Inc(semAudio);
      end
      else if (arqPB <> '') then
      begin
        Inc(naFila);
        if not temAudioPB then
          Inc(semAudio);
      end;

      DM.cdsArquivos.Append;
      DM.cdsArquivos.FieldByName('FAIXA').Value := i + 1;
      DM.cdsArquivos.FieldByName('NOME').Value := dados[0];
      //Sem versão cantada, o corpo do item abre o playback.
      if (arqCantado <> '')
        then DM.cdsArquivos.FieldByName('DIR').Value := arqCantado
        else DM.cdsArquivos.FieldByName('DIR').Value := arqPB;
      DM.cdsArquivos.FieldByName('DIR_PB').Value := arqPB;
      DM.cdsArquivos.FieldByName('TEM_AUDIO').Value := temAudio;
      DM.cdsArquivos.FieldByName('TEM_AUDIO_PB').Value := temAudioPB;
      DM.cdsArquivos.FieldByName('EH_SLIDE').Value := ehSlide;
      DM.cdsArquivos.Post;

      SetLength(itens, n + 1);
      itens[n].faixa := i + 1;
      itens[n].nome := dados[0];
      itens[n].tipo := TIPO_ARQUIVO;
      itens[n].pos := n;
      //DIR aponta para a versão cantada; só quando ela falta é que ele repete
      //o playback, e aí o item é playback puro.
      itens[n].acoes := AcoesDaPasta(ehSlide, arqCantado <> '', arqPB <> '',
        temAudio, temAudioPB);
      itens[n].possiveis := PossiveisDaPasta(ehSlide);
      Inc(n);
    end;
  finally
    for i := 0 to ordem.Count - 1 do
      ordem.Objects[i].Free;
    ordem.Free;
  end;

  DM.cdsArquivos.First;
  FTodos := itens;

  //Reproduzir todas encadeia uma pasta só de slides. Fica escondido quando há
  //arquivo de outro tipo, quando algum item não toca áudio (a fila pararia
  //nele) ou quando não há nada para tocar. Só playback também vale.
  btTodas.Visible := (naoSlides = 0) and (semAudio = 0) and (naFila > 0);
  //Projetar o menu é coisa de álbum do acervo.
  btProjetar.Visible := False;

  //O -PB é uma convenção de nome, então precisa estar dita em algum lugar.
  //Virou o subtítulo: o cabeçalho compacto não tem linha sobrando, e para
  //pasta o fmMenu deixa o subtítulo vazio de qualquer forma.
  if (naoSlides = 0) and (n > 0) then
    lblSubtitulo.Caption := 'Arquivo terminado em -PB é marcado como playback'
  else
    lblSubtitulo.Caption := Format('%d itens', [n]);

  pnlBotoes.Visible := btTodas.Visible;

  mostraBusca(n);
  aplicaFiltro(nil);
end;

procedure TfListaMusica.aoAtivar(Sender: TObject);
begin
  //OnActivate dispara a cada reativação da janela: o 'inicio' é a trava de
  //reentrância, e já era assim antes.
  if (inicio = True) then
    Exit;

  inicio := True;

  if ehAcervo then
    carregaAcervo
  else
    carregaPasta;

  arrumaCabecalho;

  if lista.CanFocus then
    lista.SetFocus;
end;

{ dados e ações }

procedure TfListaMusica.posicionaNoItem(indice: Integer);
var
  ds: TDataSet;
begin
  if (indice < 0) then
    Exit;

  if ehAcervo then
    ds := DM.qrMUSICAS
  else
    ds := DM.cdsArquivos;

  if (ds = nil) or not ds.Active then
    Exit;

  //First + MoveBy em vez de RecNo: vale para qualquer TDataSet, inclusive no
  //porte. A lista é de uma coletânea, então são dezenas de registros.
  ds.First;
  if (indice > 0) then
    ds.MoveBy(indice);
end;

procedure TfListaMusica.listaAcao(Sender: TObject; indice: Integer;
  acao: TAcaoItem);
var
  ds: TDataSet;
  tag: Integer;
begin
  posicionaNoItem(lista.posDoItem(indice));
  //Marca de onde veio o que esta no ar. E a ULTIMA aberta por esta tela: se
  //a projecao for fechada por fora, a marca continua -- diz o que foi aberto,
  //nao o que esta visivel.
  lista.projetando := indice;

  //E a projeção destaca a mesma música. O índice da grade é o do dataset,
  //não o da lista: com a busca filtrando, os dois divergem.
  if (fMonitorMenuMusicas <> nil) then
    fMonitorMenuMusicas.destaca(lista.posDoItem(indice));
  tag := TagDaAcao(acao);

  if ehAcervo then
  begin
    //O fmIndex lê o Tag do Sender e o registro atual de DM.qrMUSICAS.
    emissor.Tag := tag;
    fmIndex.dbctrlMusicasClick(emissor);
    Exit;
  end;

  ds := DM.cdsArquivos;

  //Fora dos pacotes de slides não há botão algum: o clique só pode ter vindo
  //do corpo do item, que abre o arquivo como sempre abriu.
  if (tag < 1) or (tag > 5) or not ds.FieldByName('EH_SLIDE').AsBoolean
    then fmIndex.abrirArquivo(ds.FieldByName('DIR').AsString)
    else fmIndex.abreSlidesArquivo(ds.FieldByName('DIR').AsString,
                                   ds.FieldByName('DIR_PB').AsString, tag);
end;

procedure TfListaMusica.listaAbrir(Sender: TObject; indice: Integer);
var
  ds: TDataSet;
begin
  posicionaNoItem(lista.posDoItem(indice));
  //Marca de onde veio o que esta no ar. E a ULTIMA aberta por esta tela: se
  //a projecao for fechada por fora, a marca continua -- diz o que foi aberto,
  //nao o que esta visivel.
  lista.projetando := indice;

  //E a projeção destaca a mesma música. O índice da grade é o do dataset,
  //não o da lista: com a busca filtrando, os dois divergem.
  if (fMonitorMenuMusicas <> nil) then
    fMonitorMenuMusicas.destaca(lista.posDoItem(indice));

  //Clique no corpo do item: era o Tag 0 dos painéis do grid.
  if ehAcervo then
  begin
    emissor.Tag := 0;
    fmIndex.dbctrlMusicasClick(emissor);
    Exit;
  end;

  ds := DM.cdsArquivos;
  fmIndex.abrirArquivo(ds.FieldByName('DIR').AsString);
end;

procedure TfListaMusica.listaRolou(Sender: TObject);
begin
  //A projeção acompanha a rolagem do operador -- vira a página até o
  //primeiro item visível aqui.
  //
  //Antes isso era feito movendo o CURSOR do dataset, porque a tela projetada
  //era um DBCtrlGrid ligado a ele. Agora a grade recebe os itens e o índice,
  //então rolar a lista deixou de ter efeito colateral no dataset.
  if (fMonitorMenuMusicas <> nil) then
    fMonitorMenuMusicas.mostraItem(lista.posDoItem(lista.primeiroVisivel));
end;

procedure TfListaMusica.cliqueTodas(Sender: TObject);
begin
  //Coletânea personalizada: a fila é a pasta, não um álbum do banco.
  if not ehAcervo then
    fmIndex.abreSlidesPasta(dir)
  else
    fmIndex.abreLetraMusicaAlbum(
      DM.qrMUSICAS.FieldByName('ID_ALBUM').AsInteger);
end;

{ projeção }

function TfListaMusica.monitorEscolhido: Integer;
begin
  //Mesmo parâmetro que o monitor_bt_label do fmIndex lê para este botão
  //(monitor_tp_config('btExp_MenuMusicas') = 'Lista Musicas'). 1 é o primeiro.
  Result := StrToIntDef(fmIndex.lerParam('Lista Musicas', 'Monitor', '2'), 2);
end;

procedure TfListaMusica.atualizaRotuloProjecao;
begin
  btProjetar.Caption := 'Projetar Menu (Monitor ' +
    IntToStr(monitorEscolhido) + ')';
  arrumaCabecalho;
end;

procedure TfListaMusica.poeProjetando(v: Boolean);
begin
  if (FProjetando = v) then
    Exit;

  FProjetando := v;

  if (btProjetar <> nil) then
  begin
    if v then
      btProjetar.indiceImagem := ICONE_PROJETANDO
    else
      btProjetar.indiceImagem := ICONE_PROJETAR;
    btProjetar.Invalidate;
  end;
end;

function TfListaMusica.podeProjetar: Boolean;
begin
  Result := (btProjetar <> nil) and btProjetar.Visible and (not FProjetando);
end;

procedure TfListaMusica.projetarMenu;
begin
  if (btProjetar = nil) or (not btProjetar.Visible) then
    Exit;

  //O corpo da projeção continua sendo do fmIndex; o que mudou é que ele passou
  //a ser chamado pelo nome do botão, e não por um TbsSkinMenuSpeedButton.
  //Liga/desliga, igual ao clique no botão skinado -- que decidia pelo
  //ImageIndex o que esta tela agora guarda em FProjetando.
  fmIndex.expandirAreaPorNome(BOTAO_PROJECAO, not FProjetando);
end;

procedure TfListaMusica.cliqueProjetar(Sender: TObject);
var
  i, atual: Integer;
  it: TMenuItem;
  p: TPoint;
begin
  //O botão do skin tinha TrackButtonMode: o corpo ligava/desligava e a seta
  //abria o menu dos monitores. Aqui o menu abre sempre e já traz as duas
  //coisas -- um clique a mais, mas sem um alvo de 16px para acertar.
  popMonitores.Items.Clear;
  atual := monitorEscolhido;

  for i := 0 to Screen.MonitorCount - 1 do
  begin
    it := TMenuItem.Create(popMonitores);
    it.Caption := 'Monitor ' + IntToStr(i + 1) + ' (' +
      IntToStr(Screen.Monitors[i].Width) + 'x' +
      IntToStr(Screen.Monitors[i].Height) + ')';
    it.Tag := i;
    it.RadioItem := True;
    it.Checked := (atual = i + 1);
    it.OnClick := cliqueMonitor;
    popMonitores.Items.Add(it);
  end;

  if FProjetando then
  begin
    it := TMenuItem.Create(popMonitores);
    it.Caption := '-';
    popMonitores.Items.Add(it);

    it := TMenuItem.Create(popMonitores);
    it.Caption := 'Fechar projeção';
    it.OnClick := cliqueFecharProjecao;
    popMonitores.Items.Add(it);
  end;

  TemaPopup.aplica(popMonitores.Items);

  p := btProjetar.ClientToScreen(Point(0, btProjetar.Height));
  popMonitores.Popup(p.X, p.Y);
end;

procedure TfListaMusica.cliqueMonitor(Sender: TObject);
begin
  //Escolher o monitor grava a preferência (o mesmo parâmetro que o
  //mmPopMonitorClick grava) e projeta nele. O expandirAreaPorNome fecha a
  //projeção anterior antes de abrir, então trocar de monitor funciona.
  fmIndex.gravaParam('Lista Musicas', 'Monitor',
    IntToStr(TMenuItem(Sender).Tag + 1));
  atualizaRotuloProjecao;
  fmIndex.expandirAreaPorNome(BOTAO_PROJECAO, True);
end;

procedure TfListaMusica.cliqueFecharProjecao(Sender: TObject);
begin
  fmIndex.expandirAreaPorNome(BOTAO_PROJECAO, False);
end;

{ teclado e roda }

procedure TfListaMusica.aoTeclaSolta(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  //As teclas que a lista consome no KeyDown precisam de guarda TAMBÉM aqui:
  //Key := 0 num OnKeyDown não impede o KeyUp de chegar, e o FormKeyUp do
  //fmIndex manda seta para fMusica.acaoSlide mesmo com esta janela na frente.
  //PgUp/PgDn ficam de fora da guarda de propósito: são do passador de slides.
  if (Shift = []) and (Screen.ActiveControl = lista) then
    case Key of
      VK_UP, VK_DOWN, VK_HOME, VK_END, VK_RETURN:
        begin
          Key := 0;
          Exit;
        end;
    end;

  fmIndex.FormKeyUp(Sender, Key, Shift);
end;

procedure TfListaMusica.aoRodaBaixo(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  fmIndex.MouseWheel('Down', Sender, Shift, MousePos, Handled);
end;

procedure TfListaMusica.aoRodaCima(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  fmIndex.MouseWheel('Up', Sender, Shift, MousePos, Handled);
end;

end.
