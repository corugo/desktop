unit fmLiturgia;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, BusinessSkinForm, bsSkinCtrls,
  Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Mask, bsSkinBoxCtrls,
  bsdbctrls, bsribbon, Data.DB, Data.Win.ADODB, bsColorCtrls, StrUtils, ShellApi,
  uTema, uControles, uMenuMusicas, uItensLiturgia,
  Vcl.DBCtrls, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type
  TfLiturgia = class(TForm)
    bsBusinessSkinForm1: TbsBusinessSkinForm;
    GridPanel2: TGridPanel;
    btAdd: TbsSkinButton;
    bsSkinPanel1: TbsSkinPanel;
    lblItem: TbsSkinLabel;
    txtItem: TbsSkinEdit;
    bsSkinLabel2: TbsSkinLabel;
    cbItens: TbsSkinComboBox;
    ScrollBox1: TScrollBox;
    dsHinos: TDataSource;
    qrHinos: TFDQuery;
    pnlHinos: TbsSkinPanel;
    bsRibbonDivider10: TbsRibbonDivider;
    bsSkinPanel2: TbsSkinPanel;
    opcHinosOpc1: TbsSkinRadioButton;
    pnlHinosOpc1: TbsSkinPanel;
    skLitLabel: TbsSkinStdLabel;
    bsSkinPanel4: TbsSkinPanel;
    dbLitHinoLista: TbsSkinDBLookupComboBox;
    csCor: TbsSkinColorButton;
    bsSkinLabel3: TbsSkinLabel;
    btDel: TbsSkinButton;
    pnlAnotacoes: TbsSkinPanel;
    bsRibbonDivider1: TbsRibbonDivider;
    bsSkinPanel6: TbsSkinPanel;
    bsSkinStdLabel1: TbsSkinStdLabel;
    pnlSite: TbsSkinPanel;
    bsSkinSpeedButton1: TbsSkinSpeedButton;
    edtAnotacao: TbsSkinEdit;
    bsRibbonDivider2: TbsRibbonDivider;
    bsSkinPanel3: TbsSkinPanel;
    bsSkinStdLabel2: TbsSkinStdLabel;
    urlSite: TbsSkinURLEdit;
    bsSkinSpeedButton2: TbsSkinSpeedButton;
    pnlArquivo: TbsSkinPanel;
    bsRibbonDivider3: TbsRibbonDivider;
    bsSkinPanel7: TbsSkinPanel;
    bsSkinStdLabel3: TbsSkinStdLabel;
    edtDiretorio: TbsSkinEdit;
    bsSkinSpeedButton3: TbsSkinSpeedButton;
    bsSkinSpeedButton4: TbsSkinSpeedButton;
    edtDiretorioInfo: TbsSkinEdit;
    pnlItensAgendados: TbsSkinPanel;
    bsRibbonDivider4: TbsRibbonDivider;
    bsSkinPanel8: TbsSkinPanel;
    bsSkinStdLabel4: TbsSkinStdLabel;
    dblItem: TDBLookupComboBox;
    bsSkinPanel5: TbsSkinPanel;
    procedure cbItensChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure executaOpcoes();
    procedure opcHinosOpc1Click(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure bsSkinSpeedButton1Click(Sender: TObject);
    procedure btAddClick(Sender: TObject);
    procedure btDelClick(Sender: TObject);
    procedure txtItemKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure bsSkinSpeedButton2Click(Sender: TObject);
    function validaURL(url: string): string;
    procedure urlSiteExit(Sender: TObject);
    procedure bsSkinSpeedButton4Click(Sender: TObject);
    procedure edtDiretorioEnter(Sender: TObject);
    procedure edtDiretorioExit(Sender: TObject);
    procedure bsSkinSpeedButton3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    //A trilha de tipos e o seletor de modo nascem em CODIGO, nao no .dfm:
    //acrescentar um tipo passa a ser mexer no cbItens.Items e no
    //tipoDoIndice, e a trilha acompanha sozinha.
    pnlTipos: TPainelLiso;
    pnlDireita: TPainelLiso;
    pnlModo: TPainelLiso;
    //O aviso do tipo "Busca rapida", no lugar onde a musica seria escolhida.
    pnlBuscaInfo: TPainelLiso;
    lblModo: TLabel;
    lblBusca: TLabel;
    botoesTipo: array of TBotaoChato;
    botoesModo: array of TBotaoChato;
    modoEscolhido: TAcaoItem;
    //O modo pode ficar SEM NADA selecionado: trocar para uma musica sem
    //playback desmarca a opcao de playback que estivesse escolhida, e o
    //btAddClick recusa salvar nesse estado.
    modoDefinido: Boolean;
    //Tudo que decide "que tipo e este" passa por aqui, e NADA depende da
    //ordem do combo: a ligacao e pelo ROTULO. Acrescentar um tipo e uma
    //linha na tabela TIPOS_ITEM, e mais nada.
    function tipoAtual: Integer;
    function indiceNoCombo(t: Integer): Integer;
    function codigoAtual: string;
    function ehBuscaRapida: Boolean;
    procedure montaTrilha;
    procedure montaSeletorModo;
    procedure arrumaSeletorModo;
    procedure cliqueTipo(Sender: TObject);
    procedure cliqueModo(Sender: TObject);
    procedure marcaTipoNaTrilha;
    procedure poeModo(m: TAcaoItem);
    procedure limpaModo;
    function playbackDisponivel: Boolean;
    procedure atualizaOpcoesDeModo;
    procedure aoAndarNosHinos(DataSet: TDataSet);
  public
    { Public declarations }
    id: string;
    arquivoInicial: string;
  end;

var
  fLiturgia: TfLiturgia;

implementation

{$R *.dfm}

uses fmMenu, fmBuscaMusica, dmComponentes, fmIniciando, uTiposItem;

const
  LARG_TRILHA   = 150;
  ALT_BOTAO_TIPO = 34;
  //O seletor de modo: 5 botoes em 3 colunas (3 + 2), como o modelo escolhido.
  //O seletor de modo: so os icones, como a faixa de acoes da lista da
  //liturgia. Sem texto, o nome do modo vai na dica do mouse.
  LARG_BOTAO_MODO = 40;   //8 de margem + 24 do icone + 8 de margem
  ALT_BOTAO_MODO  = 34;
  GAP_MODO        = 4;

  //Os cinco modos, na ordem do TAcaoItem. O acLetra fica FORA de proposito:
  //nao e um jeito de abrir a musica, e ja tem botao proprio na faixa de
  //acoes do item.
  MODOS: array[0..4] of TAcaoItem =
    (acSlideCantado, acSlidePlayback, acSlideSemAudio, acAudioCantado,
     acAudioPlayback);

procedure TfLiturgia.FormCreate(Sender: TObject);
var
  minimo: Integer;
begin
  modoEscolhido := MODO_PADRAO;
  modoDefinido := True;
  montaTrilha;

  //A coluna da direita. Reparentar em tempo de execucao custa duas linhas e
  //evita mexer em ~1.200 linhas de .dfm -- e e o que leva o NOME do item
  //para dentro da coluna, em vez de uma faixa na largura toda que fica
  //esquisita quando o nome esta escondido (Itens Agendados).
  pnlDireita := TPainelLiso.Create(Self);
  pnlDireita.Parent := Self;
  pnlDireita.cor := COR_ITEM;
  pnlDireita.Align := alClient;
  bsSkinPanel1.Parent := pnlDireita;
  ScrollBox1.Parent := pnlDireita;

  montaSeletorModo;

  //O "A musica sera escolhida na hora" saiu da tela: virou o tipo de item
  //"Busca rapida". O radio continua no .dfm porque apagar objeto de .dfm e
  //diff grande por nada -- ele so deixa de aparecer e de decidir.
  bsSkinPanel2.Visible := False;

  //O seletor de item agendado vai para a linha do nome, a pedido do
  //usuario: antes ele morava num painel proprio e a linha de cima ficava
  //vazia, o que e exatamente o que incomodava. Ele ja nasce alClient e com
  //as mesmas margens do txtItem, entao basta trocar de pai.
  dblItem.Parent := bsSkinPanel1;
  dblItem.Visible := False;

  pnlBuscaInfo := TPainelLiso.Create(Self);
  pnlBuscaInfo.Parent := pnlHinos;
  pnlBuscaInfo.cor := COR_ITEM;
  pnlBuscaInfo.Height := 31;
  pnlBuscaInfo.Top := 10000;   //entra por ultimo; ver a nota no cbItensChange
  pnlBuscaInfo.Align := alTop;
  pnlBuscaInfo.Visible := False;

  lblBusca := TLabel.Create(Self);
  lblBusca.Parent := pnlBuscaInfo;
  lblBusca.Left := 8;
  lblBusca.Top := 8;
  lblBusca.Caption := 'A música será escolhida na hora, pela busca rápida.';
  lblBusca.Font.Color := COR_TEXTO_FRACO;
  lblBusca.Transparent := True;

  //A escolha no lookup reposiciona o qrHinos -- e o que o btAddClick ja
  //assume ao ler TIPO_HASD dali. Entao este e o evento de "mudou de
  //musica", sem depender de qual evento o controle skinned expoe.
  qrHinos.AfterScroll := aoAndarNosHinos;

  //A altura minima do form e a trilha INTEIRA, porque ela nao rola: tipo
  //novo nao pode ficar fora da tela. Com isso acrescentar um tipo continua
  //sendo mexer so no cbItens.Items e no tipoDoIndice.
  minimo := Length(botoesTipo) * ALT_BOTAO_TIPO + bsSkinPanel1.Height +
            GridPanel2.Height;
  if (ClientHeight < minimo) then
    ClientHeight := minimo;
end;

function TfLiturgia.tipoAtual: Integer;
begin
  Result := -1;
  if (cbItens.ItemIndex >= 0) and (cbItens.ItemIndex < cbItens.Items.Count) then
    Result := indiceDoRotulo(cbItens.Items[cbItens.ItemIndex]);
end;

function TfLiturgia.indiceNoCombo(t: Integer): Integer;
begin
  //Pelo ROTULO: o combo pode estar em qualquer ordem.
  if (t < 0) or (t > High(TIPOS_ITEM)) then
    Result := -1
  else
    Result := cbItens.Items.IndexOf(TIPOS_ITEM[t].rotulo);
end;

function TfLiturgia.codigoAtual: string;
var
  t: Integer;
begin
  t := tipoAtual;
  if (t < 0) then
    Result := ''
  else
    Result := TIPOS_ITEM[t].codigo;
end;

function TfLiturgia.ehBuscaRapida: Boolean;
var
  t: Integer;
begin
  t := tipoAtual;
  Result := (t >= 0) and TIPOS_ITEM[t].buscaRapida;
end;

procedure TfLiturgia.montaTrilha;
var
  i, ico: Integer;
  b: TBotaoChato;
begin
  pnlTipos := TPainelLiso.Create(Self);
  pnlTipos.Parent := Self;
  pnlTipos.cor := COR_ITEM;
  pnlTipos.Width := LARG_TRILHA;
  //alLeft, e a VCL alinha alTop ANTES de alLeft: por isso a faixa de cor e
  //nome fica em cima na largura toda, e a trilha comeca abaixo dela.
  pnlTipos.Align := alLeft;

  //O combo continua sendo o modelo -- o fmMenu mexe nele por
  //Items.IndexOf('Arquivo/Diretório') --, mas quem dita o conteudo e a
  //TABELA. Assim um tipo novo nao precisa ser acrescentado em dois lugares,
  //que e como os dois divergiriam.
  cbItens.Items.BeginUpdate;
  try
    cbItens.Items.Clear;
    for i := 0 to High(TIPOS_ITEM) do
      cbItens.Items.Add(TIPOS_ITEM[i].rotulo);
  finally
    cbItens.Items.EndUpdate;
  end;

  SetLength(botoesTipo, Length(TIPOS_ITEM));
  for i := 0 to High(TIPOS_ITEM) do
  begin
    b := TBotaoChato.Create(Self);
    b.Parent := pnlTipos;
    //POSICAO A MAO, e nao alTop: o alTop empilha por Top, e botao recem
    //criado nasce com Top 0, entao a ordem saia embaralhada. Aqui a ordem e
    //exatamente a da tabela.
    b.SetBounds(0, i * ALT_BOTAO_TIPO, LARG_TRILHA, ALT_BOTAO_TIPO);
    b.Caption := TIPOS_ITEM[i].rotulo;
    b.corFundo := COR_ITEM;
    b.Tag := i;
    b.OnClick := cliqueTipo;

    //A divisoria nao tem icone de proposito (o IconeDoItem devolve -1 para
    //ela), e arquivo precisa do subtipo para escolher entre pasta e arquivo.
    //Escolher outro indice do ico_24x24 no chute e como a alca de arrastar
    //sumiu em tema claro -- a lupa que o botao de buscar usa, por exemplo,
    //e da ico_16x16.
    if EhDivisoria(TIPOS_ITEM[i].codigo) then
      //A divisoria nao tem icone no ico_24x24 -- o IconeDoItem devolve -1
      //de proposito. Ganha a lista com marcador, que e o que ela faz:
      //agrupar os itens abaixo dela.
      b.glifo := glBloco
    else if EhMusica(TIPOS_ITEM[i].codigo) then
      //Os dois tipos de musica ganham a NOTA DESENHADA, a mesma da lista
      //da liturgia. O TBotaoChato desenha o glifo quando nao recebe lista
      //de imagens, entao basta nao atribuir nenhuma.
      b.glifo := glNota
    else
    begin
      ico := IconeDoItem(TIPOS_ITEM[i].codigo, SUB_ARQ, '');
      if (ico >= 0) then
      begin
        b.imagens := DM.ico_24x24;
        b.indiceImagem := ico;
      end;
    end;

    botoesTipo[i] := b;
  end;
end;

procedure TfLiturgia.montaSeletorModo;
var
  i: Integer;
  b: TBotaoChato;
begin
  pnlModo := TPainelLiso.Create(Self);
  pnlModo.Parent := ScrollBox1;
  pnlModo.cor := COR_ITEM;
  pnlModo.Height := 22 + ALT_BOTAO_MODO + 6;
  //Criado DEPOIS dos paineis do .dfm, entao empilha abaixo do pnlHinos: o
  //DoAlign de alTop segue a ordem da lista de controles.
  pnlModo.Align := alTop;
  pnlModo.Visible := False;

  lblModo := TLabel.Create(Self);
  lblModo.Parent := pnlModo;
  lblModo.Left := 8;
  lblModo.Top := 5;
  lblModo.Caption := 'Ao clicar no item, abrir com:';
  lblModo.Font.Color := COR_TEXTO_FRACO;
  //O TPainelLiso nao publica Color, entao o ParentColor do rotulo pegaria
  //clBtnFace e sairia um retangulo cinza em cima da cor do painel.
  lblModo.Transparent := True;

  SetLength(botoesModo, Length(MODOS));
  for i := 0 to High(MODOS) do
  begin
    b := TBotaoChato.Create(Self);
    b.Parent := pnlModo;
    b.Height := ALT_BOTAO_MODO;
    b.Width := LARG_BOTAO_MODO;
    //So o icone, como na faixa de acoes da lista. Sem texto, o nome do modo
    //tem de vir na dica -- senao os cinco icones nao se explicam.
    b.Caption := '';
    b.Hint := NomeDaAcao(MODOS[i]);
    b.ShowHint := True;
    b.corFundo := COR_ITEM;
    b.imagens := DM.ico_24x24;
    b.indiceImagem := IconeDaAcao(MODOS[i]);
    b.Tag := i;
    b.OnClick := cliqueModo;
    botoesModo[i] := b;
  end;
end;

procedure TfLiturgia.arrumaSeletorModo;
var
  i, x: Integer;
begin
  if (pnlModo = nil) or (Length(botoesModo) = 0) then
    Exit;

  //Os cinco ficam sempre na mesma posicao: o playback indisponivel e
  //apagado, nao escondido, entao a faixa nao muda de tamanho nem os icones
  //trocam de lugar quando se troca de musica.
  x := 8;
  for i := 0 to High(botoesModo) do
  begin
    botoesModo[i].SetBounds(x, 22, LARG_BOTAO_MODO, ALT_BOTAO_MODO);
    Inc(x, LARG_BOTAO_MODO + GAP_MODO);
  end;
end;

function TfLiturgia.playbackDisponivel: Boolean;
var
  id: Integer;
begin
  //Busca rapida: nao existe musica para conferir, entao os dois playbacks
  //continuam na mesa. Mesma decisao do musicaTemPlayback.
  if (pnlBuscaInfo <> nil) and pnlBuscaInfo.Visible then
  begin
    Result := True;
    Exit;
  end;

  id := StrToIntDef(VarToStr(dbLitHinoLista.KeyValue), -1);
  Result := fmIndex.musicaTemPlayback(id);
end;

procedure TfLiturgia.atualizaOpcoesDeModo;
var
  i: Integer;
  tem: Boolean;
begin
  if (pnlModo = nil) or (Length(botoesModo) = 0) then
    Exit;

  //APAGADO, nao escondido -- a mesma escolha das duas listas: coluna vazia
  //nao distingue "esta musica nao tem playback" de "ninguem usa esta
  //coluna". O TBotaoChato ja apaga o icone quando Enabled e False, e
  //controle desabilitado nao recebe clique (o ControlAtPos da VCL pula os
  //desabilitados), entao nao precisa de guarda no clique.
  tem := playbackDisponivel;
  for i := 0 to High(botoesModo) do
    if (MODOS[i] = acSlidePlayback) or (MODOS[i] = acAudioPlayback) then
      botoesModo[i].Enabled := tem;

  //Opcao que apagou deixa de valer: nao da para salvar um item apontando
  //para um playback que esta musica nao tem. Fica SEM nada marcado -- com o
  //botao apagado E marcado o estado seria contraditorio --, e o btAddClick
  //cobra a escolha.
  if modoDefinido and not tem and
     ((modoEscolhido = acSlidePlayback) or (modoEscolhido = acAudioPlayback))
  then
    limpaModo;

  arrumaSeletorModo;
end;

procedure TfLiturgia.aoAndarNosHinos(DataSet: TDataSet);
begin
  if (pnlModo <> nil) and pnlModo.Visible then
    atualizaOpcoesDeModo;
end;

procedure TfLiturgia.cliqueTipo(Sender: TObject);
var
  i: Integer;
begin
  //O Tag e a linha da TABELA; o combo pode estar em outra ordem.
  i := indiceNoCombo(TBotaoChato(Sender).Tag);
  if (i < 0) then
    Exit;

  //Guarda necessaria: atribuir ItemIndex em combo skinned dispara o OnChange
  //mesmo quando o valor nao muda (armadilha do BusinessSkinForm), e ali
  //dentro o executaOpcoes reabre o qrHinos.
  if (cbItens.ItemIndex <> i) then
    cbItens.ItemIndex := i
  else
    marcaTipoNaTrilha;
end;

procedure TfLiturgia.cliqueModo(Sender: TObject);
begin
  poeModo(MODOS[TBotaoChato(Sender).Tag]);
end;

procedure TfLiturgia.marcaTipoNaTrilha;
var
  i, t: Integer;
begin
  t := tipoAtual;
  for i := 0 to High(botoesTipo) do
    botoesTipo[i].selecionado := (i = t);
end;

procedure TfLiturgia.poeModo(m: TAcaoItem);
var
  i: Integer;
begin
  modoEscolhido := m;
  modoDefinido := True;
  for i := 0 to High(botoesModo) do
    botoesModo[i].selecionado := (MODOS[i] = m);
end;

procedure TfLiturgia.limpaModo;
var
  i: Integer;
begin
  modoDefinido := False;
  for i := 0 to High(botoesModo) do
    botoesModo[i].selecionado := False;
end;

procedure TfLiturgia.edtDiretorioEnter(Sender: TObject);
begin
  edtDiretorio.Text := fmIndex.verificaURL(edtDiretorio.Text, edtDiretorioInfo, true);
end;

procedure TfLiturgia.edtDiretorioExit(Sender: TObject);
begin
  edtDiretorio.Text := fmIndex.verificaURL(edtDiretorio.Text, edtDiretorioInfo, false);
  edtDiretorio.SelStart := Length(edtDiretorio.Text);
  edtDiretorio.Perform(EM_SCROLLCARET, 0, 0);
end;

procedure TfLiturgia.bsSkinSpeedButton1Click(Sender: TObject);
begin
  fIniciando.AppCreateForm(TfBuscaMusica, fBuscaMusica);
  fBuscaMusica.ShowModal;
  if (fBuscaMusica.id) > 0
    then dbLitHinoLista.KeyValue := fBuscaMusica.id;
end;

procedure TfLiturgia.bsSkinSpeedButton2Click(Sender: TObject);
begin
  urlSite.text := validaURL(urlSite.text);
  fmIndex.abrirArquivo(urlSite.Text);
end;

procedure TfLiturgia.bsSkinSpeedButton3Click(Sender: TObject);
var
  dir: string;
begin
  dir := fmIndex.openDialog('pasta', '', 'Liturgia',false,edtDiretorio.Text);
  if dir <> '' then edtDiretorio.Text := dir;
  edtDiretorioExit(Sender);
end;

procedure TfLiturgia.bsSkinSpeedButton4Click(Sender: TObject);
var
  arq: string;
begin
  arq := fmIndex.openDialog('arquivo', '', 'Liturgia',false,ExtractFilePath(edtDiretorio.Text));
  if arq <> '' then edtDiretorio.Text := arq;
  edtDiretorioExit(Sender);
end;

procedure TfLiturgia.btAddClick(Sender: TObject);
var
  semana: string;
  tipo: string;
  subitem: string;
  param: string;
  itens: array of TParamItem;

  procedure Add(const p, v: string);
  begin
    SetLength(itens, Length(itens)+1);
    itens[High(itens)].Grupo := id;
    itens[High(itens)].Param := p;
    itens[High(itens)].Valor := v;
  end;
begin
  if (cbItens.ItemIndex < 0) then
  begin
    application.MessageBox('Escolha o tipo de item!', fmIndex.titulo, mb_ok + MB_ICONEXCLAMATION);
    cbItens.SetFocus;
    Exit;
  end;

  if (txtItem.Visible) and (Trim(txtItem.Text) = '') then
  begin
    application.MessageBox('Defina o nome do item!', fmIndex.titulo, mb_ok + MB_ICONEXCLAMATION);
    txtItem.SetFocus;
    Exit;
  end;

  if (dblItem.Visible) and (trim(dblItem.KeyValue) = '') then
  begin
    application.MessageBox('Escolha o item!', fmIndex.titulo, mb_ok + MB_ICONEXCLAMATION);
    dblItem.SetFocus;
    Exit;
  end;

  //Antes, musica nao escolhida virava "escolher na hora" calada. Agora isso
  //e um tipo de item proprio, entao faltar a musica aqui e engano.
  if SameText(codigoAtual, TIPO_MUSICA) and not ehBuscaRapida and
     (StrToIntDef(VarToStr(dbLitHinoLista.KeyValue), -1) <= 0) then
  begin
    application.MessageBox('Escolha a música!', fmIndex.titulo,
      mb_ok + MB_ICONEXCLAMATION);
    Exit;
  end;

  //Pode estar sem nada marcado: trocar para uma musica sem playback desmarca
  //a opcao de playback que estivesse escolhida. Salvar assim deixaria o
  //clique no corpo sem destino.
  if (pnlHinos.Visible) and not modoDefinido then
  begin
    application.MessageBox('Escolha como este item deve abrir!',
      fmIndex.titulo, mb_ok + MB_ICONEXCLAMATION);
    Exit;
  end;

  semana := fmIndex.loadCol.Strings.Values['LITURGIA:SEMANA'];

  if (Trim(id) = '') then
    id := 'item_'+FormatDateTime('yyyymmddhhnnsszzz', Now);

  tipo := codigoAtual;

  Add('tipo', tipo);
  Add('item', txtItem.Text);
  Add('cor', ColorToString(csCor.ColorValue));

  try
    fmIndex.gravaLog('btAddClick: pre-build id=' + id + ' pnlArquivo=' + BoolToStr(pnlArquivo.Visible, True) + ' edtDiretorio=' + edtDiretorio.Text + ' edtDiretorioInfo=' + edtDiretorioInfo.Text);
  except
    // silencioso
  end;

  if (pnlAnotacoes.Visible) then
  begin
    Add('subitem', edtAnotacao.Text);
  end
  else
  if (dblItem.Visible) then
  begin
    Add('item', dblItem.Text);
    Add('subitem', '');
    Add('id', dblItem.KeyValue);
  end
  else
  if (pnlSite.Visible) then
  begin
    urlSite.text := validaURL(urlSite.text);
    Add('subitem', 'Site '+urlSite.Text);
    Add('url', urlSite.Text);
  end
  else
  if (pnlArquivo.Visible) then
  begin
    edtDiretorio.Text := trim(edtDiretorio.Text);
    if (edtDiretorioInfo.Text = 'I')
      then param := ExtractFilePath(Application.ExeName)+edtDiretorio.Text
      else param := edtDiretorio.Text;

    if (Copy(param,Length(param),1) = '\') then
    begin
      Add('subtipo', 'dir');
      Add('subitem', 'Pasta '+edtDiretorio.Text);
    end
    else if FileExists(param) then
    begin
      Add('subtipo', 'arq');
      Add('subitem', 'Arquivo '+edtDiretorio.Text);
    end
    else if DirectoryExists(param) then
    begin
      edtDiretorio.Text := edtDiretorio.Text+'\';
      Add('subtipo', 'dir');
      Add('subitem', 'Pasta '+edtDiretorio.Text);
    end
    else
    begin
      Add('subtipo', 'arq');
      Add('subitem', 'Arquivo '+edtDiretorio.Text);
    end;

    Add('dir', edtDiretorio.Text);
    Add('dir_info', edtDiretorioInfo.Text);
  end
  else
  if (pnlHinos.Visible) then
  begin
    //Como o clique no CORPO do item abre esta musica. Vazio para o padrao,
    //que e o slide cantado -- assim item de quem nunca mexeu no modo
    //continua sem a chave, e o arquivo nao cresce por nada.
    Add(CHAVE_MODO, ParamDoModo(modoEscolhido));

    //Quem decide agora e o TIPO, nao mais o radio: "Busca rapida" grava a
    //mesma coisa que o "A musica sera escolhida na hora" gravava.
    if ehBuscaRapida then
    begin
      Add('escolha', '1');
      Add('musica', '-1');
      Add('subtipo', 'escolha');
      subitem := 'Clique para escolher a música';
      Add('subitem', subitem);
    end
    else
    begin
      Add('escolha', '0');
      Add('musica', IntToStr(dbLitHinoLista.KeyValue));
      if (qrHinos.FieldByName('TIPO_HASD').AsString = 'S')
        then Add('subtipo', 'hasd')
      else if (qrHinos.FieldByName('TIPO_JA').AsString = 'S')
        then Add('subtipo', 'ja')
      else Add('subtipo', 'div');

      if (qrHinos.FieldByName('TIPO_HASD').AsString = 'S')
        then subitem := 'Hino nº '
        else subitem := 'Música ';
      subitem := subitem + qrHinos.FieldByName('NOME').AsString;
      Add('subitem', subitem);
    end;
  end;

  fmIndex.gravaParamLote(fmIndex.arq_liturgia, itens);

  try
    fmIndex.gravaLog('btAddClick: salvando item ' + id + ' tipo=' + tipo);
  except
    // silencioso: log falhou -> continua
  end;

  if fmIndex.lbLiturgia.Items.IndexOf(id) < 0 then
  begin
    fmIndex.lbLiturgia.Items.Add(id);
    fmIndex.salvaItensLiturgia;
    fmIndex.carregaItemLiturgia(id,fmIndex.lbLiturgia.Items.Count);
  end
  else fmIndex.carregaItemLiturgia(id);

  close;
end;

procedure TfLiturgia.btDelClick(Sender: TObject);
begin
  if (application.MessageBox('Deseja realmente excluir este item?', fmIndex.titulo, mb_yesno + mb_iconquestion) <> 6) then Exit;
  fmIndex.apagaItemLiturgia(id);
  Close;
end;

procedure TfLiturgia.cbItensChange(Sender: TObject);
var
  idx: Integer;
  cod: string;
  ehAgendado, ehMusica: Boolean;
begin
  //Pelo CODIGO do tipo, nunca pelo indice do combo.
  idx := cbItens.ItemIndex;
  cod := codigoAtual;
  ehAgendado := SameText(cod, TIPO_AGENDADOS_LEGADO);
  ehMusica := SameText(cod, TIPO_MUSICA);

  pnlAnotacoes.Visible      := SameText(cod, TIPO_ANOTACAO);
  pnlArquivo.Visible        := SameText(cod, TIPO_ARQUIVO);
  //O painel dos agendados ficou VAZIO: o seletor mudou de lugar, para a
  //linha onde os outros tipos poem o nome. Deixa-lo visivel seria uma tira
  //so com rotulo.
  pnlItensAgendados.Visible := False;
  //Os dois tipos de musica dividem o mesmo painel: o que muda e a escolha da
  //musica aparecer ou nao.
  pnlHinos.Visible          := ehMusica;
  pnlSite.Visible           := SameText(cod, TIPO_SITE);

  pnlHinosOpc1.Visible := ehMusica and not ehBuscaRapida;
  if (pnlBuscaInfo <> nil) then
    pnlBuscaInfo.Visible := ehMusica and ehBuscaRapida;

  //O seletor de agendados ocupa a MESMA linha do nome dos outros tipos: os
  //dois sao alClient dentro do bsSkinPanel1 e so um aparece por vez.
  lblItem.Visible := True;
  txtItem.Visible := not ehAgendado;
  dblItem.Visible := ehAgendado;
  if ehAgendado then
    lblItem.Caption := 'Item Agendado:'
  else
    lblItem.Caption := 'Nome do Item:';

  //O seletor de modo vale para os dois tipos de musica: os outros tem um
  //jeito so de abrir.
  if (pnlModo <> nil) then
  begin
    if pnlHinos.Visible then
    begin
      //O alTop da VCL empilha POR Top (o InsertBefore do TWinControl compara
      //Top), e painel escondido guarda o Top antigo. Era isso que punha o
      //seletor ACIMA da musica ao voltar de outro tipo: o pnlModo tinha
      //ficado com Top menor que o do pnlHinos. Jogar o Top para longe antes
      //de mostrar garante que ele entre por ultimo, sempre.
      pnlModo.Top := 10000;
      pnlModo.Visible := True;
      atualizaOpcoesDeModo;
    end
    else
      pnlModo.Visible := False;
  end;

  marcaTipoNaTrilha;

  if idx < 0 then Exit;
  executaOpcoes;
end;

procedure TfLiturgia.executaOpcoes;
var
  item: string;
begin
  try
    if (pnlHinos.Visible) then
    begin
      opcHinosOpc1Click(nil);
      qrHinos.Close;
      qrHinos.Open;
    end
    else if dblItem.Visible then
    begin
      item := '';
      if (dblItem.KeyValue <> null) then
        item := dblItem.KeyValue;
      if not DM.cdsCategoriasItensAgendados.Active then
      begin
        DM.cdsCategoriasItensAgendados.CreateDataSet;
        DM.cdsCategoriasItensAgendados.IndexName := '';
        DM.cdsCategoriasItensAgendados.IndexFieldNames := 'NOME';
        DM.cdsCategoriasItensAgendados.LogChanges := False;
      end;

      if (FileExists(fmIndex.dir_dados + 'itensAgendadosCategorias.xml')) then
        DM.cdsCategoriasItensAgendados.LoadFromFile(fmIndex.dir_dados + 'itensAgendadosCategorias.xml');
      DM.cdsCategoriasItensAgendados.Open;
      dblItem.KeyValue := item;
    end;
  except
    // Silencioso - erros em opções não devem quebrar a UI
  end;
end;

procedure TfLiturgia.FormActivate(Sender: TObject);
var
  tipo: string;
  idx: Integer;
  function FindIndexForTipo(const code: string): Integer;
  var
    i: Integer;
    c: string;
  begin
    Result := -1;
    if Trim(code) = '' then Exit;
    // try direct code-index mapping (legacy behavior)
    Result := AnsiIndexStr(code, ['anotacao','arquivo','categoria','itensagendados','musica','site']);
    if (Result >= 0) and (Result < cbItens.Items.Count) then Exit;

    // fallback: match by partial label (case-insensitive)
    for i := 0 to cbItens.Items.Count - 1 do
    begin
      c := cbItens.Items[i];
      if AnsiContainsText(c, 'Anot') and ((code = 'anotacao')) then
      begin
        Result := i; Exit;
      end;
      if (AnsiContainsText(c, 'Arquiv') or AnsiContainsText(c, 'Diretor') or AnsiContainsText(c, 'Diret')) and (code = 'arquivo') then
      begin
        Result := i; Exit;
      end;
      if AnsiContainsText(c, 'Categor') and (code = 'categoria') then
      begin
        Result := i; Exit;
      end;
      if (AnsiContainsText(c, 'Itens') or AnsiContainsText(c, 'Agend')) and (code = 'itensagendados') then
      begin
        Result := i; Exit;
      end;
      if (AnsiContainsText(c, 'Músic') or AnsiContainsText(c, 'Musica') or AnsiContainsText(c, 'Hino')) and (code = 'musica') then
      begin
        Result := i; Exit;
      end;
      if AnsiContainsText(c, 'Site') and (code = 'site') then
      begin
        Result := i; Exit;
      end;
    end;
  end;
begin
  pnlAnotacoes.Visible := False;
  pnlHinos.Visible := False;
  pnlSite.Visible := False;
  pnlArquivo.Visible := False;
  pnlItensAgendados.Visible := False;
  ScrollBox1.Visible := True;

  if (Trim(id) = '') then
  begin
    btAdd.Caption := ' Adicionar';
    btAdd.ImageIndex := 44;
    btDel.Visible := False;
  end
  else
  begin
    btAdd.Caption := ' Salvar';
    btAdd.ImageIndex := 2;
    btDel.Visible := True;
  end;

  try
    fmIndex.gravaLog('FormActivate: carrega item ' + id);
    tipo := fmIndex.lerParam(id, 'tipo', '', fmIndex.arq_liturgia);

    // Prefill simple controls that do not require datasets
    if tipo = 'anotacao' then
      edtAnotacao.Text := fmIndex.lerParam(id, 'subitem', '', fmIndex.arq_liturgia)
    else
      edtAnotacao.Text := '';

    if tipo = 'site' then
      urlSite.Text := fmIndex.lerParam(id, 'url', '', fmIndex.arq_liturgia)
    else
      urlSite.Text := '';

    if tipo = 'arquivo' then
    begin
      edtDiretorio.Text := fmIndex.lerParam(id, 'dir', '', fmIndex.arq_liturgia);
      edtDiretorioInfo.Text := fmIndex.lerParam(id, 'dir_info', '', fmIndex.arq_liturgia);
      edtDiretorio.SelStart := Length(edtDiretorio.Text);
      edtDiretorio.Perform(EM_SCROLLCARET, 0, 0);
    end
    else
    begin
      edtDiretorio.Text := '';
      edtDiretorioInfo.Text := '';
    end;

      txtItem.Text := fmIndex.lerParam(id, 'item', '', fmIndex.arq_liturgia);
      csCor.ColorValue := StringToColor(fmIndex.lerParam(id, 'cor', '$004F0000', fmIndex.arq_liturgia));

      // Map and set ItemIndex so cbItensChange opens datasets before KeyValue assignment
      try
        //Pela TABELA, nao pelo indice: o `escolha` desempata as duas linhas
        //que gravam tipo musica. Sem isso um item de busca rapida voltaria
        //como "Musica" com o campo vazio, e salvar perderia a escolha na
        //hora.
        idx := indiceNoCombo(indiceDoGravado(tipo,
          fmIndex.lerParam(id, 'escolha', '0', fmIndex.arq_liturgia) = '1'));

        //Rotulo antigo que a tabela nao conhece: cai no mapeamento por
        //texto que ja existia.
        if (idx < 0) then
          idx := FindIndexForTipo(tipo);

        if idx >= 0 then
          cbItens.ItemIndex := idx
        else
        begin
          cbItens.ItemIndex := -1;
          fmIndex.gravaLog('FormActivate: tipo desconhecido para item ' + id + ' -> "' + tipo + '"');
        end;
      except
        cbItens.ItemIndex := -1;
        fmIndex.gravaLog('FormActivate: erro ao mapear tipo para item ' + id);
      end;

    // Ensure datasets and lookup lists are initialized
    cbItensChange(Sender);

    // Now safe to assign DB lookup KeyValues
    if tipo = 'itensagendados' then
      dblItem.KeyValue := fmIndex.lerParam(id, 'id', '', fmIndex.arq_liturgia)
    else
      dblItem.KeyValue := '';

    dbLitHinoLista.KeyValue := fmIndex.lerParam(id, 'musica', '-1', fmIndex.arq_liturgia);

    //DEPOIS do KeyValue, nesta ordem: atribuir a musica dispara o AfterScroll
    //do qrHinos, que reavalia as opcoes. Carregar o modo antes faria o
    //AfterScroll julgar um modo que ainda nao era o do item. Item novo (id
    //vazio) devolve '' e cai no padrao.
    poeModo(ModoDoParam(fmIndex.lerParam(id, CHAVE_MODO, '',
      fmIndex.arq_liturgia)));
    atualizaOpcoesDeModo;

  except
    cbItens.ItemIndex := -1;
    try fmIndex.gravaLog('FormActivate: excecao ao carregar item ' + id); except end;
  end;

  // Pré-preenchimento via drag-and-drop de arquivo na liturgia
  if (Trim(arquivoInicial) <> '') and (Trim(id) = '') then
  begin
    cbItens.ItemIndex := 1; // Arquivo
    cbItensChange(nil);
    edtDiretorio.Text := arquivoInicial;
    edtDiretorioExit(nil);
    arquivoInicial := '';
    if txtItem.CanFocus then txtItem.SetFocus;
  end;
end;

procedure TfLiturgia.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  fmIndex.FormKeyUp(Sender, Key, Shift);
end;

procedure TfLiturgia.opcHinosOpc1Click(Sender: TObject);
begin
  //O radio saiu da tela (virou o tipo "Busca rapida") e nao decide mais a
  //visibilidade de nada. O metodo fica porque o .dfm aponta o OnClick para
  //ca e porque o executaOpcoes o chama.
  atualizaOpcoesDeModo;
end;

procedure TfLiturgia.txtItemKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  fmIndex.edtKeyUp(Sender,Key,Shift);
end;

procedure TfLiturgia.urlSiteExit(Sender: TObject);
begin
  urlSite.text := validaURL(urlSite.text);
end;

function TfLiturgia.validaURL(url: string): string;
begin
  if (Copy(url,1,7) <> 'http://') and
     (Copy(url,1,8) <> 'https://') and
     (Copy(url,1,6) <> 'ftp://')
    then url := 'http://'+url;

  Result := url;
end;

end.
